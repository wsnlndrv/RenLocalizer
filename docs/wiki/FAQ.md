# 📖 RenLocalizer Comprehensive Guide & FAQ

This document is your primary resource for understanding settings, optimizing performance, and troubleshooting errors.

---

## ⚡ 1. Speed & Performance

### Why are some lines untranslated? ("Aggressive Translation")
By default, **"Aggressive Translation"** mode is **disabled** for maximum speed.
*   **What it does when enabled:** If the primary engine (e.g., Google) fails to translate a line (returning the exact same English text), the program automatically:
    1.  Retries using a **different Google Server** (e.g., switches from `.com` to `.co.uk`).
    2.  If that still fails, it uses **Lingva Translate** as a final backup.
*   **The Trade-off:** This multi-step process significantly improves translation coverage (near 100%) but increases the time per line.
*   **When to Enable:** If you see untranslated lines after the first pass, enable "Aggressive Translation" in **Settings > Advanced** and run the translation again.

### How to speed up AI Translation?
*   **Batch Size:** Increase "AI Batch Size" in settings (Default is 50). Values up to 100 are often safe for GPT-4o.
*   **Model Choice:** Use faster models like `gpt-4o-mini`, `gemini-1.5-flash`, or a quantified Local LLM (7B parameters).

---

## ⚙️ 2. Translation Settings Explained ("Translate What?")

These settings control *which* parts of the game are modified.

### A. Core Content (Safe)
*   **Translate Dialogue:** The main story text (`say` statements).
    *   *Recommendation:* Always **ON**.
*   **Translate Menus:** The choices players make.
    *   *Recommendation:* Always **ON**.

### B. Interface & UI (Moderate Risk)
*   **Translate UI:** Standard Ren'Py interface text defined in `screens.rpy` (Save, Load, Preferences).
*   **Translate Buttons:** Texts inside manual `textbutton` elements.
*   **Translate Tooltips:** Popup text when hovering over elements (Accessibility/Alt-text).
    *   *Note:* Turn these **OFF** if you want to keep the game's interface in English while translating only the story.

### C. Technical & Advanced (High Risk)
*   **Translate Notifications:** Popup messages like `"Game Saved"`.
*   **Translate Input Values:** Default text in input boxes (e.g., `"Enter Name"`).
*   **Translate String Definitions:** Variables defined with `define`.
    *   *⚠️ Risk:* Some games use these strings for logic checks. Translating them carries a risk of breaking game logic. Enable only if you want a 100% full translation.

### D. Special Features
*   **Exclude System Folders:** Automatically skips unnecessary folders like `renpy/`, `lib/`, `cache/` to speed up scanning.
*   **Scan .rpym Files:** Scans Ren'Py Module files. Usually contains library code. Keep OFF unless needed.

---

## 🛑 3. Installation & Startup Issues

### "Windows protected your PC" (SmartScreen)
*   **Cause:** We are open-source and don't have a paid digital signature.
*   **Solution:** Click **"More Info"** -> **"Run Anyway"**.

### Antivirus / False Positives
*   **Cause:** Antiviruses often flag unverified Python programs as generic risks.
*   **Solution:** Add the RenLocalizer folder to your Antivirus **Exclusions** list.

### "Missing MSVCP140.dll"
*   **Solution:** Install the **Visual C++ Redistributable** package from Microsoft.

---

## 🎮 4. In-Game Issues & Missing Text

### "Some parts (Menus, Quests) are still in English."
Even after a full translation, some parts might remain in English.
*   **Feature:** RenLocalizer can install a **Force Runtime Translation** script (`zzz_renlocalizer_runtime.rpy`) to catch these while you play. Enable it via **Tools > Runtime Hook Generator** or in Settings.
*   **If still English:**
    *   **Image Text:** The menus might be PNG/JPG images (Photoshop), which cannot be translated by text tools.
    *   **Hardcoded Code:** The text is embedded deeply in Python code blocks which are skipped for safety.

### "I see squares (□□□) instead of text."
*   **Cause:** The game's font doesn't support characters like `Ş, Ç, Ğ, Ü` or Cyrillic/Chinese.
*   **Solution:** Use **Tools > Font Injection**. You can:
    *   **Auto-Inject:** Let RenLocalizer automatically download a compatible font for your target language.
    *   **Manual Select:** Choose from **80+ curated Google Fonts** (Sans, Serif, Display, Handwriting, Monospace) to match the game's style.

### "My Save Game is broken / Crashes on load."
*   **Cause:** Ren'Py save files are sensitive to script changes.
*   **Solution:** **START A NEW GAME.** Loading an old English save on a translated game will often crash.

### "Text is overflowing."
*   **Cause:** Translated text is often longer (e.g., German/Russian) than English.
*   **Solution:** This requires manually editing the game's font size in `screens.rpy`. There is no automatic fix yet.

---

## 🛠️ 5. Errors & Crashes

### "No translatable texts found" Error
*   **Cause:** The game folder only has compiled `.rpyc` files, no `.rpy` source files.
*   **Solution:** Enable **RPYC Reader** in Settings. This allows the tool to read binary files directly.

### Game Crashes on Startup (Traceback)
*   **Cause:** The AI might have broken a syntax tag (e.g., `[score]` -> `[puan]`).
*   **Fix:** Check the `traceback.txt` file in the game folder to find the bad line, or delete the `game/tl` folder to reset.

### "Already exists" / Duplicate Errors
*   **Solution:** Delete the `game/tl` folder before starting a fresh translation.

---

## 🤖 6. AI & Local LLM Troubleshooting

### Connection Failing (Local LLM)
*   **Checklist:**
    1.  Is **Ollama** or **LM Studio** running?
    2.  Is the **Model Name** in settings exact? (e.g., `llama3` vs `llama3:latest`).
    3.  **Timeout:** Increase "Timeout" to `120s` in settings.

### Safety / Censorship Errors
*   **Issue:** Gemini/GPT refuses to translate content.
*   **Solution:**
    *   **Gemini:** Set Safety Settings to `BLOCK_NONE` in the app.
    *   **Local/OpenRouter:** Use an "Uncensored" model (e.g., `dolphin-mistral`, `lzlv`).

---

## 🛡️ 7. Placeholder & Syntax Protection

### "My translated text has broken [variables]."
*   **Cause:** AI or Google Translate sometimes corrupts Ren'Py syntax like `[name]`, `{b}`, or `%(score)s`.
*   **Solution:** RenLocalizer v2.6.4+ includes **Advanced Syntax Guard** with:
    *   **XML Tag Protection:** Placeholders are wrapped in `<ph id="0">` tags for AI engines.
    *   **Fuzzy Recovery:** Automatically repairs common corruptions like `X R P Y X` → `XRPYX`.
    *   **Bracket Healing:** Fixes `[ var ]` → `[var]` and `[list [ 0 ] ]` → `[list[0]]`.
*   **If still broken:** Report the specific line in a GitHub issue.

---

## 🌍 8. Language & First Run Issues

### "The game still opens in English after translation."
*   **Cause:** Ren'Py defaults to the game's original language on first run.
*   **Solution:** Press **Shift+L** in-game to open the language selector, then choose your translated language (e.g., "Turkish").
*   **Permanent Fix:** Enable **"Auto Hook Gen"** in Settings. This creates a script that sets your language as default on game start.

### "I translated to Turkish but the folder is named 'english'."
*   **Cause:** RenLocalizer auto-detects the target language from the `tl/` folder name.
*   **Solution:** Rename the folder to your target language code (e.g., `tl/turkish` or `tl/tr`), then retranslate.

---

## 📦 9. RPYC & Compiled Games

### "No texts found" but RPYC Reader is ON.
*   **Possible Causes:**
    1.  **Game never run:** Ren'Py creates `.rpyc` files on first launch. Run the game once (just to main menu).
    2.  **Encrypted game:** Some games use custom encryption. Check if `.rpa` files exist and try **Tools > Extract RPA** first.
    3.  **Very old Ren'Py:** Games from 2015 or earlier may use incompatible formats.

### ".rpyc but no .rpy files?"
*   **Explanation:** The developer only shipped compiled files.
*   **Solution:** Enable **RPYC Reader** in Settings. RenLocalizer can read compiled files directly without decompilation.

---

## 💾 10. Cache & Translation Memory

### "Why is the same text not re-translated?"
*   **Feature:** RenLocalizer caches all translations in `translation_cache.json` to save API calls and speed up re-runs.
*   **To Force Fresh Translation:**
    1.  Go to **Cache (TM)** page in the app.
    2.  Click **"Clear All"** to reset the cache.
    3.  Re-run translation.

### "How do I edit a cached translation?"
*   Navigate to **Cache (TM)** page, search for the text, and click **Edit**.

---

## 📖 11. Glossary Tips

### "Character names keep getting translated!"
*   **Solution:** Add names to the **Glossary** with the same source and target:
    | Source | Target |
    |--------|--------|
    | Alice  | Alice  |
    | Bob    | Bob    |
*   These terms will be preserved during translation.

### "How to ensure consistent terminology?"
*   Use **Glossary > Auto-Extract** to find repeated terms in your game.
*   Add translations for game-specific words (e.g., "Mana Points" → "Ruh Puanı").

---

## � 12. Workflow & Best Practices

### Recommended Translation Workflow
1.  **First Pass:** Run with default settings (Aggressive OFF) for speed.
2.  **Review:** Check logs for untranslated count.
3.  **Second Pass:** If many untranslated, enable **Aggressive Translation** and re-run.
4.  **Polish:** Use **Glossary** to fix repeated terminology issues.
5.  **Test:** Play the game and check for broken text or missing translations.

### "Should I delete tl/ folder before re-translating?"
*   **If updating:** No, RenLocalizer will skip already-translated lines (using cache).
*   **If starting fresh:** Yes, delete `game/tl/` to get a clean slate.

### "Can I translate only specific files?"
*   Currently, RenLocalizer translates the entire project.
*   **Workaround:** Use **TL Translate** tool to translate existing `tl/` folders selectively.

---
## 🧠 13. External Translation Memory (TM)

### "How can I reuse translations from another game?"
*   **Feature:** RenLocalizer v2.7.3 introduced **External Translation Memory**. You can import translations from any previously translated Ren'Py game's `tl/<language>/` folder.
*   **How:**
    1.  Go to **Tools** page → Click **"Import from tl/ folder"**.
    2.  Select the `tl/<language>/` folder of the translated game.
    3.  Enable TM in **Settings** and select sources on the **Home** page.
*   **Result:** Common strings are matched instantly without any API call.

### "Why is my TM hit rate low?"
*   TM uses **exact match** only — even small differences (capitalization, punctuation) will miss.
*   **Solution:** Import TM from multiple games, especially ones using the default Ren'Py UI (Start, Save, Load, Preferences, etc.).

### "Can I use TM with AI engines (GPT, Gemini)?"
*   **Yes!** TM works with all engines. Matched strings skip the API entirely, saving tokens and costs.

### "How do I delete or manage TM sources?"
*   Go to **Tools** page → The TM card shows all imported sources with entry counts. You can remove individual TM files from the `tm/` folder if needed.

> 📖 See [[External-Translation-Memory]] for the complete guide.

---> �🚩 **Still Stuck?** [Open an issue on GitHub](https://github.com/Lord0fTurk/RenLocalizer/issues) and attach your `error_output.txt`.

