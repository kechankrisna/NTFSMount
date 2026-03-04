import SwiftUI
import AppKit

// MARK: - OnboardingView
// 4-step first-launch wizard: Welcome → macFUSE → System Extension → Ready

struct OnboardingView: View {

    @EnvironmentObject var prefs: PreferencesManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress dots ─────────────────────────────────────────────
            HStack(spacing: 7) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? Color.cyan : Color.white.opacity(0.18))
                        .frame(width: i == currentStep ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // ── Step body (animated slide) ────────────────────────────────
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

            // ── Navigation ────────────────────────────────────────────────
            HStack {
                // Back
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }

                Spacer()

                // Skip (steps 1 and 2 only)
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    Button("Skip") {
                        withAnimation { currentStep += 1 }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .buttonStyle(.plain)
                }

                // Next / Finish
                if currentStep < totalSteps - 1 {
                    Button(currentStep == 0 ? "Get Started →" : "Continue →") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(CyanButtonStyle())
                } else {
                    Button("Launch NTFSMount  ↗") {
                        prefs.hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(CyanButtonStyle())
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 32)
            .padding(.top, 16)
        }
        .frame(width: 520, height: 420)
        .background(Color(.windowBackgroundColor))
        .preferredColorScheme(.dark)
    }

    // ── Step switcher ──────────────────────────────────────────────────────

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0:  WelcomeStep()
        case 1:  MacFUSEStep()
        case 2:  SystemExtStep()
        case 3:  ReadyStep()
        default: WelcomeStep()
        }
    }
}

// MARK: - Step 0 — Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .font(.system(size: 44, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.cyan)
            }

            VStack(spacing: 8) {
                Text("Welcome to NTFSMount")
                    .font(.system(size: 22, weight: .bold))

                Text("Read and write to NTFS drives on your Mac —\nfree, forever, open source.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            HStack(spacing: 24) {
                FeaturePill(icon: "lock.open.fill",   label: "Read & Write")
                FeaturePill(icon: "bolt.fill",         label: "Native Speed")
                FeaturePill(icon: "heart.fill",        label: "Open Source")
            }
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Step 1 — macFUSE

private struct MacFUSEStep: View {

    @State private var installed: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: installed
                  ? "checkmark.circle.fill"
                  : "cube.box.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(installed ? .green : .cyan)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text("Install macFUSE")
                    .font(.system(size: 22, weight: .bold))
                Text("macFUSE lets macOS use third-party filesystem drivers like ntfs-3g.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            if installed {
                Label("macFUSE is installed ✓", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 8) {
                    Text("Run these two commands in Terminal:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    // Step 1: macFUSE
                    VStack(alignment: .leading, spacing: 3) {
                        Text("① macFUSE kernel extension")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        CopyableCode("brew install --cask macfuse")
                    }

                    // Step 2: ntfs-3g (macOS tap)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("② ntfs-3g driver (macOS tap)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        CopyableCode("brew install gromgit/fuse/ntfs-3g-mac")
                    }

                    Button("Download macFUSE manually") {
                        NSWorkspace.shared.open(
                            URL(string: "https://macfuse.github.io")!)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 48)
        .onAppear {
            installed = FileManager.default.fileExists(
                atPath: "/Library/Filesystems/macfuse.fs")
        }
    }
}

// MARK: - Step 2 — System Extension

private struct SystemExtStep: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "shield.fill")
                .font(.system(size: 44, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.cyan)

            VStack(spacing: 8) {
                Text("Allow System Extension")
                    .font(.system(size: 22, weight: .bold))
                Text("macOS needs your approval to load the macFUSE kernel extension.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 10) {
                OnboardingStep(n: "1", text: "Open System Settings → Privacy & Security")
                OnboardingStep(n: "2", text: "Scroll to the Security section")
                OnboardingStep(n: "3", text: "Click \"Allow\" next to the macFUSE entry")
                OnboardingStep(n: "4", text: "Restart your Mac when prompted")
            }

            Button("Open System Settings") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Step 3 — Ready

private struct ReadyStep: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(pulse ? 0.06 : 0.14))
                    .frame(width: 108, height: 108)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.cyan)
            }
            .onAppear { pulse = true }

            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.system(size: 22, weight: .bold))

                Text("NTFSMount lives in your menu bar.\nConnect any NTFS drive and tap \"Mount R/W\".")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Helper components

private struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.cyan)
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
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(n)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(Color.cyan)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }
}

struct CopyableCode: View {
    let code: String
    @State private var copied = false

    init(_ code: String) { self.code = code }

    var body: some View {
        HStack {
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.cyan)
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: 320)
    }
}

// MARK: - Cyan button style

struct CyanButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(configuration.isPressed ? 0.75 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(PreferencesManager.shared)
    }
}
#endif
