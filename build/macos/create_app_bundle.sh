#!/bin/bash
# create_app_bundle.sh — Assembles a macOS .app bundle from PyInstaller onedir output
# Usage: ./create_app_bundle.sh <pyinstaller_dist_dir> <output_app_path>
#
# Example:
#   ./create_app_bundle.sh dist/RenLocalizer RenLocalizer.app

set -euo pipefail

DIST_DIR="${1:?Usage: $0 <dist_dir> <output.app>}"
APP_PATH="${2:?Usage: $0 <dist_dir> <output.app>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Creating macOS .app bundle ==="
echo "  Source: $DIST_DIR"
echo "  Output: $APP_PATH"

# Clean previous output
rm -rf "$APP_PATH"

# Create .app structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$APP_PATH/Contents/Info.plist"

# Inject version from source
DEFAULT_VERSION=$(python3 -c "
import plistlib
from pathlib import Path
plist_path = Path('$SCRIPT_DIR') / 'Info.plist'
with plist_path.open('rb') as f:
    data = plistlib.load(f)
print(data.get('CFBundleShortVersionString', '0.0.0'))
" 2>/dev/null || echo "0.0.0")

VERSION=$(python3 -c "
import sys; sys.path.insert(0, '$PROJECT_ROOT')
from src.version import VERSION; print(VERSION)
" 2>/dev/null || echo "$DEFAULT_VERSION")

# Update version in Info.plist using plistlib so the template version is not hard-coded.
python3 -c "
import plistlib
from pathlib import Path
plist_path = Path('$APP_PATH') / 'Contents' / 'Info.plist'
with plist_path.open('rb') as f:
    data = plistlib.load(f)
data['CFBundleShortVersionString'] = '$VERSION'
data['CFBundleVersion'] = '$VERSION'
with plist_path.open('wb') as f:
    plistlib.dump(data, f, sort_keys=False)
"

echo "  Version: $VERSION"

# Convert icon.ico → icon.icns
# macOS has 'sips' built-in, but it can't read .ico directly.
# Strategy: Extract PNG from .ico first, then build .icns
ICON_SOURCE="$PROJECT_ROOT/icon.ico"
ICONSET_DIR=$(mktemp -d)/icon.iconset

if [ -f "$ICON_SOURCE" ]; then
    mkdir -p "$ICONSET_DIR"
    
    # Try using sips to convert (works if ico has embedded PNG)
    # First extract the largest image from ico using Python (more reliable)
    python3 -c "
from PIL import Image
import sys
try:
    img = Image.open('$ICON_SOURCE')
    # Get the largest size available
    sizes = img.info.get('sizes', [(256, 256)])
    img.save('$ICONSET_DIR/icon_256x256.png', format='PNG')
    # Create required sizes
    for size in [16, 32, 64, 128, 256, 512]:
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(f'$ICONSET_DIR/icon_{size}x{size}.png', format='PNG')
        if size <= 256:
            resized2x = img.resize((size*2, size*2), Image.LANCZOS)
            resized2x.save(f'$ICONSET_DIR/icon_{size}x{size}@2x.png', format='PNG')
    print('Icon conversion successful')
except Exception as e:
    print(f'Warning: Icon conversion failed: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1 || echo "  Warning: PIL icon conversion failed, trying fallback..."

    # Use iconutil to create .icns from iconset
    if ls "$ICONSET_DIR"/*.png 1>/dev/null 2>&1; then
        iconutil -c icns "$ICONSET_DIR" -o "$APP_PATH/Contents/Resources/icon.icns" 2>/dev/null || {
            echo "  Warning: iconutil failed, bundle will use the default app icon"
            rm -f "$APP_PATH/Contents/Resources/icon.icns"
        }
    fi
    
    # Cleanup
    rm -rf "$(dirname "$ICONSET_DIR")"
    echo "  Icon: converted"
else
    echo "  Warning: icon.ico not found, skipping icon"
fi

# Copy the entire PyInstaller onedir output into Resources
cp -R "$DIST_DIR" "$APP_PATH/Contents/Resources/app"
echo "  App files: copied"

# Create the launch script (referenced by CFBundleExecutable in Info.plist)
cat > "$APP_PATH/Contents/MacOS/launch" << 'LAUNCHER'
#!/bin/bash
# macOS .app launcher for RenLocalizer
# Determines the correct path and launches the PyInstaller binary

DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES="$DIR/../Resources/app"

# Set working directory to Resources so relative paths work
cd "$RESOURCES"

# Keep the Cocoa layer-backed window path enabled unless the user or CI
# already provided a more specific override.
export QT_MAC_WANTS_LAYER="${QT_MAC_WANTS_LAYER:-1}"

# Launch the actual binary
exec "$RESOURCES/RenLocalizer" "$@"
LAUNCHER

chmod +x "$APP_PATH/Contents/MacOS/launch"
echo "  Launcher: created"

# Make the main binary executable (should already be, but ensure)
chmod +x "$APP_PATH/Contents/Resources/app/RenLocalizer" 2>/dev/null || true
chmod +x "$APP_PATH/Contents/Resources/app/RenLocalizerCLI" 2>/dev/null || true

echo "=== .app bundle created successfully ==="
echo "  Path: $APP_PATH"
