import Foundation
import SwiftUI
import AppKit

// MARK: - App-level state

enum AppState { case idle, active, error }

// MARK: - NTFSMounter

/// Central @Observable that the entire SwiftUI layer reacts to.
/// Coordinates DiskScanner, dependency checks, mount/eject, and workspace notifications.
@MainActor
final class NTFSMounter: ObservableObject {

    // ── Published state ───────────────────────────────────────────────────
    @Published var drives:    [NTFSDrive] = []
    @Published var isScanning: Bool       = false
    @Published var appState:   AppState   = .idle
    @Published var lastError:  MountError? = nil

    /// Set to true when dependencies are missing (macFUSE / ntfs-3g).
    @Published var showDependencyAlert: Bool = false
    @Published var missingDependency:   MountError? = nil

    // ── Demo/preview mode (uses sample data, no real diskutil calls) ──────
    var isDemoMode: Bool = false

    // ── Internals ─────────────────────────────────────────────────────────
    private let scanner  = DiskScanner()
    private var workspaceObservers: [Any] = []

    // ── Menu bar icon ─────────────────────────────────────────────────────
    var menuBarSystemImage: String {
        switch appState {
        case .idle:
            return drives.isEmpty ? "externaldrive" : "externaldrive.fill"
        case .active:
            return "externaldrive.fill.badge.checkmark"
        case .error:
            return "externaldrive.badge.xmark"
        }
    }

    var menuBarTintColor: Color {
        switch appState {
        case .idle:   return Color.primary
        case .active: return Color.cyan
        case .error:  return Color.red
        }
    }

    // ── Init ──────────────────────────────────────────────────────────────
    init() {
        Task { await scanDrives() }
        subscribeToWorkspaceNotifications()
    }

    // Note: deinit is deliberately NOT @MainActor isolated.
    // We capture the observers list by value so we can clean up from any thread.
    nonisolated func cancelObservers(_ observers: [Any]) {
        let nc = NSWorkspace.shared.notificationCenter
        observers.forEach { nc.removeObserver($0) }
    }

    deinit {
        cancelObservers(workspaceObservers)
    }

    // ── Scan ──────────────────────────────────────────────────────────────

    func scanDrives() async {
        isScanning = true
        defer { isScanning = false }

        if isDemoMode {
            try? await Task.sleep(nanoseconds: 600_000_000)
            drives   = NTFSDrive.samples
            appState = drives.contains(where: \.isWritable) ? .active : .idle
            return
        }

        do {
            drives   = try await scanner.scanDrives()
            lastError = nil
            appState = drives.contains(where: \.isWritable) ? .active : .idle
        } catch {
            lastError = .mountFailed(reason: error.localizedDescription)
            appState  = .error
        }
    }

    // ── Mount ─────────────────────────────────────────────────────────────

    func mount(_ drive: NTFSDrive) async {
        // Dependency check (before touching the array)
        guard validateDependencies() else { return }
        guard let idx = index(of: drive) else { return }

        drives[idx].isMounting = true
        // Use id-based lookup after every await suspension point
        defer { setMounting(false, id: drive.id) }

        if isDemoMode {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            if let i = index(of: drive) {
                drives[i].isMounted  = true
                drives[i].isWritable = true
                appState = .active
            }
            return
        }

        // ── Real mount path ────────────────────────────────────────────────
        // 1. Unmount the macOS read-only mount first (no root needed).
        if drive.isMounted, let mp = drive.mountPoint {
            _ = shell("/usr/sbin/diskutil", args: ["unmount", mp])
        }

        // 2. Run mkdir + ntfs-3g.
        //    • Seamless mode – uses `sudo -n` (no prompt; requires one-time setup).
        //    • Standard mode – uses osascript so macOS shows its password dialog.
        let ntfs3gPath = ntfs3gBinaryPath()
        let mountPoint = "/Volumes/\(drive.volumeName)"
        let devPath    = "/dev/\(drive.bsdName)"

        let result: (exitCode: Int32, stdout: String, stderr: String)
        if isSeamlessMountingSetup {
            // Password-free path — sudoers rule is installed.
            let mkdirResult = shell("/usr/bin/sudo", args: ["-n", "mkdir", "-p", mountPoint])
            if mkdirResult.exitCode != 0 {
                result = mkdirResult
            } else {
                result = shell("/usr/bin/sudo", args: [
                    "-n", ntfs3gPath, devPath, mountPoint,
                    "-o", "local,allow_other,auto_xattr,noatime"
                ])
            }
        } else {
            // Standard path — osascript shows the macOS admin password dialog.
            let mkdirPart = "mkdir -p \(sq(mountPoint))"
            let mountPart = "\(sq(ntfs3gPath)) \(sq(devPath)) \(sq(mountPoint))"
                          + " -o local,allow_other,auto_xattr,noatime"
            result = shellPrivileged("\(mkdirPart) && \(mountPart)")
        }

        if result.exitCode == 0 {
            await scanDrives()
        } else if result.exitCode == -128 {
            // User clicked Cancel in the password dialog — not an error.
            lastError = nil
        } else {
            let reason = result.stderr.isEmpty ? result.stdout : result.stderr
            lastError  = .mountFailed(reason: reason)
            appState   = .error
        }
    }

    // ── Eject ─────────────────────────────────────────────────────────────

    func eject(_ drive: NTFSDrive) async {
        guard let idx = index(of: drive) else { return }
        drives[idx].isMounting = true
        defer { setMounting(false, id: drive.id) }

        if isDemoMode {
            try? await Task.sleep(nanoseconds: 800_000_000)
            if let i = index(of: drive) {
                drives[i].isMounted  = false
                drives[i].isWritable = false
                appState = drives.contains(where: \.isWritable) ? .active : .idle
            }
            return
        }

        guard let mp = drive.mountPoint else { return }
        let result = shell("/usr/sbin/diskutil", args: ["unmount", mp])

        if result.exitCode == 0 {
            await scanDrives()
        } else {
            lastError = .unmountFailed(reason: result.stderr)
            appState  = .error
        }
    }

    // ── Dependency validation ─────────────────────────────────────────────

    @discardableResult
    func validateDependencies() -> Bool {
        let fm = FileManager.default
        if !fm.fileExists(atPath: "/Library/Filesystems/macfuse.fs") {
            missingDependency  = .macFUSENotInstalled
            showDependencyAlert = true
            appState = .error
            return false
        }
        if ntfs3gBinaryPath().isEmpty {
            missingDependency  = .ntfs3gNotFound
            showDependencyAlert = true
            appState = .error
            return false
        }
        return true
    }

    var dependenciesInstalled: Bool {
        let fm = FileManager.default
        let fuseOK  = fm.fileExists(atPath: "/Library/Filesystems/macfuse.fs")
        let ntfsOK  = !ntfs3gBinaryPath().isEmpty
        return fuseOK && ntfsOK
    }

    // ── Seamless (password-free) mounting ─────────────────────────────────

    /// True when the one-time sudoers rule for password-free mounting is installed.
    var isSeamlessMountingSetup: Bool {
        FileManager.default.fileExists(atPath: "/etc/sudoers.d/ntfsmount")
    }

    /// One-time setup: writes a sudoers rule that lets the current user run
    /// ntfs-3g and mkdir as root with no password prompt.
    /// Shows the macOS admin dialog exactly once. Returns true on success.
    @discardableResult
    func setupSeamlessMount() async -> Bool {
        let username = NSUserName()
        let ntfs3g1  = "/opt/homebrew/bin/ntfs-3g"
        let ntfs3g2  = "/usr/local/bin/ntfs-3g"

        let lines: [String] = [
            "# NTFSMount – password-free NTFS mounting",
            "# Delete /etc/sudoers.d/ntfsmount to re-enable the password prompt.",
            "\(username) ALL=(root) NOPASSWD: \(ntfs3g1) *",
            "\(username) ALL=(root) NOPASSWD: \(ntfs3g2) *",
            "\(username) ALL=(root) NOPASSWD: /bin/mkdir *",
            ""
        ]
        let content = lines.joined(separator: "\n")

        // Write to a temp file first (no root needed).
        let tmpPath = NSTemporaryDirectory() + "ntfsmount_\(UUID().uuidString)"
        do {
            try content.write(toFile: tmpPath, atomically: true, encoding: .utf8)
        } catch {
            lastError = .mountFailed(reason: "Could not write temp file: \(error.localizedDescription)")
            return false
        }

        // Move into place with a single privileged command (asks for password once).
        let cmd    = "cp \(sq(tmpPath)) /etc/sudoers.d/ntfsmount && chmod 440 /etc/sudoers.d/ntfsmount"
        let result = shellPrivileged(cmd)
        try? FileManager.default.removeItem(atPath: tmpPath)

        if result.exitCode == 0   { return true  }
        if result.exitCode == -128 { return false } // user cancelled – not an error
        lastError = .mountFailed(reason: result.stderr.isEmpty ? result.stdout : result.stderr)
        appState  = .error
        return false
    }

    /// Removes the sudoers rule, restoring the password prompt on future mounts.
    func removeSeamlessMount() async {
        let result = shellPrivileged("rm -f /etc/sudoers.d/ntfsmount")
        if result.exitCode != 0 && result.exitCode != -128 {
            lastError = .mountFailed(reason: result.stderr.isEmpty ? result.stdout : result.stderr)
            appState  = .error
        }
    }

    // ── Internals ─────────────────────────────────────────────────────────

    private func ntfs3gBinaryPath() -> String {
        let candidates = [
            "/opt/homebrew/bin/ntfs-3g",
            "/usr/local/bin/ntfs-3g"
        ]
        return candidates.first {
            FileManager.default.isExecutableFile(atPath: $0)
        } ?? ""
    }

    private func index(of drive: NTFSDrive) -> Int? {
        drives.firstIndex(where: { $0.id == drive.id })
    }

    /// Safe post-await setter — re-resolves index by stable UUID.
    private func setMounting(_ value: Bool, id: UUID) {
        if let i = drives.firstIndex(where: { $0.id == id }) {
            drives[i].isMounting = value
        }
    }

    private func subscribeToWorkspaceNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        let mount = nc.addObserver(
            forName: NSWorkspace.didMountNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { await self?.scanDrives() } }

        let unmount = nc.addObserver(
            forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { await self?.scanDrives() } }

        workspaceObservers = [mount, unmount]
    }

    // ── Shell helper ──────────────────────────────────────────────────────

    private func shell(_ path: String, args: [String]) -> (exitCode: Int32, stdout: String, stderr: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args

        let outPipe = Pipe(); let errPipe = Pipe()
        proc.standardOutput = outPipe; proc.standardError = errPipe

        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return (-1, "", error.localizedDescription)
        }

        let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (proc.terminationStatus, stdout, stderr)
    }

    /// Runs a shell command with administrator privileges via osascript.
    /// Shows the standard macOS password dialog.
    /// Returns exit code -128 if the user cancels the dialog.
    private func shellPrivileged(_ command: String) -> (exitCode: Int32, stdout: String, stderr: String) {
        // Embed the command inside an AppleScript string — escape backslashes and double-quotes.
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"
        return shell("/usr/bin/osascript", args: ["-e", script])
    }

    /// Single-quote-escapes a shell argument so paths with spaces are safe.
    /// e.g.  /Volumes/My Drive  →  '/Volumes/My Drive'
    private func sq(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
