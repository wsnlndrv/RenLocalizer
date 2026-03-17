# 🛡️ Technical String Filtering & Syntax Guard

Ren'Py files are a mix of human dialogue and technical Python code. To ensure game stability, RenLocalizer uses a multi-layered filtering and protection system.

---

## 🔹 1. Identification (Filtering)
Not every string should be translated. RenLocalizer uses **Heuristic Analysis** to decide:
*   **Deny-list:** Skips paths (`.png`, `.rpy`), colors (`#fff`), and engine internals (`config.*`, `gui.*`).
*   **Symbol Density:** If a string has too many underscores, dots, or brackets (e.g., `sys.path_manager.load_asset`), it is marked as technical and skipped.
*   **DATA_KEY_WHITELIST:** Only extracts strings assigned to high-probability keys like `name`, `title`, `desc`, or `msg`.

---

## 🔹 2. Protection (Syntax Guard v4.0)
Before sending a valid string to a translation engine (Google, GPT, DeepL), RenLocalizer "masks" the Ren'Py code to prevent the AI from translating it.

### 💎 Unicode Tokenization (The Standard)
RenLocalizer converts code to **Legacy-Proof Unicode Tokens**:
- Original: `Hello [player_name], click {b}here{/b}!`
- Masked: `Hello ⟦RLPH_0⟧, click ⟦RLPH_1⟧here⟦RLPH_2⟧!`

**Why?**
- Most AI models recognize `[` as a character to translate, but they treat `⟦` (Unicode Mathematical Brackets) as atomic units they shouldn't touch.
- It prevents `[name]` from being translated to `[isim]` or `[اسم]`.

### 🛡️ Recovery & Healing
If an AI engine returns a corrupted token, the **Surgical Healing** logic kicks in:
*   **Spaced Recovery:** `⟦ RLPH _ 0 ⟧` → `⟦RLPH_0⟧`
*   **Translit Recovery:** `[RLPH_0]` (if brackets were changed)
*   **Integrity Validation:** If a variable is lost during translation, RenLocalizer detects it and falls back to the original text to prevent a game crash.

---

## 🔹 3. HTML Mode (Cloud API)
When using professional APIs like **Gemini** or **DeepL**, RenLocalizer can use **HTML Mode**:
- Logic: Code is wrapped in `<span class="notranslate">` tags.
- Benefit: Professional APIs follow these standards strictly, providing the most reliable results.

---

## ⚠️ Troubleshooting False Positives

### **If code IS being translated (breaking the game):**
1.  Navigate to the **Glossary** page.
2.  Add the specific code word as both **Source** and **Target** (e.g., `my_variable` -> `my_variable`).
3.  RenLocalizer will now "protect" this word globally.

### **If text is NOT being translated:**
1.  Check the **Diagnostics** report in the game folder.
2.  Ensure the relevant **Text Tier** is enabled in Settings (e.g., "Deep Extraction" for hidden strings).

---
> 🔗 **Related Pages:**
> * [[Advanced-Parsing]] — The extraction logic.
> * [[Glossary-Management]] — Manual protection rules.
