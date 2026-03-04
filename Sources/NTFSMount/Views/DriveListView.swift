import SwiftUI
import AppKit

// MARK: - DriveListView
// Main content of the 360pt-wide menu bar popover (NSPopover-style window).

struct DriveListView: View {

    @EnvironmentObject var mounter: NTFSMounter
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {

            header

            divider

            // ── Body ───────────────────────────────────────────────────────
            if mounter.isScanning {
                scanningPlaceholder
            } else if mounter.drives.isEmpty {
                EmptyStateView()
            } else {
                driveList
            }

            // ── Dependency / error banner ──────────────────────────────────
            if let err = mounter.lastError {
                ErrorBanner(error: err) {
                    mounter.lastError = nil
                }
            }

            divider

            footer
        }
        .background(.ultraThinMaterial)
        // Dependency-missing alert
        .alert(
            mounter.missingDependency?.errorDescription ?? "Dependency Missing",
            isPresented: $mounter.showDependencyAlert
        ) {
            Button("Open Setup") {
                // re-run onboarding
                NSWorkspace.shared.open(
                    URL(string: "ntfsmount://onboarding")!)
            }
            Button("OK", role: .cancel) { }
        } message: {
            if let suggestion = mounter.missingDependency?.recoverySuggestion {
                Text(suggestion)
            }
        }
    }

    // ── Header ─────────────────────────────────────────────────────────────

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.cyan)

            Text("NTFSMount")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            // Dependency indicator
            Circle()
                .fill(mounter.dependenciesInstalled ? Color.cyan : Color.orange)
                .frame(width: 6, height: 6)
                .help(mounter.dependenciesInstalled
                      ? "Dependencies OK"
                      : "macFUSE or ntfs-3g not found")

            // Refresh button
            Button {
                Task { await mounter.scanDrives() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(mounter.isScanning ? .degrees(360) : .zero)
                    .animation(
                        mounter.isScanning
                            ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                            : .default,
                        value: mounter.isScanning
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh drives")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // ── Drive list ─────────────────────────────────────────────────────────

    private var driveList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(mounter.drives) { drive in
                    DriveRowView(drive: drive)
                        .environmentObject(mounter)
                    if drive.id != mounter.drives.last?.id {
                        divider.padding(.horizontal, 14)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
    }

    // ── Scanning placeholder ───────────────────────────────────────────────

    private var scanningPlaceholder: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.75)
            Text("Scanning drives…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }

    // ── Footer ─────────────────────────────────────────────────────────────

    private var footer: some View {
        HStack {
            Button {
                // LSUIElement apps have no reliable keyWindow — trying to close
                // NSApp.keyWindow silently fails.  Instead we:
                //  1. Bring an existing Preferences window to front, or open a new one.
                //  2. Activate the app so the window appears above the panel.
                //  3. The MenuBarExtra panel auto-dismisses when it loses focus.
                if let existing = NSApp.windows.first(where: { $0.title == "Preferences" }) {
                    existing.makeKeyAndOrderFront(nil)
                } else {
                    openWindow(id: "preferences")
                }
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Preferences", systemImage: "gear")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("v1.0.0")
                .font(.system(size: 10))
                .foregroundStyle(Color(.tertiaryLabelColor))

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let error: MountError
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.orange.opacity(0.10))
    }
}

// MARK: - Preview

#if DEBUG
struct DriveListView_Previews: PreviewProvider {
    static var previews: some View {
        let m = NTFSMounter()
        m.isDemoMode = true
        return DriveListView()
            .environmentObject(m)
            .frame(width: 360)
            .preferredColorScheme(.dark)
    }
}
#endif
