# 📖 RenLocalizer Comprehensive Guide & FAQ

This document is your primary resource for understanding settings, optimizing performance, and troubleshooting issues in RenLocalizer.

---

## ⚡ 1. Speed & Performance

### Why are some lines untranslated? ("Aggressive Translation")
By default, **"Aggressive Translation"** mode is **disabled** for maximum speed.
*   **What it does when enabled:** If the primary engine fails to translate a line (returning the exact same text), the program automatically:
    1.  Retries using a **different server mirror** (e.g., switches between Google Mirrors).
    2.  If that still fails, it uses **Lingva Translate** or another fallback engine.
*   **When to Enable:** If you see untranslated lines after the first pass, enable "Aggressive Translation" in **Settings > Advanced** and run the translation again.

### How to speed up AI Translation?
*   **Batch Size:** Increase "AI Batch Size" in settings (Default is 50). Values up to 100 are often safe for GPT-4o.
*   **Model Choice:** Use faster models like `gpt-4o-mini`, `gemini-1.5-flash`, or a quantified Local LLM (7B parameters).
*   **Parallel Processing:** Ensure "Max Threads" is set appropriately for your CPU/Network.

---

## ⚙️ 2. Translation Settings Explained ("Translate What?")

These settings control *which* parts of the game are modified.

### A. Core Content (Safe)
*   **Translate Dialogue:** The main story text (`say` statements).
*   **Translate Menus:** The choice buttons in the game.
*   **Deep Extraction (v2.7+):** Extracts hidden text from variables, complex dicts, and f-strings. See [[Deep-Extraction-Design]].

### B. Interface & UI (Moderate Risk)
*   **Translate UI (strings.json):** Standard Ren'Py interface text (Save, Load, Preferences).
*   **Translate Buttons:** Texts inside manual `textbutton` elements.
*   **Translate Tooltips:** Popup text when hovering over elements.

### C. Technical & Advanced (High Risk)
*   **Extract Deep String Definitions:** Captures text assigned to variables (`define var = "text"`). 
    *   *⚠️ Risk:* Some games use these for logic checks. Avoid if the game crashes after translation.
*   **Atomic Segments (Angle-Pipe):** Handles strings like `<Option A|Option B>`.

---

## 🛑 3. Installation & Startup Issues

### "Windows protected your PC" (SmartScreen)
*   **Cause:** We are open-source and don't carry a paid digital signature.
*   **Solution:** Click **"More Info"** -> **"Run Anyway"**.

### Antivirus / False Positives
*   **Cause:** Security software often flags unverified Python binaries.
*   **Solution:** Add the RenLocalizer folder to your Antivirus **Exclusions** list.

### "Missing MSVCP140.dll"
*   **Solution:** Install the **Visual C++ Redistributable** package from Microsoft.

---

## 🎮 4. In-Game Issues & Missing Text

### "Some parts are still in English."
*   **Solution 1:** Enable the **Runtime Hook** in Settings. This injects a filter into Ren'Py to translate dynamic text at runtime.
*   **Solution 2:** The text might be an **Image** (PNG/JPG). Use an OCR/Image translator for those as RenLocalizer only handles text files.

### "I see squares (□□□) instead of text."
*   **Cause:** The game's font doesn't support your language's characters.
*   **Solution:** Use **Tools > Font Injection**. Choose a Google Font (like `Inter` or `Roboto`) and let RenLocalizer inject it into the game.

### "My Save Game is broken / Crashes on load."
*   **Rule:** **START A NEW GAME.** Loading an old English save after translating scripts often causes Ren'Py to crash due to ID mismatches.

### "Smart Data Path" (v2.7.4)
*   If your translation data or settings aren't saving, check the **Smart Data Path** in Settings. You can enable **Portable Mode** to keep data within the app folder.

---

## 🤖 5. AI & Local LLM Troubleshooting

### Connection Failing (Local LLM)
1. Is **Ollama** or **LM Studio** running with an OpenAI-compatible server?
2. Is the **Model Name** exact? (e.g., `llama3.1:8b`).
3. **Internal IP:** Use `http://127.0.0.1:11434/v1` for Ollama.

### Safety / Censorship Errors
*   **Gemini:** Set Safety Settings to `BLOCK_NONE` in RenLocalizer settings.
*   **OpenAI/Claude:** Use "NSW Fallback" or an uncensored model for adult titles.

---

## 🛡️ 6. Placeholder & Syntax Protection

### "The AI broke my [variables]!"
*   **v2.7 Solution:** RenLocalizer uses `⟦RLPH_0⟧` tokens for maximum safety.
*   If you are using **Web Google Translate**, ensure **"Use HTML Mode"** is **OFF**.
*   If you are using **Cloud APIs (Gemini/DeepL)**, ensure **"Use HTML Mode"** is **ON**.

---

## 📂 7. RPA & Compressed Games

### "No texts found" even with RPYC Reader.
1. Some games hide files in `.rpa` archives. Use **Tools > RPA Extractor** first.
2. If the game is encrypted with a custom key, RenLocalizer might not be able to read it without a specialized decryptor.

---

## 💾 8. Cache & Translation Memory

### "How do I reuse translations?"
1. Go to **Tools** → **Import from tl/ Folder**.
2. Select an old translation.
3. Enable **External TM** in Settings. This saves time and money by matching common Ren'Py UI strings automatically.

---

> [!TIP]
> **Still having issues?**
> Check the **Diagnostics** report generated at the end of every translation. It lists exactly which files were skipped and why.

---> 🚩 [Open an issue on GitHub](https://github.com/Lord0fTurk/RenLocalizer/issues) if you need help!
