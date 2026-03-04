import Foundation

// MARK: - DiskScanner

/// Discovers NTFS volumes via `diskutil list -plist` and `diskutil info -plist`.
/// Handles both GPT ("Microsoft Basic Data") and MBR ("Windows_NTFS") partition types.
final class DiskScanner {

    // ── Public API ────────────────────────────────────────────────────────

    /// Returns all NTFS partitions found on the system.
    func scanDrives() async throws -> [NTFSDrive] {

        let listData = try await runDiskutil(args: ["list", "-plist"])

        guard
            let plist = try? PropertyListSerialization.propertyList(
                from: listData, format: nil) as? [String: Any],
            let allDisks = plist["AllDisksAndPartitions"] as? [[String: Any]]
        else {
            return []
        }

        var drives: [NTFSDrive] = []

        for disk in allDisks {
            // Check the disk itself (whole-disk NTFS — uncommon but possible)
            if looksLikeNTFS(content: disk["Content"] as? String,
                             fs: disk["FilesystemType"] as? String),
               let dev = disk["DeviceIdentifier"] as? String,
               let drive = try? await fetchDriveInfo(bsdName: dev) {
                drives.append(drive)
            }

            // Check every partition inside the disk
            guard let partitions = disk["Partitions"] as? [[String: Any]] else {
                continue
            }
            for partition in partitions {
                let content = partition["Content"] as? String
                let fs      = partition["FilesystemType"] as? String
                guard looksLikeNTFS(content: content, fs: fs),
                      let dev = partition["DeviceIdentifier"] as? String
                else { continue }

                if let drive = try? await fetchDriveInfo(bsdName: dev) {
                    drives.append(drive)
                }
            }
        }

        return drives
    }

    // ── NTFS detection ────────────────────────────────────────────────────

    /// Returns true for any content / filesystem string that signals NTFS.
    ///
    /// - GPT disks  → Content = "Microsoft Basic Data"
    /// - MBR disks  → Content = "Windows_NTFS"          ← user's Verbatim HDD
    /// - diskutil info extra keys → FilesystemPersonality = "NTFS"
    private func looksLikeNTFS(content: String?, fs: String?) -> Bool {
        let c = (content ?? "").lowercased()
        let f = (fs     ?? "").lowercased()
        return c == "windows_ntfs"
            || c == "microsoft basic data"
            || c.contains("ntfs")
            || f.contains("ntfs")
    }

    // ── Drive info fetch ──────────────────────────────────────────────────

    private func fetchDriveInfo(bsdName: String) async throws -> NTFSDrive {
        let data = try await runDiskutil(args: ["info", "-plist", "/dev/\(bsdName)"])

        guard
            let info = try? PropertyListSerialization.propertyList(
                from: data, format: nil) as? [String: Any]
        else {
            throw MountError.driveNotFound(name: bsdName)
        }

        // ── Confirm NTFS at the info level too ────────────────────────────
        let personality = (info["FilesystemPersonality"] as? String ?? "").lowercased()
        let fsType      = (info["FilesystemType"]        as? String ?? "").lowercased()
        let content     = (info["Content"]               as? String ?? "").lowercased()
        let isNTFS      = personality.contains("ntfs")
                       || fsType.contains("ntfs")
                       || content.contains("ntfs")
                       || content == "windows_ntfs"

        // Skip non-NTFS partitions that slipped past the list filter
        guard isNTFS else {
            throw MountError.driveNotFound(name: bsdName)
        }

        // ── Volume identity ───────────────────────────────────────────────
        let volumeName = nonEmpty(info["VolumeName"] as? String)
                      ?? nonEmpty(info["MediaName"]  as? String)
                      ?? bsdName

        // ── Mount state ───────────────────────────────────────────────────
        let rawMount   = info["MountPoint"] as? String ?? ""
        let mountPoint = rawMount.isEmpty ? nil : rawMount
        let isMounted  = mountPoint != nil

        // "Writable" = current mount is writable (false for macOS read-only NTFS mounts).
        // "WritableMedia" = physical media is not write-protected (almost always true).
        // We want the mount-level flag so the UI shows "Read Only" for stock macOS mounts.
        let writable   = info["Writable"] as? Bool ?? false
        let isWritable = isMounted && writable

        // ── Capacity ──────────────────────────────────────────────────────
        let totalBytes = (info["TotalSize"] as? Int64) ?? 0
        let freeBytes  = (info["FreeSpace"] as? Int64)
                      ?? (info["APFSContainerFree"] as? Int64)
                      ?? 0

        return NTFSDrive(
            id:          UUID(),
            bsdName:     bsdName,
            volumeName:  volumeName,
            mountPoint:  mountPoint,
            isMounted:   isMounted,
            isWritable:  isWritable,
            isMounting:  false,
            totalBytes:  totalBytes,
            freeBytes:   freeBytes
        )
    }

    // ── Shell ─────────────────────────────────────────────────────────────

    /// Runs diskutil on a background thread and returns its stdout as Data.
    private func runDiskutil(args: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
                proc.arguments     = args

                let outPipe = Pipe()
                let errPipe = Pipe()
                proc.standardOutput = outPipe
                proc.standardError  = errPipe

                do {
                    try proc.run()
                    proc.waitUntilExit()
                    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
