# 🖥️ Command Line Interface (CLI) Usage

The RenLocalizer CLI is designed for automation, remote server usage, or advanced batch processing.

---

## 🚀 Basic Usage
Launch the CLI with the module syntax:
```bash
python -m src.cli_main translate -i
```
This opens the **Interactive Mode** wizard.

---

## 🛠️ Direct Commands (Automation)
For automation, pass arguments directly. 

### **Example: Translate Project to Spanish**
```bash
python -m src.cli_main translate "/path/to/game" --target-lang es --engine google --mode auto
```

### 📋 Argument Reference

| Argument | Description |
| :--- | :--- |
| `--target-lang` | Code of the target language (e.g., `tr`, `es`, `ru`). |
| `--engine` | `google`, `deepl`, `openai`, `gemini`, `local_llm`, `pseudo`. |
| `--mode` | `auto` (Detect), `full` (Extract + Translate), `translate` (Only translate). |
| `--deep-scan` | Enable AST-based deep scanning. |
| `--verbose` | Show detailed logging output. |

---

## 🔧 Additional CLI Commands (v2.6.4+)

| Command | Description |
| :--- | :--- |
| `health-check <path>` | Run static analysis on a project directory. |
| `font-check <path> --lang tr` | Check font compatibility for a target language. |
| `pseudo <path>` | Generate pseudo-localized text for UI overflow testing. |
| `fuzzy <old_tl> <new_tl>` | Smart update: Recover translations using fuzzy matching. |
| `extract-glossary <path>` | Extract potential glossary terms from project files. |

### Example: Health Check
```bash
python -m src.cli_main health-check "C:\Games\MyRenPyGame"
```

---

## 🌟 Modes Explained

*   **Auto Mode (`--mode auto`):** Recommended. Detects whether RPA extraction is needed.
*   **Full Mode (`--mode full`):** For packaged games. Extracts RPA archives, normalizes encodings, and translates.
*   **Translate Mode (`--mode translate`):** For already unpacked projects or existing `tl/` folders.

---

## 🤖 Server & Headless Usage
The CLI version is lightweight and doesn't require a GUI. You can run it on a Linux VPS or in a **GitHub Action**:

```bash
# Example script for a cloud server
python -m src.cli_main translate "./GameProject" \
  --target-lang tr \
  --engine gemini \
  --mode auto \
  --deep-scan \
  --verbose
```

---

## 📋 Logs & Troubleshooting
In case of failure, the CLI writes a detailed diagnostic report to **`error_output.txt`** in the project root. Check this file to see which file or line caused the issue.

