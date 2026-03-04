# NTFSMount — User Guide

**Version 1.0 · macOS 14 Sonoma and later**

---

## What Is NTFSMount?

macOS can read files from NTFS drives (the format used by Windows) but **cannot write to them** by default. If you have ever plugged in a Windows external hard drive or USB stick and found you couldn't save, copy, or delete files — that is the NTFS write restriction.

NTFSMount solves this problem. It sits quietly in your menu bar and lets you mount any NTFS drive with full **read and write** access in one click, with no Terminal commands required during normal use.

---

## Before You Start — Install the Required Tools

NTFSMount needs two free, open-source components. You only do this once.

> **You need Homebrew installed.** If you don't have it, open Terminal and run:
> ```
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```

### Step 1 — Install macFUSE

macFUSE is a macOS kernel extension that allows third-party filesystems (like NTFS) to work on your Mac.

Open **Terminal** and run:

```bash
brew install --cask macfuse
```

When it finishes, you **must** approve the system extension:

1. Open **System Settings** (Apple menu → System Settings)
2. Go to **Privacy & Security**
3. Scroll down to the **Security** section
4. Click **Allow** next to "System software from developer Benjamin Fleischer"
5. You will be asked to restart — **restart your Mac now**

> ⚠️ If you skip the restart or the "Allow" step, NTFSMount will not be able to mount drives.

---

### Step 2 — Install ntfs-3g

ntfs-3g is the filesystem driver that actually reads and writes NTFS data.

Open **Terminal** and run:

```bash
brew install gromgit/fuse/ntfs-3g-mac
```

> **Important:** Use this exact command. The similar-looking `brew install ntfs-3g` is Linux-only and will not work on macOS.

---

### Step 3 — Launch NTFSMount

Double-click **NTFSMount** in your Applications folder (or wherever you saved it).

You will not see a new window in the Dock — NTFSMount lives entirely in the **menu bar** at the top right of your screen. Look for the drive icon (🖥) near the clock.

---

## First Launch — Setup Wizard

If NTFSMount cannot find macFUSE or ntfs-3g, it opens the **Setup Wizard** automatically. The wizard guides you through the same steps above. You can:

- Copy each Terminal command with the copy button next to it
- Click **Open System Settings** to jump straight to the Privacy & Security page
- Click **Back** or **Next** to move between steps

Once both tools are detected, the wizard shows a green "Ready" screen. Click **Start Using NTFSMount**.

> You can re-open the Setup Wizard at any time from **Preferences → About → Re-run Setup Wizard**.

---

## Using the App

### Opening the Drive List

Click the **NTFSMount icon** in the menu bar (top-right corner of your screen). A panel drops down showing all connected NTFS drives.

### Understanding Drive Status

Each drive row shows:

| Icon color | What it means |
|---|---|
| 🔵 **Cyan** | Mounted with **read and write** access — you can freely copy, edit, and delete files |
| 🔵 **Blue** | Mounted **read-only** — macOS mounted it before NTFSMount could (click "Mount R/W" to upgrade) |
| ⚫ **Grey** | Not mounted — click "Mount R/W" to access it |

The storage bar below the drive name shows how much space is used and how much is free.

---

### Mounting a Drive with Write Access

1. Click the NTFSMount menu bar icon
2. Find your drive in the list
3. Click **Mount R/W**

If Seamless Mounting is not yet set up, macOS will ask for your administrator password — this is normal and required so the filesystem driver can run with the necessary permissions. Enter your password and click **OK**.

The drive will appear on your Desktop and in Finder's sidebar, ready for full read/write access.

---

### Ejecting a Drive

Before physically disconnecting a drive, always eject it properly:

1. Click the NTFSMount menu bar icon
2. Find the drive in the list
3. Click **Eject**

You can also right-click (or Control-click) on a drive row for a context menu with additional options.

---

### Refreshing the Drive List

If you plug in a drive and it doesn't appear, click the **↺ refresh button** in the top-right corner of the panel. The app also refreshes automatically when drives are connected or disconnected.

---

## Setting Up Seamless Mounting (Recommended)

By default, NTFSMount asks for your administrator password each time you mount a drive. You can eliminate this permanently with a one-time setup:

1. Click the menu bar icon to open the panel
2. Click **Preferences** (gear icon in the bottom-left of the panel), or press **⌘,**
3. Go to the **Drives** tab
4. In the **Permissions** section, click **Enable…**
5. Enter your administrator password **one final time**
6. You will see "✓ Seamless mounting enabled" — done!

From this point on, all mounts are instant and silent. No password dialog will ever appear again.

### Disabling Seamless Mounting

If you want to restore the password prompt (for example on a shared Mac), go back to **Preferences → Drives → Permissions** and click **Disable**.

---

## Preferences

Open Preferences by clicking the gear icon in the panel footer or pressing **⌘,**.

### General Tab

| Setting | Description |
|---|---|
| Launch at login | Start NTFSMount automatically when you log in to your Mac |
| Notify when mounted or ejected | Show a notification banner when drive status changes |
| Warn before ejecting a busy drive | Show a confirmation dialog if a drive is in use |

### Drives Tab

| Setting | Description |
|---|---|
| Auto-mount on connect | Automatically mount NTFS drives with write access when you plug them in (requires Seamless Mounting) |
| Open Finder after mounting | Open a Finder window showing the drive contents after a successful mount |
| Seamless Mounting | One-time setup for password-free mounting (see above) |

### Logs Tab

Shows the location of the application log files and provides quick access to the macOS Console app. Useful for diagnosing issues.

### About Tab

Shows the version number, links to the GitHub repository and license, and a button to re-run the Setup Wizard.

---

## Menu Bar Icon Colors

The NTFSMount icon in the menu bar changes color to give you a quick status overview:

| Icon appearance | What it means |
|---|---|
| **Cyan** | One or more drives are mounted with write access |
| **Red** | An error occurred (click the icon to see details) |
| **Default (white/black)** | App is running, no drives currently mounted R/W |

---

## Troubleshooting

### My drive doesn't appear in the list

- Make sure the drive is formatted as NTFS. Open **Disk Utility** (Finder → Applications → Utilities → Disk Utility) and check the format shown for the drive. If it says "exFAT" or "MS-DOS (FAT32)" it is a different format — NTFSMount only handles NTFS.
- Click the **↺ refresh** button in the header.
- Try unplugging and re-plugging the drive.

### I click "Mount R/W" but nothing happens / I see an error

The most common cause is macFUSE's system extension not being approved. Check:

1. **System Settings → Privacy & Security → Security**
2. Look for a message about macFUSE or "Benjamin Fleischer" and click **Allow**
3. Restart your Mac if prompted

If the error message says "Unprivileged user cannot mount", set up Seamless Mounting (Preferences → Drives → Enable) and try again.

### The drive shows in Finder but I still can't write files

macOS may have mounted the drive read-only before NTFSMount got a chance to act. To fix this:

1. In NTFSMount, click **Eject** on the drive (this removes the read-only mount)
2. Then click **Mount R/W** to re-mount it with write access

### "macFUSE not installed" warning appears even though I installed it

The system extension may not have been approved yet, or your Mac needs a restart. Check **System Settings → Privacy & Security** and look for the Allow button. After approving, restart your Mac.

### I installed ntfs-3g but the app says it can't find it

Make sure you used the correct Homebrew command:

```bash
brew install gromgit/fuse/ntfs-3g-mac
```

If you previously ran `brew install ntfs-3g`, uninstall it first (`brew uninstall ntfs-3g`) and then install the correct version above.

---

## Frequently Asked Questions

**Is NTFSMount safe to use?**
Yes. It uses the same ntfs-3g driver that Linux distributions have shipped for over 15 years. Your data is no more at risk than on a Windows machine.

**Will this format or erase my drive?**
No. NTFSMount only mounts existing NTFS drives. It does not create, format, or erase drives. Use Disk Utility if you need to format a drive.

**Can I use this with Time Machine or backups?**
NTFSMount is for NTFS drives only. Time Machine uses Apple's own format (APFS or HFS+). You cannot use an NTFS drive as a Time Machine destination.

**Does it work with USB sticks, not just hard drives?**
Yes, any storage device formatted as NTFS works — USB sticks, portable SSDs, external hard drives, SD cards in USB adapters, etc.

**What happens if I unplug the drive without ejecting first?**
The filesystem driver will unmount automatically. To avoid any risk of data corruption, always eject via NTFSMount or Finder before physically disconnecting the drive, especially if files are open or being transferred.

**Can I have multiple NTFS drives mounted at once?**
Yes. NTFSMount displays and manages all connected NTFS drives independently.

---

## Uninstalling

To completely remove NTFSMount and its components:

1. **Quit NTFSMount** — click the menu bar icon → Quit
2. **Delete the app** — drag NTFSMount from Applications to Trash
3. **Remove Seamless Mounting rule** (if set up):
   ```bash
   sudo rm /etc/sudoers.d/ntfsmount
   ```
4. **Uninstall ntfs-3g** (optional):
   ```bash
   brew uninstall gromgit/fuse/ntfs-3g-mac
   ```
5. **Uninstall macFUSE** (optional — only if no other apps need it):
   ```bash
   brew uninstall --cask macfuse
   ```

---

## Getting Help

- **GitHub Issues:** [github.com/ntfsmount/ntfsmount/issues](https://github.com/ntfsmount/ntfsmount/issues)
- **Re-run Setup Wizard:** Preferences → About → Re-run Setup Wizard
- **Application Logs:** Preferences → Logs → Open Log Folder

---

*NTFSMount is free and open-source software, released under the GPL-3.0 license.*
*Built on macFUSE and ntfs-3g.*
*© 2026 KECHANKRISNA · [ke.chankrisna168@gmail.com](mailto:ke.chankrisna168@gmail.com)*
