import SwiftUI

// MARK: - EmptyStateView
// Shown in the popover when no NTFS drives are detected.

struct EmptyStateView: View {

    @State private var iconScale: CGFloat = 0.85
    @State private var iconOpacity: Double = 0.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            // Animated icon badge
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.08))
                    .frame(width: 72, height: 72)

                Circle()
                    .strokeBorder(Color.cyan.opacity(0.15), lineWidth: 1)
                    .frame(width: 72, height: 72)

                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 28, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.cyan)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    iconScale   = 1.0
                    iconOpacity = 1.0
                }
            }

            Spacer(minLength: 16)

            // Copy
            VStack(spacing: 6) {
                Text("No NTFS Drives")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Connect an NTFS-formatted drive\nto get started.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Spacer(minLength: 20)

            // Hint pill
            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("NTFS drives from Windows PCs are supported.")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color(.tertiaryLabelColor))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.04)))

            Spacer(minLength: 28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView()
            .frame(width: 360)
            .background(.ultraThinMaterial)
            .preferredColorScheme(.dark)
    }
}
#endif
