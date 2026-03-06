# Build Instructions

This guide details how to build RenLocalizer into standalone executables for Windows, Linux, and macOS.

## 📋 Prerequisites

- **Python 3.10+** (Recommended: 3.12)
- **Pip** & **Virtualenv**
- **Git**

## 🏗️ Building for Distribution

RenLocalizer uses `PyInstaller` to create standalone executables. The build process is configured in `RenLocalizer.spec` to produce two separate binaries:
1. **RenLocalizer** (GUI Version)
2. **RenLocalizerCLI** (Command Line Version)

### 1. Setup Environment
```bash
# Clone and enter repo
git clone https://github.com/Lord0fTurk/RenLocalizer.git
cd RenLocalizer

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate
# Activate (Linux/macOS)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install pyinstaller
```

### 2. Run the Build
Use the provided spec file which handles hidden imports (OpenAI, Gemini, UnRPA) and asset bundling automatically.

```bash
pyinstaller RenLocalizer.spec --clean --noconfirm
```

### 3. Check Artifacts
The build output will be in the `dist/` directory.
- `dist/RenLocalizer/`: Contains the main executable and all dependencies (Folder/Onedir mode).
  - `RenLocalizer` (GUI)
  - `RenLocalizerCLI` (CLI)

> **Note:** We use "Onedir" mode (folder based) instead of "Onefile" to ensure faster startup times and better compatibility with external assets like `locales/` and `tools/`.

---

## 📦 Platform-Specific Packaging

After the base PyInstaller build, each platform has an additional packaging step:

### Windows
No extra step. The `dist/RenLocalizer/` folder is shipped as a `.zip` archive.

### Linux → AppImage
The `dist/RenLocalizer/` output is wrapped into an AppImage for single-file distribution.

```bash
# Install prerequisites
sudo apt-get install libfuse2 imagemagick

# Convert icon
convert icon.ico[0] -resize 256x256 renlocalizer.png

# Create AppDir structure
mkdir -p RenLocalizer.AppDir/usr/bin
cp -R dist/RenLocalizer RenLocalizer.AppDir/usr/bin/RenLocalizer
cp build/linux/AppRun RenLocalizer.AppDir/AppRun
chmod +x RenLocalizer.AppDir/AppRun
cp build/linux/renlocalizer.desktop RenLocalizer.AppDir/renlocalizer.desktop
cp renlocalizer.png RenLocalizer.AppDir/renlocalizer.png

# Download appimagetool and build
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O appimagetool
chmod +x appimagetool
ARCH=x86_64 ./appimagetool RenLocalizer.AppDir RenLocalizer-Linux-x64.AppImage
```

### macOS → DMG
The `dist/RenLocalizer/` output is assembled into a `.app` bundle and packaged as a `.dmg`.

```bash
# Create .app bundle from PyInstaller output
chmod +x build/macos/create_app_bundle.sh
./build/macos/create_app_bundle.sh dist/RenLocalizer RenLocalizer.app

# Create DMG
mkdir -p dmg_contents
cp -R RenLocalizer.app dmg_contents/
ln -s /Applications dmg_contents/Applications
hdiutil create -volname "RenLocalizer" -srcfolder dmg_contents -ov -format UDZO RenLocalizer-macOS.dmg
```

> ⚠️ **macOS Gatekeeper Notice:** The .app bundle is not code-signed. On first launch, 
> macOS will block it. To open:
> 1. Right-click (or Ctrl+click) on `RenLocalizer.app`
> 2. Select **"Open"** from the context menu
> 3. Click **"Open"** in the confirmation dialog
> 
> Alternatively, run in Terminal: `xattr -cr /Applications/RenLocalizer.app`

---

## 🤖 GitHub Actions (CI/CD)

This project includes automated workflows for building and releasing on all platforms.

- **File:** `.github/workflows/release.yml`
- **Triggers:** Pushing any tag (e.g., `v2.7.2`)
- **Outputs:**
  - `RenLocalizer-Windows-x64.zip` — Folder-based ZIP
  - `RenLocalizer-Linux-x64.AppImage` — Single-file executable
  - `RenLocalizer-macOS.dmg` — Disk image with drag-and-drop install

---

## 🔧 Troubleshooting Builds

### "No module named 'openai'" or similar
If the executable fails with missing module errors:
1. Ensure the module is listed in `hidden_imports` in `RenLocalizer.spec`.
2. Re-run PyInstaller with `--clean`.

### Anti-Virus False Positives
PyInstaller executables (especially unsigned ones) are often flagged by Windows Defender.
- **Solution:** Sign the executable or add an exclusion folder.

### Assets not loading
Ensure that `locales/` and `icon.ico` are correctly copied to the `dist/RenLocalizer/` folder. The `.spec` file handles this, but verify manually if issues persist.

### Linux AppImage won't run
If you get a FUSE-related error:
```bash
# Install FUSE2 support
sudo apt-get install libfuse2

# Or extract and run without FUSE
./RenLocalizer-Linux-x64.AppImage --appimage-extract-and-run
```

### macOS "App is damaged" error
This happens due to quarantine attributes on downloaded files:
```bash
xattr -cr /Applications/RenLocalizer.app
```