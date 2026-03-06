# 🚀 Performance Optimization Guide

RenLocalizer is built for speed, capable of processing projects with over 100,000 lines. Use this guide to squeeze every bit of performance out of the tool.

For detailed proxy behavior, 429 handling, and proxy quality guidance, see: [[Proxy-and-Rate-Limits]].

---

## 🔹 Multi-Endpoint Google Architecture
Instead of using a single connection, RenLocalizer "races" multiple requests across different Google mirrors.

*   **Lingva Fallback:** If the primary service rate-limits you, the app automatically switches to Lingva servers.
*   **Result:** Translation speed jumps from ~3 strings/sec to **~10+ strings/sec**.
*   **Important:** Ensure "Aggressive Translation" is **OFF** in Settings. Enabling it forces double-checks for every line, reducing speed by ~50%.

---

## 🌐 Proxy & Real-World Speed Variability

Google-side behavior is not constant. Even with RenLocalizer's protections, throughput can fluctuate heavily depending on IP reputation, endpoint health, and current throttling pressure.

Typical examples in real usage:

*   A 100-line chunk may finish in around **1 second** in healthy conditions.
*   The same size chunk may take **6-8 seconds** when throttling/cooldowns kick in.
*   In unstable windows, completion time can swing between fast and slow batches.

Using a good proxy (especially residential/private) can improve stability and often improve sustained speed by reducing repeated throttling on a single public IP.

Important caveat:

*   Proxy use is **not a guaranteed speed boost** for every request.
*   Poor proxies can make performance worse (timeouts, failed handshakes, dead exits).
*   Best gains come from **high-quality, stable proxy pools**.

For setup details and proxy mode behavior, go to [[Proxy-and-Rate-Limits]].

---

## ⚙️ Key Tuning Settings

| Setting | Recommended | Description |
| :--- | :--- | :--- |
| **Parser Workers** | 4-8 | Number of CPU threads used for file scanning. Match your CPU core count. |
| **Concurrent Threads** | 32-64 | Simultaneous translation requests. Set higher for fast fiber internet. |
| **Batch Size** | 200-500 | How many strings are sent in one block. Larger is faster but uses more RAM. |
| **Request Delay** | 100ms | Pause between requests. Increase if you see `HTTP 429` errors. |

---

## 🧠 Memory & System Load
For low-end systems or very massive games:

1.  **Lower Batch Size:** Reduces peak memory (RAM) usage.
2.  **Lower Workers:** prevents the UI from freezing during the initial "Extracting" phase.
3.  **Use SIMPLE Format:** Produces smaller `.rpy` files that are easier for both the tool and the game to handle.

---

## 🌐 Engine Selection
*   **Fastest:** Google (via Multi-Endpoint).
*   **High Quality:** DeepL (Requires API Key).
*   **Smartest:** AI Engines (GPT/Gemini). **Note:** These are much slower due to the nature of Large Language Models.

---

## ✅ Practical Speed Strategy (Recommended)

1.  Start with Google Multi-Endpoint and sensible concurrency.
2.  Keep Aggressive Translation OFF unless quality fallback is required.
3.  If you get repeated 429 bursts, use a reliable personal proxy.
4.  If free proxy mode is used, expect unstable latency and frequent dead nodes.
5.  Tune delay/concurrency gradually instead of jumping to extreme values.

---
> 💡 **Tip:** Use **Google** for the bulk of the game and switch to **AI** only for the most important story dialogue to save time.
