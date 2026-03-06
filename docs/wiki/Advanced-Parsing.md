# 🔍 Advanced Parsing & Text Extraction

RenLocalizer uses a sophisticated multi-stage pipeline to extract text without breaking the underlying game logic or engine syntax.

---

## 🔹 1. Traditional Regex Parsing
The first layer of scanning uses highly optimized Regular Expressions to find standard Ren'Py dialogue and UI strings:
*   **Dialogue:** `character_name "Dialogue text"`
*   **Direct strings:** `_("Text")` or `"Text"`
*   **Menu items:** `menu:` choice blocks.

## 🔹 2. AST (Abstract Syntax Tree) Scanning
When simple patterns aren't enough, RenLocalizer analyzes the script's structure using Python's `ast` module.
*   **Capabilities:**
    *   Finds strings inside nested functions.
    *   Extracts text from `init python` blocks.
    *   Distinguishes between technical code and translatable content.

## 🔹 3. RPYC & RPYMC Readers
Many "obfuscated" games hide their source code by deleting `.rpy` files.
*   **RPYC Reader:** "Unpickles" binary RPYC files to extract the original logic. You can translate a game even if the source code is missing!
*   **RPYMC Reader:** Handles screen cache files, ensuring complex UI elements are localized.

## 🔹 4. Deep Scan Technology
Enable **Deep Scan** in settings to trigger a recursive analysis of the entire project.
*   **What it finds:** Variable assignments and list items used as game text that don't follow standard `_()` markers.
*   **Safety:** Uses a "Technical String Filter" to skip engine internals like `renpy.dissolve`.

---

## 🔹 4b. Deep Extraction Engine *(v2.7.1)*
An advanced extension of Deep Scan that captures previously invisible text:

### Tier Classification
| Tier | Purpose | Examples |
|------|---------|----------|
| **Tier-1** (16 calls) | Always-text API calls | `renpy.notify`, `renpy.confirm`, `Character`, `Text`, `ui.text` |
| **Tier-2** (4 calls) | Contextual UI calls | `QuickSave`, `CopyToClipboard`, `FilePageNameInputValue`, `Help` |
| **Tier-3** (30+ calls) | **Blacklist** — never extract | `Jump`, `Call`, `Show`, `Hide`, `Play`, `SetVariable` |

### Variable Name Heuristics
**DeepVariableAnalyzer** scores variable names 0.0–1.0 to decide extraction:
*   ✅ `quest_title` → translatable (suffix `_title`)
*   ✅ `config.name` → translatable (exact match)
*   ❌ `persistent.flags` → non-translatable (namespace `persistent`)
*   ❌ `audio_volume` → non-translatable (prefix `audio_`)

### New Extraction Targets
*   **Bare define/default:** `define quest_title = "text"` without `_()` wrapper
*   **f-string templates:** `f"Welcome back, {player}!"` → `"Welcome back, [player]!"`
*   **Multi-line structures:** Dict/list with `title`, `desc`, `name` keys
*   **Tooltip properties:** `tooltip "hint text"` in screen language
*   **Extended API calls:** `QuickSave(message=...)`, `CopyToClipboard(...)`, `narrator(...)`, `renpy.display_notify(...)`

### False Positive Prevention
15 compiled regex patterns filter technical strings: file paths, hex colors, URLs, snake_case identifiers, CONSTANT_NAMES, etc.

### Config Toggles
Seven granular settings in `config.json` for full control over what gets extracted.

> 📖 See [Deep Extraction Design](Deep-Extraction-Design) for architecture details.

---

## 🔹 5. Text Types Filter
Categorize and select exactly what you want to translate in **Settings > Text Types**:

*   📌 **Core:** Dialogue, Menus, Buttons.
*   📌 **Interface:** UI text, Input fields, Alt text.
*   📌 **System:** Notifications, Confirmation dialogs.
*   📌 **Config:** Game title, Version strings.

---

## 🔹 6. Normalization & Encoding
RenLocalizer automatically detects file encodings and normalizes them to **UTF-8 with BOM**. 
> 🛡️ **Benefit:** Prevents "Mojibake" (broken characters) in languages like Russian, Chinese, or Japanese.

---

## 🔹 7. ID Stability (v3 Engine)
Introduced in v2.6.0, this technology ensures that translations remain linked to the correct code block even if the script files are modified.
*   **Deterministic Hashing:** Instead of relying on line numbers (which change when you add/remove code), it generates unique IDs based on Ren'Py's internal `Label ID` mapping and the original text content.
*   **Advantage:** Perfect for "External AI Translation" (Export/Import) workflow. You can keep developing your game while someone else translates the JSON files.

---

## 🔹 8. Force Runtime Translation (Hook)
Sometime Ren'Py source code contains dynamic strings that are not wrapped in `_()` or `!t` flags. These strings often appear untranslated in games even after processing.

*   **How it Works:** 
    *   RenLocalizer injects a small script (`zzz_renlocalizer_runtime.rpy`) into the game folder.
    *   This script uses a **Dual-Hook Strategy:**
        1.  `config.say_menu_text_filter` — Catches text *before* variable substitution.
        2.  `config.replace_text` — Catches text *after* rendering.
    *   Every time a string is displayed, it checks if a translation exists in the current language files.
*   **When to Use:** Use this if you see quest descriptions, item names, or dynamic UI elements that remain untranslated.
*   **How to Enable:** **Tools > Runtime Hook Generator** or enable "Auto Hook Gen" in Settings.

---

## 🔹 9. Syntax Guard v3.1 (Hybrid Strategy)
RenLocalizer employs a military-grade syntax protection system to prevent AI translators (Google, DeepL, LLMs) from breaking your game code.

### 🛡️ Three Layers of Defense
1.  **Wrapper Tag Removal:** Outer tags like `{i}...{/i}` are surgically removed *before* translation and re-attached *after*. This prevents the AI from translating `i` to `Ben` or moving the tags to the wrong place.
2.  **Placeholder Masking:** Internal tags and variables are converted to unbreakable tokems:
    *   `[variable]` → `XRPYXVAR0XRPYX`
    *   `save slot %s` → `save slot XRPYXFMT1XRPYX` (New in v2.6.4!)
    *   This ensures Google sees "XRPYX..." (a made-up word) instead of code, preventing hallucinations.
3.  **Bracket Healing (Cerrah):** A final post-processing step that fixes specific corruptions caused by Neural Machine Translation quirks:
    *   `[ [text]` → `[[text]` (Fixes detailed parsing of double brackets)
    *   `[ var ]` → `[var]` (Removes illegal spaces)
    *   `[list [ 1 ] ]` → `[list[1]]` (Repairs nested variable access)

> **Why "Hybrid"?** It combines the safety of removing tags (Layer 1) with the precision of masking (Layer 2) and the robustness of regex repair (Layer 3).

