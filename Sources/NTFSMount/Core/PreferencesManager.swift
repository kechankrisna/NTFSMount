import Foundation
import Combine

// MARK: - PreferencesManager

/// Singleton that persists user preferences via UserDefaults.
final class PreferencesManager: ObservableObject {

    static let shared = PreferencesManager()

    // ── Settings ──────────────────────────────────────────────────────────

    /// Automatically mount NTFS drives with write access when they are connected.
    @Published var autoMount: Bool {
        didSet { store(autoMount, for: .autoMount) }
    }

    /// Show a notification banner when a drive is mounted, ejected, or errors.
    @Published var showNotifications: Bool {
        didSet { store(showNotifications, for: .showNotifications) }
    }

    /// Launch NTFSMount at login.
    @Published var launchAtLogin: Bool {
        didSet { store(launchAtLogin, for: .launchAtLogin) }
    }

    /// Set after the user completes (or skips) the first-launch onboarding flow.
    @Published var hasCompletedOnboarding: Bool {
        didSet { store(hasCompletedOnboarding, for: .hasCompletedOnboarding) }
    }

    /// Show a warning dialog before ejecting a busy drive.
    @Published var warnBeforeEject: Bool {
        didSet { store(warnBeforeEject, for: .warnBeforeEject) }
    }

    /// Open Finder automatically after successfully mounting a drive.
    @Published var openFinderOnMount: Bool {
        didSet { store(openFinderOnMount, for: .openFinderOnMount) }
    }

    // ── Keys ──────────────────────────────────────────────────────────────

    fileprivate enum Key: String {   // fileprivate so the UserDefaults extension below can access it
        case autoMount
        case showNotifications
        case launchAtLogin
        case hasCompletedOnboarding
        case warnBeforeEject
        case openFinderOnMount
    }

    // ── Init ──────────────────────────────────────────────────────────────

    private init() {
        let d = UserDefaults.standard
        autoMount              = d.bool(for: .autoMount)
        showNotifications      = d.optionalBool(for: .showNotifications) ?? true
        launchAtLogin          = d.bool(for: .launchAtLogin)
        hasCompletedOnboarding = d.bool(for: .hasCompletedOnboarding)
        warnBeforeEject        = d.optionalBool(for: .warnBeforeEject) ?? true
        openFinderOnMount      = d.bool(for: .openFinderOnMount)
    }

    // ── Helper ────────────────────────────────────────────────────────────

    private func store(_ value: Bool, for key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

// MARK: - UserDefaults convenience

private extension UserDefaults {
    func bool(for key: PreferencesManager.Key) -> Bool {
        bool(forKey: key.rawValue)
    }
    func optionalBool(for key: PreferencesManager.Key) -> Bool? {
        object(forKey: key.rawValue) as? Bool
    }
}
