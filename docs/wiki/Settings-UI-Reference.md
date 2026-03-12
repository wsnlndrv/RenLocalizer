# ⚙️ Settings & UI Reference

This guide explains the advanced options found in the RenLocalizer **Settings** tab. Understanding these settings will help you optimize translation quality and performance.

---

## 🌐 General Settings

### **Language & Theme**
*   **App Language:** Changes the interface language of RenLocalizer itself.
*   **Theme:** Switches between Light, Dark, and System themes.
*   **Check Updates:** If enabled, the app checks for new versions on GitHub startup.
13: 
14: ### **Smart Data Path (v2.7.4)**
15: *   **Portable Mode Toggle:** Switches between storing user data in `AppData` (System Mode) or next to the application (Portable Mode).
16: *   **Automatic Migration:** Switching modes automatically **moves** (not copies) your `cache/`, `tm/`, and `glossary.json` files to the correct location.
17: *   **Open Data Folder:** A quick shortcut to open the active data directory (either AppData or the Local folder) in File Explorer.

---

## 🔍 Translation Filters (What to Translate?)

These checkboxes control *which* parts of the game script get translated.

*   **Dialogue:** The main story text spoken by characters.
*   **Menu Options:** Choices the player makes (e.g., "Go Left", "Go Right").
*   **Buttons/UI:** Text on buttons (Start, Load, Save) and interface elements.
*   **Notifications:** Small popup messages in the game.
*   **Ren'Py Functions:** Advanced technical strings inside code blocks. *Only enable if you know what you are doing.*

---

## 🎛️ AI Model Parameters

Control how the AI "thinks" and behaves.

### **Temperature (Creativity)**
*   **Range:** `0.0` - `2.0`
*   **Recommended:** `0.3` for accuracy, `0.7` for creative writing.
*   **Effect:** Lower values make the AI more deterministic and focused. Higher values make it more random and creative.

### **Max Tokens**
*   Limits the length of the AI's response.
*   **Default:** `2048` usually suffices for game dialogue. Increase if you are translating very long lore books.

### **Deep Scan (Derin Tarama)**
*   **What it does:** Scans Python blocks (`init python:`) and AST nodes for hidden strings that normal scanning misses.
*   **Cost:** Slower processing time.
*   **Use case:** Enable if some menus or dynamic texts remain untranslated.

### **Aggressive Retry**
*   **What it does:** If the AI returns the *exact same text* as the original (refusing to translate), the tool forces a retry with a stricter "You MUST translate this" prompt.
*   **Default:** `Disabled` (v2.6.4+) to maximize batch processing speed.
*   **Use case:** Enable only if you notice many untranslated lines in the output.

---

## ⚡ Performance & Advanced

### **Batch Size**
*   Number of lines sent to the AI in a single request.
*   **Higher (50+):** Faster, but risk of AI skipping lines or "lazy" translation.
*   **Lower (10-20):** Higher accuracy, slower speed.

### **Concurrent Threads**
*   How many parallel requests to generate.
*   **Warning:** Setting this too high may hit API Rate Limits (Error 429) quickly.

### **RPYC Reader**
*   **Experimental:** Allows the tool to read compiled `.rpyc` files directly if the source `.rpy` files are missing or obfuscated.

### **Force Runtime Translation**
*   Injects a script into the game to force Ren'Py to translate strings on-the-fly. This is a powerful backup for strings that hard-coded scanning simply cannot find.

---

## 🧠 External Translation Memory

### **Use External TM**
*   **Default:** `OFF`
*   **What it does:** Enables the External Translation Memory system. When enabled, RenLocalizer checks imported TM sources for exact matches before calling any translation API.
*   **How to use:** Import TM sources from the **Tools** page first, then enable this toggle.
*   **Benefit:** Reduces API calls, speeds up translation, and ensures consistency for common strings.

> 📖 See [[External-Translation-Memory]] for the full guide on importing and using TM.
