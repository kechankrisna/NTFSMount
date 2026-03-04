import Foundation

// MARK: - NTFSDrive

/// Represents a single NTFS partition discovered on the system.
struct NTFSDrive: Identifiable, Equatable, Hashable {

    // ── Identity ──────────────────────────────────────────────────────────
    let id: UUID
    /// BSD node name, e.g. "disk2s1"
    let bsdName: String
    /// Human-readable volume label, e.g. "MY_DRIVE"
    let volumeName: String

    // ── Mount state ───────────────────────────────────────────────────────
    /// Absolute path of the current mount point, nil if unmounted.
    let mountPoint: String?
    /// True when currently mounted.
    var isMounted: Bool
    /// True when mounted with read/write access via ntfs-3g.
    var isWritable: Bool
    /// True while a mount / eject operation is in flight.
    var isMounting: Bool

    // ── Capacity ──────────────────────────────────────────────────────────
    let totalBytes: Int64
    let freeBytes: Int64

    // ── Computed ──────────────────────────────────────────────────────────
    var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }

    var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    var displaySize: String { ByteFormatter.format(totalBytes) }
    var displayFree: String { ByteFormatter.format(freeBytes) }
    var displayUsed: String { ByteFormatter.format(usedBytes) }
}

// MARK: - Byte formatter helper

private enum ByteFormatter {
    static func format(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 100  { return String(format: "%.0f GB", gb) }
        if gb >= 1    { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576.0
        if mb >= 1    { return String(format: "%.0f MB", mb) }
        return "\(bytes) B"
    }
}

// MARK: - Sample data (for Xcode Previews & demo mode)

extension NTFSDrive {

    static let sampleRW = NTFSDrive(
        id: UUID(),
        bsdName: "disk2s1",
        volumeName: "WORKDRIVE",
        mountPoint: "/Volumes/WORKDRIVE",
        isMounted: true,
        isWritable: true,
        isMounting: false,
        totalBytes: 500_107_862_016,
        freeBytes: 183_456_000_000
    )

    static let sampleRO = NTFSDrive(
        id: UUID(),
        bsdName: "disk3s1",
        volumeName: "BACKUP",
        mountPoint: "/Volumes/BACKUP",
        isMounted: true,
        isWritable: false,
        isMounting: false,
        totalBytes: 1_000_204_886_016,
        freeBytes: 620_000_000_000
    )

    static let sampleUnmounted = NTFSDrive(
        id: UUID(),
        bsdName: "disk4s1",
        volumeName: "ARCHIVE",
        mountPoint: nil,
        isMounted: false,
        isWritable: false,
        isMounting: false,
        totalBytes: 256_060_514_304,
        freeBytes: 0
    )

    static let sampleMounting = NTFSDrive(
        id: UUID(),
        bsdName: "disk5s1",
        volumeName: "TRANSFER",
        mountPoint: nil,
        isMounted: false,
        isWritable: false,
        isMounting: true,
        totalBytes: 128_048_508_928,
        freeBytes: 0
    )

    static var samples: [NTFSDrive] {
        [.sampleRW, .sampleRO, .sampleUnmounted, .sampleMounting]
    }
}
