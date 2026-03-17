# 🔬 Deep Extraction — Technical Design Document

> **Target Version:** RenLocalizer v2.7.1  
> **Status:** ✅ Implemented  
> **Authors:** RenLocalizer Core Team  
> **Dependencies:** parser.py, rpyc_reader.py, rpymc_reader.py

---

## 📋 Table of Contents
1. [Executive Summary](#-1-executive-summary)
2. [Current Architecture](#-2-current-architecture)
3. [Gap Analysis](#-3-gap-analysis)
4. [Ren'Py Text-Bearing API Catalog](#-4-renpy-text-bearing-api-catalog)
5. [Deep Extraction Design](#-5-deep-extraction-design)
6. [Implementation Plan](#-6-implementation-plan)
7. [False Positive Prevention Strategy](#-7-false-positive-prevention-strategy)
8. [Test Matrix](#-8-test-matrix)

---

## 🎯 1. Executive Summary

As of RenLocalizer v2.7.1, the tool successfully extracts standard `say` blocks, `_()` wrapped strings, and regex-based patterns from `.rpy` and `.rpyc` files. However, **real-world Ren'Py projects** contain significant localization gaps that standard methods miss:

| Category | Examples | Current Coverage |
|---|---|---|
| Bare `define` strings | `define quest_title = "The Dark Forest"` | ❌ Missed |
| Bare `default` strings | `default player_name = "Adventurer"` | ❌ Missed |
| Complex data structures | `define quests = {"q1": "Kill the dragon"}` | ❌ Missed |
| Python block strings | `init python: tips = ["Press F1"]` | ⚠️ Partial (deep_scan) |
| f-strings (.rpy) | `$ msg = f"Welcome {player}"` | ❌ Not in Parser |
| `renpy.notify()` & APIs | `$ renpy.notify("Save complete")` | ✅ In RPYC / ⚠️ Partial in Parser |
| Screen action strings | `Confirm("Delete save?", ...)` | ✅ In RPYC / ⚠️ Partial in Parser |
| `config.*` assignments | `define config.name = "My Great Game"` | ⚠️ Partial |
| `gui.*` assignments | `define gui.about = _("About this game")` | ⚠️ Partial (via `_()`) |
| `tooltip` property | `tooltip "Click to save"` | ❌ Missed |
| `QuickSave(message=...)` | `QuickSave(message="Saved!")` | ❌ Missed |
| `CopyToClipboard(s)` | `CopyToClipboard("Link copied")` | ❌ Missed |

**Deep Extraction** is designed as a **5th layer** enhancing the existing 4-layer architecture to close these gaps.

---

## 🏗 2. Current Architecture

### 2.1 Parser (`src/core/parser.py`)

```
Layer 1: Regex Pattern Registry
├── dialogue_re, narration_re, menu_re ...
├── general_define_re → define gui/config.var = "text"
├── default_translatable_re → default var = _("text")
├── notify_re, confirm_re, renpy_input_re
└── pattern_registry (ordered prioritization)

Layer 2: Secondary Passes
├── action_call_re → Confirm(), Notify(), Input()
├── show_text_re → show text "..."
├── window_text_re → window show "..."
├── hidden_args_re → (what_prefix="...")
└── triple/double_underscore_re → ___(), __()

Layer 3: Deep Scan (Separate Mode)
├── deep_scan_strings() → Comprehensive string crawling
├── _extract_python_blocks_for_ast() → python: blocks
└── Lookback context, key-value detection

Layer 4: is_meaningful_text() Filters
├── Length, encoding, and technical string validation
├── DATA_KEY_WHITELIST / BLACKLIST
└── Ren'Py internal pattern filtering
```

### 2.2 RPYC Reader (`src/core/rpyc_reader.py`)

```
Binary AST Node Processing
├── FakeDefine → _extract_from_code_obj()
├── FakeDefault → _extract_from_code_obj()
├── FakeUserStatement → Various handlers
└── Say, Menu, NVL nodes

_extract_strings_from_code() — Regex Based
├── _("text"), __("text"), ___("text")
├── renpy.notify(), Character(), renpy.say()
├── Text(), !t flag, nvl, config.name
├── gui.text_*, Smart Key scanner
└── General string capturing

_extract_strings_from_code_ast() — AST Based (DeepStringVisitor)
├── visit_Call: _(), p(), Confirm(), Notify(), MouseTooltip()
│   ui.text(), ui.textbutton(), renpy.input(), renpy.say()
│   achievement.register(), Tooltip()
├── visit_Assign: Context tracking (left-hand key context)
├── visit_Dict: Key context detection
├── visit_List: List element analysis
├── visit_Constant: Filtered string extraction
└── visit_JoinedStr: f-string reconstruction
```

---

## 🔍 3. Gap Analysis

### 3.1 Critical Gaps — Parser (.rpy files)

#### Gap-P1: Bare `define` Strings
```renpy
# CURRENTLY MISSED:
define quest_title = "The Dark Forest"
define npc_greeting = "Hello, traveler!"
define chapter_names = ["Prologue", "Act I", "Finale"]

# CURRENTLY CAUGHT (only gui/config prefix):
define config.name = "My Game"
define gui.about = _("Version 1.0")
```
**Cause:** `general_define_re` only targets `gui.` and `config.` prefixed variables. Developers often define text in custom namespaces.

#### Gap-P2: Bare `default` Strings
```renpy
# CURRENTLY MISSED:
default player_title = "Recruit"
default current_objective = "Explore the cave"
default save_name = "Chapter 1 - Beginning"

# CURRENTLY CAUGHT:
default translated_name = _("Default Name")
```
**Cause:** `default_translatable_re` only catches strings wrapped in `_()`. Many developers skip localization functions for defaults.

#### Gap-P3: Complex Data Structures
```renpy
# CURRENTLY MISSED:
define quest_data = {
    "title": "Dragon Slayer",
    "desc": "Kill the mighty dragon",
}
default inventory_labels = ["Sword", "Shield", "Potion"]
```
**Cause:** Regex-based parsing cannot handle multiline or nested data structures. Context (which key holds text) is often lost in generic deep scans.

#### Gap-P4: f-strings in .rpy
```renpy
# CURRENTLY MISSED:
$ message = f"Welcome back, {player_name}!"
$ status = f"Day {day_count}: {weather_desc}"
```
**Cause:** RPYC reader has `visit_JoinedStr`, but the Parser lacks an equivalent f-string reconstruction logic.

---

## 📚 4. Ren'Py Text-Bearing API Catalog

Compiled list of high-priority translatable calls in Ren'Py 8.x:

### 4.1 Tier-1: Guaranteed Text (High Priority)
| Function / Class | Text Parameter | Coverage |
|---|---|---|
| `renpy.notify(message)` | `message` | ✅ RPYC, ⚠️ Parser regex |
| `renpy.confirm(message)` | `message` | ✅ RPYC, ❌ Parser |
| `renpy.say(who, what)` | `what` | ✅ RPYC, ❌ Parser |
| `Confirm(prompt, yes, no)` | `prompt` | ✅ RPYC, ✅ Parser |
| `Notify(message)` | `message` | ✅ RPYC, ✅ Parser |
| `Tooltip(default)` | `default` | ✅ RPYC, ❌ Parser |
| `Character(name, ...)` | `name` | ✅ RPYC, ✅ Parser |
| `ui.text(text)` | `text` | ✅ RPYC, ❌ Parser |
| `narrator(what)` | `what` | ❌ None (Character proxy) |

### 4.2 Tier-2: Contextual Text (Medium Priority)
| Function / Class | Text Parameter | Note |
|---|---|---|
| `QuickSave(message=...)` | `message` | UI feedback text |
| `CopyToClipboard(s)` | `s` | Might be user-visible text |
| `FilePageNameInputValue` | `pattern, auto, quick` | Page naming templates |
| `config.name` | value | Game title |

### 4.3 Tier-3: Technical (Blacklist)
| Function | Parameters | Reason |
|---|---|---|
| `OpenURL(url)` | URL | Breaks if translated |
| `Jump(label)` | Label name | Code reference |
| `Play(channel, file)`| File path | Assets reference |
| `Preference(name, ...)`| All args | API key / internal state |

---

## 🧠 5. Deep Extraction Design

### 5.1 New Module: `src/core/deep_extraction.py`
This module contains the shared logic for both the Parser and RPYC reader.

```python
class DeepExtractionConfig:
    # Tier-1: Always extract string arguments from these calls
    TIER1_TEXT_CALLS = {
        "renpy.notify":        {"pos": [0]},
        "renpy.confirm":       {"pos": [0]},
        "renpy.say":           {"pos": [1]},
        "Confirm":             {"pos": [0]},
        "Notify":              {"pos": [0]},
        "Tooltip":             {"pos": [0]},
        "Character":           {"pos": [0]},
        "Text":                {"pos": [0]},
        "ui.text":             {"pos": [0]},
        "QuickSave":           {"kw": ["message"]},
        "CopyToClipboard":     {"pos": [0]},
    }
    
    # Variable name heuristics (Hints for bare string extraction)
    TRANSLATABLE_VAR_HINTS = {
        "prefixes": ["title", "name", "label", "desc", "msg", "quest", "hint"],
        "suffixes": ["_title", "_name", "_label", "_desc", "_text", "_msg"],
        "exact": ["who", "what", "save_name", "about", "greeting"],
    }
```

### 5.2 Parser Enhancements (`src/core/parser.py`)
New regex patterns to catch what was missed:
- `bare_define_string_re`: Catches `define my_var = "text"` in any namespace.
- `bare_default_string_re`: Catches `default var = "text"`.
- `fstring_assign_re`: Reconstructs f-strings into bracketed format (e.g., `f"Hi {x}"` → `"Hi [x]"`).
- `tooltip_property_re`: Extracts `tooltip "text"` from screens.

---

## 🚀 6. Implementation Plan

### Phase 1: Infrastructure
- Create `src/core/deep_extraction.py` with `Tier 1/2/3` registries.
- Implement `DeepVariableAnalyzer` for heuristic-based scoring.

### Phase 2: Parser Upgrades
- Integrate `bare_define` and `bare_default` regexes.
- Add `MultiLineStructureParser` for multiline dicts/lists.
- Implement f-string parity logic in the parser.

### Phase 3: RPYC Reader Refinement
- Update `DeepStringVisitor` in `rpyc_reader.py` with expanded Tier-1 handlers.
- Implement Tier-3 blacklist checks to reduce false positives.

---

## 🛡 7. False Positive Prevention

To ensure technical strings aren't accidentally translated, a multi-layered filter is applied:
1. **Existing `is_meaningful_text()`:** Length and encoding check.
2. **Technical Pattern Check:** Filters paths, URLs, and hex colors.
3. **Variable Name Scoring:** Bare strings are only extracted if the variable name scores >0.7 (e.g., `quest_desc` vs `img_path`).
4. **Static Ratio:** f-strings are skipped if they contain <30% static text (too dynamic to translate).

---

> [!IMPORTANT]
> **Deep Extraction** is disabled by default for legacy projects and can be enabled via `config.json` or the Settings tab for maximum coverage.
