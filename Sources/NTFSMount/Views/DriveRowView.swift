import SwiftUI
import AppKit

// MARK: - DriveRowView

struct DriveRowView: View {

    let drive: NTFSDrive
    @EnvironmentObject var mounter: NTFSMounter
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── Top row: icon + info + action ──────────────────────────────
            HStack(alignment: .center, spacing: 10) {
                driveIcon
                driveInfo
                Spacer(minLength: 8)
                actionControl
            }

            // ── Storage bar (only when mounted and size is known) ──────────
            if drive.isMounted && drive.totalBytes > 0 {
                storageBar
                    .padding(.leading, 46)   // align with text
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isHovered ? Color.white.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu { contextMenuItems }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    // ── Drive icon ─────────────────────────────────────────────────────────

    private var driveIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(iconBackgroundColor)
                .frame(width: 36, height: 36)

            if drive.isMounting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.65)
            } else {
                Image(systemName: driveSystemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconForegroundColor)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: 36, height: 36)
    }

    private var driveSystemImage: String {
        if drive.isWritable { return "externaldrive.fill.badge.checkmark" }
        if drive.isMounted  { return "externaldrive.fill" }
        return "externaldrive"
    }

    private var iconBackgroundColor: Color {
        if drive.isWritable { return .cyan.opacity(0.16) }
        if drive.isMounted  { return .blue.opacity(0.13) }
        return Color(.controlBackgroundColor).opacity(0.6)
    }

    private var iconForegroundColor: Color {
        if drive.isWritable { return .cyan }
        if drive.isMounted  { return .blue }
        return .secondary
    }

    // ── Drive info ─────────────────────────────────────────────────────────

    private var driveInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Volume name
            Text(drive.volumeName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            // BSD + R/W badge
            HStack(spacing: 5) {
                Text(drive.bsdName)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                if drive.isMounting {
                    Text("mounting…")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                } else if drive.isWritable {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil")
                            .font(.system(size: 8, weight: .bold))
                        Text("Read / Write")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.cyan)
                } else if drive.isMounted {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("Read Only")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text("Not Mounted")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(.tertiaryLabelColor))
                }
            }
        }
    }

    // ── Action control ─────────────────────────────────────────────────────

    @ViewBuilder
    private var actionControl: some View {
        if drive.isMounting {
            // Spinner already shown in icon; tiny label here
            Text("…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 70)
        } else if drive.isWritable {
            // Eject button
            Button {
                Task { await mounter.eject(drive) }
            } label: {
                Label("Eject", systemImage: "eject")
                    .labelStyle(.titleOnly)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        } else {
            // Mount R/W button
            Button {
                Task { await mounter.mount(drive) }
            } label: {
                Text("Mount R/W")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }

    // ── Storage bar ────────────────────────────────────────────────────────

    private var storageBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Track + fill
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.09))

                    Capsule()
                        .fill(LinearGradient(
                            colors: barGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * drive.usagePercent))
                }
            }
            .frame(height: 4)

            // Byte labels
            HStack {
                Text("\(drive.displayFree) free")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(drive.displaySize)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.tertiaryLabelColor))
            }
        }
    }

    private var barGradientColors: [Color] {
        let p = drive.usagePercent
        if p > 0.90 { return [.red,    .orange] }
        if p > 0.75 { return [.orange, .yellow] }
        return               [.blue,   .cyan  ]
    }

    // ── Context menu ───────────────────────────────────────────────────────

    @ViewBuilder
    private var contextMenuItems: some View {
        // Open in Finder
        Button {
            guard let mp = drive.mountPoint else { return }
            NSWorkspace.shared.open(URL(fileURLWithPath: mp))
        } label: {
            Label("Open in Finder", systemImage: "folder")
        }
        .disabled(drive.mountPoint == nil)

        Divider()

        // Copy BSD name
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(drive.bsdName, forType: .string)
        } label: {
            Label("Copy BSD Name", systemImage: "doc.on.doc")
        }

        // Copy mount point
        if let mp = drive.mountPoint {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(mp, forType: .string)
            } label: {
                Label("Copy Mount Path", systemImage: "doc.on.clipboard")
            }
        }

        Divider()

        // Eject
        if drive.isWritable || drive.isMounted {
            Button(role: .destructive) {
                Task { await mounter.eject(drive) }
            } label: {
                Label("Eject", systemImage: "eject.fill")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DriveRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            DriveRowView(drive: .sampleRW)
            Divider().opacity(0.15)
            DriveRowView(drive: .sampleRO)
            Divider().opacity(0.15)
            DriveRowView(drive: .sampleUnmounted)
            Divider().opacity(0.15)
            DriveRowView(drive: .sampleMounting)
        }
        .environmentObject(NTFSMounter())
        .frame(width: 360)
        .preferredColorScheme(.dark)
    }
}
#endif
