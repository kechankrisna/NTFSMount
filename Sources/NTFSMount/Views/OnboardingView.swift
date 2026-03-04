import SwiftUI
import AppKit

// MARK: - Brand color helpers

private extension Color {
    /// MyLekha signature accent green  #3EEAA0
    static let brand    = Color(red: 62/255,  green: 234/255, blue: 160/255)
    /// Soft emerald tint for background rings / badges
    static let brandDim = Color(red: 62/255,  green: 234/255, blue: 160/255).opacity(0.12)
}

// MARK: - Dependency detection

struct DepStatus {
    var homebrew: Bool = false
    var macFUSE:  Bool = false
    var ntfs3g:   Bool = false

    var allReady: Bool { macFUSE && ntfs3g }
}

func checkDeps() -> DepStatus {
    let fm = FileManager.default
    let brew = fm.fileExists(atPath: "/opt/homebrew/bin/brew")
            || fm.fileExists(atPath: "/usr/local/bin/brew")
    let fuse = fm.fileExists(atPath: "/Library/Filesystems/macfuse.fs")
    let ntfs = fm.fileExists(atPath: "/opt/homebrew/bin/ntfs-3g")
            || fm.fileExists(atPath: "/usr/local/bin/ntfs-3g")
            || fm.fileExists(atPath: "/opt/homebrew/sbin/mount_ntfs-3g")
            || fm.fileExists(atPath: "/usr/local/sbin/mount_ntfs-3g")
    return DepStatus(homebrew: brew, macFUSE: fuse, ntfs3g: ntfs)
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @EnvironmentObject var prefs: PreferencesManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    @State private var deps = DepStatus()
    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress pills ─────────────────────────────────────────────
            HStack(spacing: 7) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? Color.brand : Color.white.opacity(0.16))
                        .frame(width: i == currentStep ? 26 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: currentStep)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 22)

            // ── Step content ───────────────────────────────────────────────
            ZStack {
                stepView(for: currentStep)
                    .id(currentStep)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
            .animation(.easeInOut(duration: 0.28), value: currentStep)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Navigation bar ─────────────────────────────────────────────
            HStack {
                if currentStep > 0 {
                    Button("← Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }

                Spacer()

                if currentStep > 0 && currentStep < totalSteps - 1 {
                    Button("Skip") {
                        withAnimation { currentStep += 1 }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .buttonStyle(.plain)
                    .padding(.trailing, 14)
                }

                if currentStep < totalSteps - 1 {
                    Button(currentStep == 0 ? "Get Started  →" : "Continue  →") {
                        // Re-check deps whenever moving forward
                        deps = checkDeps()
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(BrandButtonStyle())
                } else {
                    Button("Launch NTFSMount  ↗") {
                        prefs.hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(BrandButtonStyle())
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 30)
            .padding(.top, 14)
        }
        .frame(width: 540, height: 510)
        .background(Color(.windowBackgroundColor))
        .preferredColorScheme(.dark)
        .onAppear { deps = checkDeps() }
    }

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0:  WelcomeStep()
        case 1:  DependenciesStep(deps: $deps)
        case 2:  SystemExtStep()
        case 3:  QuickSetupStep()
        case 4:  ReadyStep(deps: $deps)
        default: WelcomeStep()
        }
    }
}

// MARK: - Step 0 — Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.brandDim)
                    .frame(width: 108, height: 108)
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .font(.system(size: 46, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brand)
            }

            VStack(spacing: 9) {
                Text("Welcome to NTFSMount")
                    .font(.system(size: 23, weight: .bold))

                Text("Read and write to NTFS drives on your Mac —\nfree, forever, open source.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            HStack(spacing: 28) {
                FeaturePill(icon: "lock.open.fill",    label: "Read & Write")
                FeaturePill(icon: "bolt.fill",          label: "Native Speed")
                FeaturePill(icon: "heart.fill",         label: "Open Source")
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Step 1 — Dependencies

private struct DependenciesStep: View {
    @Binding var deps: DepStatus
    @State private var checking = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 7) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 36, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brand)

                Text("Install Dependencies")
                    .font(.system(size: 21, weight: .bold))

                Text("NTFSMount needs macFUSE and ntfs-3g to work.\nInstall them once via Homebrew — takes ~2 minutes.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2.5)
            }

            // Status row
            HStack(spacing: 18) {
                DepBadge(label: "Homebrew",  ok: deps.homebrew, optional: true)
                DepBadge(label: "macFUSE",   ok: deps.macFUSE,  optional: false)
                DepBadge(label: "ntfs-3g",   ok: deps.ntfs3g,   optional: false)
            }
            .padding(.vertical, 4)

            // Commands
            VStack(alignment: .leading, spacing: 6) {
                if !deps.homebrew {
                    CommandRow(
                        label: "① Install Homebrew (if needed)",
                        command: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    )
                }
                CommandRow(
                    label: deps.homebrew ? "① Install macFUSE" : "② Install macFUSE",
                    command: "brew install --cask macfuse"
                )
                CommandRow(
                    label: deps.homebrew ? "② Install ntfs-3g" : "③ Install ntfs-3g",
                    command: "brew install gromgit/fuse/ntfs-3g-mac"
                )
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    openTerminalWith(command: "brew install --cask macfuse && brew install gromgit/fuse/ntfs-3g-mac")
                } label: {
                    Label("Open Terminal", systemImage: "terminal.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    NSWorkspace.shared.open(URL(string: "https://macfuse.github.io")!)
                } label: {
                    Label("macFUSE website", systemImage: "arrow.up.right.square")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    checking = true
                    DispatchQueue.global().async {
                        let result = checkDeps()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            deps = result
                            checking = false
                        }
                    }
                } label: {
                    Label(checking ? "Checking…" : "Check Again",
                          systemImage: checking ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.brand)
                .disabled(checking)
            }
        }
        .padding(.horizontal, 38)
    }
}

// MARK: - Step 2 — System Extension

private struct SystemExtStep: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 42, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.brand)

            VStack(spacing: 8) {
                Text("Allow System Extension")
                    .font(.system(size: 21, weight: .bold))
                Text("macOS requires your approval to load the macFUSE\nkernel extension on first install.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 11) {
                OnboardingStep(n: "1", text: "Open System Settings → Privacy & Security")
                OnboardingStep(n: "2", text: "Scroll to the Security section at the bottom")
                OnboardingStep(n: "3", text: "Click \"Allow\" next to the macFUSE entry")
                OnboardingStep(n: "4", text: "Enter your password and restart when prompted")
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button("Open System Settings") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text("·")
                    .foregroundStyle(.tertiary)

                Button("Skip if already done") {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 44)
    }
}

// MARK: - Step 3 — Quick Setup

private struct QuickSetupStep: View {
    @EnvironmentObject var prefs: PreferencesManager

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 7) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 38, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brand)

                Text("Quick Setup")
                    .font(.system(size: 21, weight: .bold))

                Text("Configure your preferences now — you can always\nchange these later in the menu bar.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2.5)
            }

            VStack(spacing: 0) {
                ToggleRow(
                    icon: "arrow.up.right",
                    iconColor: Color.brand,
                    title: "Launch at Login",
                    subtitle: "Start NTFSMount automatically when you log in",
                    isOn: $prefs.launchAtLogin
                )

                Divider().opacity(0.15)

                ToggleRow(
                    icon: "bolt.fill",
                    iconColor: Color.brand,
                    title: "Auto-mount NTFS Drives",
                    subtitle: "Mount drives with write access as soon as they connect",
                    isOn: $prefs.autoMount
                )

                Divider().opacity(0.15)

                ToggleRow(
                    icon: "folder.fill",
                    iconColor: Color.brand,
                    title: "Open Finder on Mount",
                    subtitle: "Automatically show the drive in Finder when mounted",
                    isOn: $prefs.openFinderOnMount
                )

                Divider().opacity(0.15)

                ToggleRow(
                    icon: "bell.fill",
                    iconColor: Color.brand,
                    title: "Show Notifications",
                    subtitle: "Get notified when drives are mounted or ejected",
                    isOn: $prefs.showNotifications
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Step 4 — Ready

private struct ReadyStep: View {
    @Binding var deps: DepStatus
    @State private var pulse = false
    @State private var checking = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill((deps.allReady ? Color.brand : Color.orange).opacity(pulse ? 0.06 : 0.14))
                    .frame(width: 108, height: 108)
                    .scaleEffect(pulse ? 1.10 : 1.0)
                    .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: deps.allReady
                      ? "checkmark.circle.fill"
                      : "exclamationmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(deps.allReady ? Color.brand : Color.orange)
            }
            .onAppear { pulse = true }

            VStack(spacing: 8) {
                Text(deps.allReady ? "You're All Set!" : "Almost There")
                    .font(.system(size: 22, weight: .bold))

                Text(deps.allReady
                     ? "Everything is installed and configured.\nConnect an NTFS drive and tap Mount R/W."
                     : "Some dependencies are missing.\nInstall them in step 2 to enable full functionality.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Dep summary
            HStack(spacing: 20) {
                DepBadge(label: "macFUSE", ok: deps.macFUSE, optional: false)
                DepBadge(label: "ntfs-3g", ok: deps.ntfs3g, optional: false)
            }

            Button {
                checking = true
                DispatchQueue.global().async {
                    let result = checkDeps()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        deps = result
                        checking = false
                    }
                }
            } label: {
                Label(checking ? "Checking…" : "Verify Installation",
                      systemImage: checking ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(checking)
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Helper components

private struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color.brand)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

private struct OnboardingStep: View {
    let n: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 11) {
            Text(n)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(Color.brand)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }
}

private struct DepBadge: View {
    let label: String
    let ok: Bool
    let optional: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ok ? Color.brand : (optional ? Color.secondary : Color.orange))
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ok ? Color.primary : Color.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ok ? Color.brandDim : Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            ok ? Color.brand.opacity(0.35) : Color.white.opacity(0.08),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

private struct CommandRow: View {
    let label: String
    let command: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            CopyableCode(command)
        }
    }
}

private struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(Color.brand)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Terminal launcher

private func openTerminalWith(command: String) {
    let safe = command.replacingOccurrences(of: "\\", with: "\\\\")
                      .replacingOccurrences(of: "\"", with: "\\\"")
    let source = """
    tell application "Terminal"
        activate
        do script "\(safe)"
    end tell
    """
    if let script = NSAppleScript(source: source) {
        var err: NSDictionary?
        script.executeAndReturnError(&err)
    }
}

// MARK: - CopyableCode

struct CopyableCode: View {
    let code: String
    @State private var copied = false

    init(_ code: String) { self.code = code }

    var body: some View {
        HStack {
            Text(code)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Color.brand)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(copied ? Color.brand : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Brand button style

struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.brand.opacity(configuration.isPressed ? 0.75 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Keep old name as typealias so existing references still compile
typealias CyanButtonStyle = BrandButtonStyle

// MARK: - Preview

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(PreferencesManager.shared)
    }
}
#endif
