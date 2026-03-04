import SwiftUI
import AppKit

// MARK: - PreferencesView

struct PreferencesView: View {

    @EnvironmentObject var mounter: NTFSMounter
    @StateObject private var prefs = PreferencesManager.shared

    var body: some View {
        TabView {
            GeneralTab(prefs: prefs)
                .tabItem { Label("General",  systemImage: "gear") }

            DrivesTab(prefs: prefs)
                .tabItem { Label("Drives",   systemImage: "externaldrive") }

            LogsTab()
                .tabItem { Label("Logs",     systemImage: "doc.text") }

            AboutTab()
                .tabItem { Label("About",    systemImage: "info.circle") }
        }
        .frame(width: 480, height: 380)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject var prefs: PreferencesManager

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch NTFSMount at login", isOn: $prefs.launchAtLogin)
            }

            Section("Notifications") {
                Toggle("Notify when a drive is mounted or ejected", isOn: $prefs.showNotifications)
            }

            Section("Safety") {
                Toggle("Warn before ejecting a busy drive", isOn: $prefs.warnBeforeEject)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - Drives Tab

private struct DrivesTab: View {
    @ObservedObject var prefs: PreferencesManager
    @EnvironmentObject var mounter: NTFSMounter

    @State private var isSettingUp    = false
    @State private var isRemoving     = false
    @State private var setupMessage: String? = nil

    var body: some View {
        Form {
            Section("Auto-Mount") {
                Toggle("Mount NTFS drives with write access when connected",
                       isOn: $prefs.autoMount)
                Text("Requires ntfs-3g to be installed and Seamless Mounting enabled below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("After Mounting") {
                Toggle("Open Finder window after successful mount",
                       isOn: $prefs.openFinderOnMount)
            }

            Section {
                HStack(alignment: .top, spacing: 12) {
                    // Status icon
                    Image(systemName: mounter.isSeamlessMountingSetup
                          ? "checkmark.shield.fill"
                          : "shield.slash.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(mounter.isSeamlessMountingSetup ? .green : .secondary)
                        .frame(width: 28)

                    // Description
                    VStack(alignment: .leading, spacing: 3) {
                        Text(mounter.isSeamlessMountingSetup
                             ? "Seamless Mounting is active"
                             : "Seamless Mounting is not set up")
                            .font(.system(size: 13, weight: .medium))

                        Text(mounter.isSeamlessMountingSetup
                             ? "Drives mount silently with no password prompt."
                             : "One-time setup installs a sudoers rule so you are never asked for a password when mounting NTFS drives.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let msg = setupMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(msg.hasPrefix("✓") ? Color.green : Color.secondary)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()

                    // Action button
                    if mounter.isSeamlessMountingSetup {
                        Button(isRemoving ? "Removing…" : "Disable") {
                            isRemoving   = true
                            setupMessage = nil
                            Task {
                                await mounter.removeSeamlessMount()
                                isRemoving   = false
                                setupMessage = mounter.isSeamlessMountingSetup
                                    ? "Could not remove rule."
                                    : "✓ Disabled — password prompt restored."
                            }
                        }
                        .disabled(isRemoving)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button(isSettingUp ? "Setting up…" : "Enable…") {
                            isSettingUp  = true
                            setupMessage = nil
                            Task {
                                let ok       = await mounter.setupSeamlessMount()
                                isSettingUp  = false
                                setupMessage = ok
                                    ? "✓ Seamless mounting enabled — no more password prompts!"
                                    : "Setup cancelled."
                            }
                        }
                        .disabled(isSettingUp)
                        .buttonStyle(BorderedProminentButtonStyle())
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Permissions")
            } footer: {
                Text("The sudoers rule is stored in /etc/sudoers.d/ntfsmount and can be removed at any time.")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabelColor))
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - Logs Tab

private struct LogsTab: View {

    private var logURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Logs/NTFSMount")
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Application Logs")
                    .font(.headline)
                Text("~/Library/Logs/NTFSMount/")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Open Log Folder") {
                    NSWorkspace.shared.open(logURL)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Open Console") {
                    NSWorkspace.shared.open(
                        URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Logs are automatically rotated after 7 days.")
                .font(.system(size: 11))
                .foregroundStyle(Color(.tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "externaldrive.fill.badge.checkmark")
                .font(.system(size: 38, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.cyan)

            VStack(spacing: 4) {
                Text("NTFSMount")
                    .font(.system(size: 18, weight: .bold))
                Text("Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("By KECHANKRISNA · Free, open-source NTFS for macOS")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Divider().frame(width: 200)

            HStack(spacing: 20) {
                Link("GitHub",
                     destination: URL(string: "https://github.com/ntfsmount/ntfsmount")!)
                Link("Report Issue",
                     destination: URL(string: "https://github.com/ntfsmount/ntfsmount/issues")!)
                Link("GPL-3.0",
                     destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
            }
            .font(.system(size: 12))

            Text("Built on macFUSE + ntfs-3g")
                .font(.system(size: 11))
                .foregroundStyle(Color(.tertiaryLabelColor))

            // Re-run onboarding
            Button("Re-run Setup Wizard…") {
                openWindow(id: "onboarding")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(NTFSMounter())
            .preferredColorScheme(.dark)
    }
}
#endif
