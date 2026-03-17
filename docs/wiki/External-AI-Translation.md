# 📤 External AI Translation (Export/Import Workflow)

The **External AI Translation** feature allows you to translate game strings without using a direct API connection. This is the "Manual/Offline" alternative to the direct translation pipeline, ideal for using web interfaces like ChatGPT/Claude or for team-based localizations.

---

## 🔄 The Round-trip Workflow

This feature follows a structured 4-step process:
1. **Export:** Scan your project in the **Tools** tab and export untranslated strings to a transfer file.
2. **External Translation:** Upload the file to an AI (Claude, GPT-4, etc.) or open it in a tool like Excel/Google Sheets.
3. **Refine:** Manually check or AI-generate translations while keeping the original IDs intact.
4. **Import:** Bring the translated file back into RenLocalizer to update your game instantly.

---

## 📄 Supported Export Formats (v2.7+)

RenLocalizer provides several formats depending on your workflow:

### 1. JSON (Structured - Recommended for AI)
The professional standard. Includes `translation_id`, `character`, and `context`.
*   **Best for:** Uploading to Claude 3.5, GPT-4o, or OpenRouter.
*   **Logic:** Preserves metadata used for perfect matching during import.

### 2. XLSX / CSV (Excel - Recommended for Human Teams)
Newer versions support exporting to spreadsheets.
*   **Best for:** Human translators or bulk editing in Google Sheets.
*   **Structure:** Column A (Original), Column B (Translation), Column C (ID).

### 3. Simple TXT (Chat-Friendly)
A minimalist format designed for "Copy-Paste" into AI web chats.
*   **Format:** `ID|||Text`
*   **Benefit:** Zero overhead, fits more strings into a single AI prompt.

---

## 🛠️ Advanced Export Settings

*   **Export Only Untranslated:** (Default) Only extracts what hasn't been localized yet.
*   **Include Context:** Adds character names and file paths as comments in the export.
*   **Chunk Size:** Automatically splits large projects into manageable pieces (e.g., 500 strings per file) to avoid AI truncation.
*   **Instruction Generation:** RenLocalizer automatically creates a `PROMPT_FOR_AI.txt` in your export folder. **Read and use this prompt!** It contains the rules the AI must follow to preserve syntax.

---

## 🧠 External Translation Memory (TM) Entegration

In **v2.7.3+**, you can use these exported/imported files as **External TM**.
1. Import a completed translation file from another project.
2. Enable "Use External TM" in **Settings**.
3. RenLocalizer will now check this "Memory" before making any API calls, saving you money and time.

---

## 💡 Pro Tips for AI Translation

*   **The "Context" Rule:** Always include character descriptions in your first prompt. AI translates better when it knows "Eileen" is a cheerful guide vs. a serious villain.
*   **Verify Placeholders:** If you see `[ isim ]` instead of `[name]`, the AI added spaces. Use the **Tools > Placeholder Fixer** if this happens during a manual import.
*   **Recursive Workflow:** You can Export → Translate → Import → Then use the **Direct Translator** for any remaining or tricky strings.

---
> 🔗 **Related Pages:**
> * [[Settings-UI-Reference]] — How to enable TM.
> * [[Output-Formats]] — The technical details of what gets imported.
