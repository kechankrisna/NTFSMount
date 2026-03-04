# NTFSMount

> Free, open-source NTFS read/write for macOS — built on **macFUSE** + **ntfs-3g**.

macOS can read NTFS drives out of the box but cannot write to them natively. NTFSMount sits in your menu bar and mounts any NTFS drive with full read/write access in one click — no Terminal required.

**Author:** [KECHANKRISNA](mailto:ke.chankrisna168@gmail.com)

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installing Dependencies](#installing-dependencies)
- [Building from Source](#building-from-source)
- [First Launch](#first-launch)
- [Seamless Mounting (Password-Free)](#seamless-mounting-password-free)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **One-click R/W mounting** — mount any NTFS drive with write access from the menu bar
- **Auto-detection** — scans all connected drives on launch and when drives are plugged in
- **Seamless mode** — optional one-time setup so mounts never ask for a password again
- **Storage bar** — visual used/free indicator per drive
- **Auto-mount** — automatically mount NTFS drives with write access when connected
- **Open Finder** — optionally open a Finder window after mounting
- **Onboarding wizard** — step-by-step first-launch setup for macFUSE and ntfs-3g
- **Menu bar icon** — color-coded to show app state (cyan = active R/W, red = error, default = idle)
- **Dark mode** — native macOS appearance

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 14 Sonoma or later |
| Xcode | 15 or later |
| Swift | 5.9 or later |
| [macFUSE](https://osxfuse.github.io) | 4.x |
| [ntfs-3g-mac](https://github.com/gromgit/homebrew-fuse) | any recent |

---

## Installing Dependencies

NTFSMount relies on two open-source components. Install them once and the app handles everything else.

### 1. macFUSE (kernel extension)

```bash
brew install --cask macfuse
```

After installation, macOS will prompt you to approve the kernel extension:

1. Open **System Settings → Privacy & Security**
2. Scroll down and click **Allow** next to the macFUSE entry
3. **Restart your Mac** when prompted

### 2. ntfs-3g (filesystem driver)

The standard Homebrew formula is Linux-only. Use the macOS-specific tap:

```bash
brew install gromgit/fuse/ntfs-3g-mac
```

> **Note:** If you see `"Linux is required"` you are using the wrong formula. Use `gromgit/fuse/ntfs-3g-mac` exactly as shown above.

---

## Building from Source

```bash
# Clone the repository
git clone https://github.com/KECHANKRISNA/ntfsmount.git
cd ntfsmount/NTFSMount

# Open in Xcode
open Package.swift
```

Xcode will resolve the Swift Package and open the project. Press **⌘R** to build and run. The app appears as a menu bar icon (no Dock icon — it's a `LSUIElement` app).

### Demo / Preview Mode

To preview the full UI without installing macFUSE or ntfs-3g, enable demo mode:

```swift
// NTFSMountApp.swift — change the mounter initialiser:
@StateObject private var mounter = NTFSMounter(demo: true)
```

Or in `NTFSMounter.init()`:

```swift
self.isDemoMode = true
```

This populates the drive list with sample data so you can iterate on the UI freely.

---

## First Launch

When the app launches for the first time (or when a dependency is missing) the **Setup Wizard** opens automatically. It walks through four steps:

1. **Welcome** — overview of what NTFSMount does
2. **Install macFUSE** — copy-paste Homebrew command, with a link to approve the system extension
3. **Install ntfs-3g** — copy-paste Homebrew command for the macOS tap
4. **Ready** — confirm dependencies are detected and start using the app

You can re-run the wizard at any time from **Preferences → About → Re-run Setup Wizard**.

---

## Seamless Mounting (Password-Free)

By default, each mount operation shows the macOS administrator password dialog (because ntfs-3g requires root privileges). You can eliminate this prompt permanently with a one-time setup:

1. Open **Preferences** (click the gear icon in the menu bar popover footer, or press **⌘,**)
2. Go to the **Drives** tab
3. In the **Permissions** section, click **Enable…**
4. Enter your password **once** — this installs a sudoers rule at `/etc/sudoers.d/ntfsmount`
5. From now on, all mounts are silent and instant — no dialogs, no prompts

To revert at any time, click **Disable** in the same section (or run `sudo rm /etc/sudoers.d/ntfsmount` in Terminal).

---

## Usage

| Action | How |
|---|---|
| **See connected NTFS drives** | Click the menu bar icon |
| **Mount R/W** | Click "Mount R/W" on any unmounted or read-only drive |
| **Eject** | Click "Eject" on a mounted drive, or right-click for the context menu |
| **Refresh drive list** | Click the ↺ refresh icon in the header |
| **Open Preferences** | Click the gear icon in the footer |
| **Quit** | Click "Quit" in the footer |

### Drive Row Colors

| Color | Meaning |
|---|---|
| **Cyan** | Mounted with read/write access |
| **Blue** | Mounted read-only (macOS default) |
| **Grey** | Unmounted / not yet mounted |

---

## Project Structure

```
Sources/NTFSMount/
├── NTFSMountApp.swift           # @main App entry — MenuBarExtra + Settings + Onboarding scenes
├── Info.plist                   # Bundle metadata (LSUIElement = YES hides Dock icon)
│
├── Models/
│   ├── NTFSDrive.swift          # Drive model (id, bsdName, mountPoint, usage …)
│   └── MountError.swift         # Typed LocalizedError enum
│
├── Core/
│   ├── DiskScanner.swift        # diskutil list/info -plist → [NTFSDrive]
│   ├── NTFSMounter.swift        # @MainActor ObservableObject — orchestrates mount/eject/scan
│   └── PreferencesManager.swift # UserDefaults-backed singleton with @Published settings
│
└── Views/
    ├── DriveListView.swift       # 360pt popover root — header / drive list / error banner / footer
    ├── DriveRowView.swift        # Per-drive row: icon, name, storage bar, Mount/Eject buttons
    ├── EmptyStateView.swift      # Animated "No NTFS drives" placeholder
    ├── OnboardingView.swift      # 4-step first-launch wizard
    └── PreferencesView.swift     # Settings window — General / Drives / Logs / About tabs
```

---

## Architecture

### Layers

| Layer | File | Responsibility |
|---|---|---|
| **Model** | `NTFSDrive`, `MountError` | Pure data; no side effects |
| **Scanner** | `DiskScanner` | Runs `diskutil`, parses plist output, returns drive array |
| **Orchestrator** | `NTFSMounter` | `@MainActor` state machine; drives all SwiftUI updates |
| **Preferences** | `PreferencesManager` | Singleton; `@Published` props backed by `UserDefaults` |
| **Views** | `Views/` | Stateless display layer; actions via `async Task {}` |

### NTFS Drive Detection

`DiskScanner` identifies NTFS partitions by checking the `Content` and `FilesystemType` keys returned by `diskutil info -plist`. It handles both partition schemes:

- **GPT** (most modern drives) → `Content = "Microsoft Basic Data"`
- **MBR / FDisk** (older drives, e.g. some external HDDs) → `Content = "Windows_NTFS"`

### Privilege Escalation

Mounting NTFS with ntfs-3g requires root. NTFSMount uses two strategies:

| Mode | Mechanism | User interaction |
|---|---|---|
| **Standard** | `osascript … with administrator privileges` | macOS password dialog on each mount |
| **Seamless** | `sudo -n` (NOPASSWD sudoers rule) | None after one-time setup |

The sudoers rule written by `setupSeamlessMount()` is scoped to exactly three commands (`ntfs-3g`, `ntfs-3g-mac`, `mkdir`) and is stored in `/etc/sudoers.d/ntfsmount`.

### Production Path (XPC Helper)

For App Store / notarized distribution, replace the `shellPrivileged()` call in `NTFSMounter.mount(_:)` with an XPC call to a separately-signed `com.ntfsmount.helper` binary installed via `SMJobBless`. See the Technical Development Plan (`NTFSMount_Technical_Plan.docx`) for the full design.

---

## Troubleshooting

### App icon appears but no drives are listed

- Verify the drive is formatted as NTFS (not exFAT or FAT32)
- Open Terminal and run `diskutil list` — look for a `Windows_NTFS` or `Microsoft Basic Data` entry
- Click the ↺ refresh button in the app header
- Check that macFUSE is approved: **System Settings → Privacy & Security**

### "Unprivileged user cannot mount NTFS block device"

This means ntfs-3g was called without root privileges. Fix options:

1. **Recommended:** Set up Seamless Mounting in Preferences → Drives → Permissions → Enable…
2. **Manual:** The macOS password dialog should appear automatically on mount — if it doesn't, re-install ntfs-3g via `brew reinstall gromgit/fuse/ntfs-3g-mac`

### "No available formula with the name 'ntfs-3g-mac'"

Use the full tap path:

```bash
brew install gromgit/fuse/ntfs-3g-mac
```

Do **not** use `brew install ntfs-3g` or `brew install ntfs-3g-mac` — those formulas are Linux-only or don't exist.

### macFUSE system extension blocked

After `brew install --cask macfuse` you **must** manually approve the kernel extension:

1. **System Settings → Privacy & Security → Security**
2. Click **Allow** next to "System software from developer Benjamin Fleischer"
3. Restart your Mac

### Mount succeeds but drive is still read-only in Finder

macOS may have already mounted the drive read-only before NTFSMount ran. Click **Eject** first (this unmounts the macOS read-only mount), then click **Mount R/W**.

### "Linux is required for this software" when installing ntfs-3g

```bash
# Wrong:
brew install ntfs-3g

# Correct:
brew install gromgit/fuse/ntfs-3g-mac
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please open an issue first for significant changes so the approach can be discussed.

---

## License

GPL-3.0 — see [LICENSE](LICENSE).

Built on [macFUSE](https://osxfuse.github.io) (BSD) and [ntfs-3g](https://github.com/tuxera/ntfs-3g) (GPL-2.0+).

---

*© 2026 KECHANKRISNA · [ke.chankrisna168@gmail.com](mailto:ke.chankrisna168@gmail.com)*
