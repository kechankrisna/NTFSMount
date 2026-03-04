import SwiftUI
import AppKit

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {}

// MARK: - App

@main
struct NTFSMountApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var mounter = NTFSMounter()
    @StateObject private var prefs   = PreferencesManager.shared

    var body: some Scene {

        // ── Menu Bar Popover (360 pt wide, window-style) ──────────────────
        MenuBarExtra {
            DriveListView()
                .environmentObject(mounter)
                .frame(width: 360)
        } label: {
            MenuBarIconView(mounter: mounter)
        }
        .menuBarExtraStyle(.window)

        // ── Preferences Window ────────────────────────────────────────────
        // NOTE: Settings {} + openSettings() does NOT work reliably in
        // LSUIElement = YES apps when called from a MenuBarExtra window —
        // the responder chain never reaches the Settings scene handler.
        // Using a plain WindowGroup with a stable ID instead; openWindow(id:)
        // is always reliable regardless of app activation state.
        WindowGroup("Preferences", id: "preferences") {
            PreferencesView()
                .environmentObject(mounter)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 380)

        // ── Onboarding Window (shown on first launch) ─────────────────────
        WindowGroup("Setup", id: "onboarding") {
            OnboardingView()
                .environmentObject(prefs)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)
    }
}

// MARK: - Menu Bar Icon

struct MenuBarIconView: View {
    @ObservedObject var mounter: NTFSMounter

    var body: some View {
        Image(systemName: mounter.menuBarSystemImage)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(mounter.menuBarTintColor)
            .help("NTFSMount")
    }
}
