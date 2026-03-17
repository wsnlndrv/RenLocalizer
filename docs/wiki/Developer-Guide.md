# 🛠️ Developer & Contributor Guide

This guide is for developers looking to modify RenLocalizer, add new features, or contribute to the core engine.

---

## 🏗️ Technical Architecture (v2.7.4)

The project follows a **Layered Hybrid Architecture** combining a high-performance Python backend with a fluid QML (Qt Quick) frontend.

### 📂 Core Engine (`src/core/`)
*   **`translation_pipeline.py`**: The 7-stage orchestrator (QObject) that manages the lifecycle of a translation project.
*   **`parser.py`**: A massive (~3.7k lines) regex-based scanner for `.rpy` files.
*   **`syntax_guard.py`**: The "Syntax Guard v4.0" system. Handles Unicode tokenization (`⟦RLPH_0⟧`) and recovery logic.
*   **`deep_extraction.py`**: Tier-based extraction logic for complex variables and data structures.
*   **`translator.py`**: Base classes and implementations for Google, DeepL, and LibreTranslate.
*   **`ai_translator.py`**: Integrations for OpenAI, Gemini, Claude, and Local LLMs (Ollama/LM Studio).
*   **`rpyc_reader.py`**: AST-based unpickling engine for compiled Ren'Py scripts.

### 📂 Backend Bridge (`src/backend/`)
*   **`app_backend.py`**: The primary QObject bridge. Handles signals/slots between QML and the Translation Pipeline.
*   **`settings_backend.py`**: Manages the persistence and sanitization of `config.json`.

### 📂 UI Layer (`src/gui/qml/`)
*   **`main.qml`**: Root window with Material 3 styling and dynamic theming.
*   **`pages/`**: Individual QML files for Home, Settings, Tools, etc.

---

## 🧪 Development Workflow

### 1. Setting Up the Environment
```bash
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
python run.py  # Launches the GUI
```

### 2. Testing Suite
We use a comprehensive test suite (520+ tests). Always run these before a PR:
*   **Full Test Suite:** `python -m unittest discover tests/`
*   **Parser Specific:** `python -m unittest tests/test_parser.py`
*   **Syntax Guard:** `python -m unittest tests/test_syntax_guard.py`

---

## ➕ Extending the Engine

### Adding a New Translation Engine
1.  Define a new `TranslationEngine` enum in `src/core/translator.py`.
2.  Inherit from `BaseTranslator` and implement `translate_batch`.
3.  Register the new class in `src/core/translation_pipeline.py`'s `_setup_translator` method.
4.  Add the UI controls in `SettingsPage.qml` and `settings_backend.py`.

### Adding a New False Positive Filter
1.  Navigate to `src/core/output_formatter.py`.
2.  Add a pre-compiled regex to the `TECHNICAL_PATTERNS` dictionary.
3.  Update `_should_skip_translation()` logic if needed.

---

## 📦 Build & Distribution

*   **Windows:** `pyinstaller RenLocalizer.spec`
*   **Linux (AppImage):** Run the scripts in `build/linux/`.
*   **MacOS (DMG):** Run the scripts in `build/macos/`.

The `.spec` file is the source of truth for assets, library hooks, and versioning.

---

## 📜 Coding Standards
- **Language:** UI/Logic developer comments can be in Turkish, but all code (variables, functions, classes) and commit messages MUST be in **English**.
- **Type Hints:** Required for all new function signatures.
- **Atomic Edits:** Prefer additive changes over complete refactors to maintain stability.
- **Safety First:** Never store API keys or tokens in the codebase—use `config.json` (git-ignored) or environment variables.

---
> 🔗 **Related Resources:**
> * [[Deep-Extraction-Design]] — Technical breakdown of the extraction system.
> * [GitHub Issues](https://github.com/Lord0fTurk/RenLocalizer/issues) — Track bugs and feature requests.
