import os
import sys
import platform
from pathlib import Path

def get_app_dir() -> Path:
    """Returns the physical directory of the executable or script."""
    if getattr(sys, 'frozen', False):
        if hasattr(sys, '_MEIPASS'):
            # Running as compiled PyInstaller executable
            return Path(sys.executable).parent.resolve()
    # Running as development script (run.py is 3 levels up from this file)
    return Path(__file__).resolve().parent.parent.parent

def is_appimage() -> bool:
    """Check if the application is running packaged as a Linux AppImage."""
    return 'APP_IMAGE' in os.environ or 'APPIMAGE' in os.environ

def get_system_data_dir() -> Path:
    """Determine the OS-specific standard application data directory."""
    system = platform.system()
    app_name = "RenLocalizer"
    
    if system == "Windows":
        base = os.environ.get("APPDATA")
        if not base:
             base = os.path.expanduser("~")
        return Path(base) / app_name
    elif system == "Darwin":
        return Path(os.path.expanduser(f"~/Library/Application Support/{app_name}"))
    else:
        # Linux and others (XDG Base Directory Specification)
        base = os.environ.get("XDG_DATA_HOME")
        if not base:
            base = os.path.expanduser("~/.local/share")
        return Path(base) / app_name

def get_data_path() -> Path:
    """
    Determine the active data path (Portable vs System mode).
    Returns the absolute Path where config, cache, logs, and glossary should be saved.
    """
    app_dir = get_app_dir()
    
    # 1. Force System Mode for AppImages (AppImage mounts are read-only)
    if is_appimage():
        return get_system_data_dir()
        
    # 2. Check for explicit portable marker
    if (app_dir / ".portable").exists():
        return app_dir
        
    # 3. Legacy Fallback: If config.json already exists in app_dir, 
    # and app_dir is writable, assume portable legacy mode to prevent data loss.
    if (app_dir / "config.json").exists() and os.access(app_dir, os.W_OK):
        return app_dir
        
    # 4. Default to System Data Directory for clean/first-time installations
    return get_system_data_dir()

def ensure_data_directories(data_path: Path):
    """Ensure essential data directories exist within the data path."""
    data_path.mkdir(parents=True, exist_ok=True)
    (data_path / "logs").mkdir(exist_ok=True)
    (data_path / "tm").mkdir(exist_ok=True)
