# 🔍 Advanced Parsing & Text Extraction

RenLocalizer uses a sophisticated multi-stage pipeline to extract text without breaking the underlying game logic or engine syntax.

---

## 🔹 1. Traditional Regex Parsing (Layer 1)
The first layer of scanning uses highly optimized Regular Expressions to find standard Ren'Py dialogue and UI strings:
*   **Dialogue:** `character_name "Dialogue text"`
*   **Narration:** `"Indented dialogue without a name"`
*   **Menu items:** `menu:` choice blocks and captions.

## 🔹 2. AST (Abstract Syntax Tree) Scanning (Layer 2)
When simple patterns aren't enough (like in `init python` blocks), RenLocalizer analyzes the script's structure using Python's `ast` module.
*   **Capabilities:**
    *   Finds strings inside nested functions (`renpy.say`, `renpy.notify`).
    *   Extracts text from complex variable assignments.
    *   Distinguishes between technical code and translatable content using context.

## 🔹 3. RPYC & RPYMC Readers (The Binary Bridge)
Many games hide their source code by deleting `.rpy` files.
*   **RPYC Reader:** "Unpickles" binary RPYC files to extract the original logic trees. You can translate a game even if the source code (`.rpy`) is missing!
*   **RPYMC Reader:** Handles screen cache files, ensuring complex UI elements in screens are localized.

## 🔹 4. Deep Extraction Engine (v2.7.4 Standard)
An advanced extension that captures previously "invisible" text stored in variables or complex data structures.

### Tier Classification (Deep Extraction Logic)
| Tier | Purpose | Examples |
|------|---------|----------|
| **Tier-1** | Always-text API calls | `renpy.notify`, `Character("Name")`, `Text("...")` |
| **Tier-2** | Contextual UI calls | `QuickSave(message="...")`, `CopyToClipboard("...")` |
| **Tier-3** | **Blacklist** (Safe-skip) | `Jump`, `Play`, `SetVariable`, `OpenURL` |

### Variable Name Heuristics
**DeepVariableAnalyzer** scores variable names to decide if they contain text:
*   ✅ `quest_title`, `chapter_name`, `npc_msg` (Likely text)
*   ❌ `img_path`, `audio_vol`, `persistent.flags` (Technical/System)

### New Extraction Targets
*   **Bare define/default:** `define quest_title = "text"` (without requiring `_()`).
*   **f-string templates:** `f"Welcome back, {player}!"` becomes `"Welcome back, [player]!"`.
*   **Tooltip properties:** Extracts `tooltip "hint text"` directly from screen code.

---

## 🔹 5. Smart Data Path (v2.7.4)
RenLocalizer now manages data paths intelligently:
*   **Portable Mode:** Keeps all translations (`cache/`), settings (`config.json`), and logs in the application folder.
*   **Migration:** Automatically moves your old data to the new structure if you switch modes.

---

## 🔹 6. Syntax Guard (v4.0 Standard)
Our "Civilian-to-Military" grade protection system ensures AI translators (Google, OpenAI, Gemini) don't break your code.

### 🛡️ Core Protection Layers
1.  **Unicode Tokenization:** Replaces `[var]` with unbreakable tokens like `⟦RLPH_0⟧`. Google Translate cannot translate or corrupt these unique Unicode brackets.
2.  **HTML Mode:** For Cloud APIs (DeepL/Gemini), it uses valid HTML tags to hide code.
3.  **Spaced Token Recovery:** If an engine returns `⟦ RLPH _ 0 ⟧` (adding spaces), RenLocalizer automatically heals and restores the original code.

---

## 🔹 7. Force Runtime Translation (Hook)
Injected via `zzz_renlocalizer_runtime.rpy`, this script catches dynamic strings *as they are displayed* in the game, ensuring a 100% translation even for hard-coded Python text.

---

> [!TIP]
> Always enable **RPYC Reader** if you don't see any `.rpy` files in the game folder. It's the most powerful way to unlock a project.

---
> 🔗 **Related Pages:**
> * [[Deep-Extraction-Design]] — Detailed technical design.
> * [[Technical-Filtering]] — How strings are validated.
