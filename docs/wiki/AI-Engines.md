# 🤖 AI Translation Engines

RenLocalizer integrates modern Large Language Models (LLMs) to provide context-aware, high-quality translations that understand the nuances of your game's dialogue.

---

## 🔹 🟢 OpenAI / OpenRouter
The industry standard for high-quality AI translation.
*   **Setup:** Enter your API key in the Settings tab.
*   **OpenRouter Support:** To use models like Claude 3.5 or Llama 3, change the **Base URL** to `https://openrouter.ai/api/v1` and use your OpenRouter key.

## 🔹 🟡 Google Gemini
Fast, reliable, and often includes a generous free tier.
*   **Setup:** Select the `Gemini` provider.
*   **API Key:** Obtain your key from [Google AI Studio](https://aistudio.google.com/).
*   **Safety Hint:** Set the safety threshold to `BLOCK_NONE` for uncensored game content.

## 🔹 🔵 Local LLM (Offline & Private)
Run models locally on your hardware. **No cost, 100% privacy.**
*   **Supported Backends:** Ollama, LM Studio, LocalAI.
*   **Model Recommendations:** `Qwen 2.5 7B`, `Llama 3.1 8B`, or `Dolphin-Mistral`.
*   **Default URLs:** 
    *   Ollama: `http://localhost:11434/v1`
    *   LM Studio: `http://localhost:1234/v1`

## 🔹 🔴 DeepSeek (New in v2.6.4)
State-of-the-art reasoning model, excellent for complex syntax.
*   **Setup:** Select the `DeepSeek` provider in Settings.
*   **API Key:** Get it from [platform.deepseek.com](https://platform.deepseek.com).
*   **Why use it?** DeepSeek follows XML tag instructions (`<ph id="0">`) with near-perfect accuracy, making it ideal for code-heavy games.

---

## 🛠️ How RenLocalizer Protects Your Code (XML)
In v2.6.4+, RenLocalizer wraps all variables and placeholders in XML tags before sending them to the AI.
*   **Original:** `Hello [player_name], you obtained {b}Sword{/b}.`
*   **Sent to AI:** `Hello <ph id="0">[player_name]</ph>, you obtained <ph id="1">{b}</ph>Sword<ph id="2">{/b}</ph>.`
*   **Benefit:** The AI understands that anything inside `<ph>` tags is **sacred code** and must not be translated. This drastically reduces syntax errors.

## ⚙️ Advanced AI Parameters

| Parameter | Default | Description |
| :--- | :--- | :--- |
| **Temperature** | 0.3 | **0.1-0.3** for consistency. **0.7+** for creative flair. |
| **Max Tokens** | 2048 | Limits the length of the AI's response. |
| **Batch Size** | 5-10 | Strings per prompt. Higher is faster but may reduce quality. |
| **System Prompt** | *Auto* | Instructions for the AI (e.g., "Translate as a fantasy novelist"). |

---

## 🛡️ Content Safety & Refusals
Standard AI providers (OpenAI/Gemini) may refuse to translate "NSFW" or violent content due to their safety policies.

### 💡 Solutions:
1.  **Gemini:** Set Safety Level to `BLOCK_NONE`.
2.  **OpenRouter:** Use "Uncensored" models like `dolphin-mistral`.
3.  **Local LLM:** Use models without ethical alignment (Instruct/Uncensored).
4.  **Fallback:** RenLocalizer can automatically use **Google Translate** if the AI refuses a specific line.

---
> 📘 **See Also:** [[LM-Studio-Guide]] for a detailed local setup.
