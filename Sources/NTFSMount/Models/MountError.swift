import Foundation

// MARK: - MountError

/// Typed errors produced by the NTFSMount core layer.
enum MountError: LocalizedError, Equatable {

    case macFUSENotInstalled
    case ntfs3gNotFound
    case helperNotInstalled
    case driveNotFound(name: String)
    case mountFailed(reason: String)
    case unmountFailed(reason: String)
    case permissionDenied
    case timeout

    // ── LocalizedError ────────────────────────────────────────────────────

    var errorDescription: String? {
        switch self {
        case .macFUSENotInstalled:
            return "macFUSE is not installed. Install it to enable NTFS write access."
        case .ntfs3gNotFound:
            return "ntfs-3g was not found. Run: brew install gromgit/fuse/ntfs-3g-mac"
        case .helperNotInstalled:
            return "The privileged helper needs to be installed. Run Setup again."
        case .driveNotFound(let name):
            return "Drive \"\(name)\" was not found on the system."
        case .mountFailed(let reason):
            return "Mount failed: \(reason)"
        case .unmountFailed(let reason):
            return "Eject failed: \(reason)"
        case .permissionDenied:
            return "Permission denied — the helper may need to be reinstalled."
        case .timeout:
            return "The operation timed out after 30 seconds."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .macFUSENotInstalled:
            return "Install macFUSE from https://macfuse.github.io or via Homebrew."
        case .ntfs3gNotFound:
            return "brew install gromgit/fuse/ntfs-3g-mac"
        case .helperNotInstalled:
            return "Open NTFSMount Preferences → Help → Re-run Setup."
        default:
            return nil
        }
    }

    // ── Equatable (manual, since associated values) ───────────────────────

    static func == (lhs: MountError, rhs: MountError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
