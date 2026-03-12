# 🌐 Proxy Management & Rate Limits (2.7.3)

This page is the canonical place for proxy and rate-limit behavior in RenLocalizer.

For performance tuning details, also see: [[Performance-Optimization]].

---

## 🛑 What HTTP 429 Means
`HTTP 429: Too Many Requests` means the source IP is being throttled by Google.

In practice, Google rate-limits by **IP**, not by a single mirror domain.
So if one mirror returns 429, other mirrors from the same IP may also be affected.

This is why endpoint switching alone may not fully solve heavy throttling windows if the same source IP keeps being reused.

---

## ⚡ 2.7.1+ Rate-Limit Protection

RenLocalizer now applies a global cooldown and safer pacing to reduce ban cascades:

- **Global cooldown on 429:** escalating backoff (short to longer waits)
- **Health-aware endpoint selection:** unhealthy mirrors are deprioritized/temporarily banned
- **Request jitter + pacing:** avoids synchronized bursts
- **Lower risky parallelism:** helps stability under heavy load

### v2.7.3 Enhancements
- **Smart Proxy Isolation:** Proxy rotation is now intelligently disabled for local instances (`localhost`, `127.0.0.1`). Only public endpoint traffic routes through configured proxies.
- **User-Agent Rotation (LibreTranslate):** Randomized browser User-Agent spoofing for public LibreTranslate endpoints minimizes rate-limit blocks and IP bans.
- **Exponential Backoff (LibreTranslate):** 3-tier retry logic (2s, 4s, 8s) automatically handles `429 Too Many Requests` for LibreTranslate.

Result: fewer cascade bans and more stable long runs.

### What this means in practice

- Speed becomes more stable over long sessions.
- Hard fail storms are reduced, but not fully eliminated if IP pressure is high.
- Some batches may still slow down intentionally due to cooldown logic.

---

## 🛠️ Proxy Behavior in 2.7.1+

### Priority logic (important)

- If `proxy_url` **or** `manual_proxies` is configured, RenLocalizer uses **only personal/manual proxies**.
- Free proxy sources are used **only as fallback** when no personal/manual proxy is configured.

This prevents reliable private proxies from being mixed with unstable public pools.

### Why this priority exists

- Mixing private and public proxies in the same rotation often destroys consistency.
- Public lists can inject many dead/blocked nodes into an otherwise healthy pool.
- Isolating personal proxies improves predictability and easier troubleshooting.

### Rotation

- With `auto_rotate = true`, proxies rotate automatically.
- Failed proxies are deprioritized; successful ones get healthier scores.

### Health expectations by proxy type

- **Residential proxies:** best success rate, usually best sustained throughput.
- **Datacenter proxies:** can be fast but are often pre-flagged on some endpoints.
- **Public/free proxies:** highly volatile; many are dead, overloaded, or already blocked.

---

## 🧭 How to Configure

1. Open **Settings → Proxy**.
2. Enable proxy usage.
3. Choose one mode:
	- **Personal Proxy URL** (`http://user:pass@host:port`) — recommended
	- **Manual Proxy List** (`IP:PORT`, one per line)
	- **No personal proxy** → free-proxy fallback mode

4. Enable auto-rotate if you have multiple usable proxies.
5. Start with moderate concurrency and observe 429 frequency.

---

## 💡 Practical Recommendations

- For best reliability: use a personal/residential proxy.
- If using free proxies: expect unstable uptime and variable speed.
- Keep request delay reasonable when translating very large projects.
- If you still see repeated 429, pause briefly and resume (or switch proxy pool).

### Important note about free/global proxy pools

RenLocalizer includes a free proxy fallback mode, but real-world quality is limited:

- Finding actually working free proxies is often very hard.
- Many public endpoints are already burned/blocked.
- Even "working" entries can die after a short time.

Treat free proxy mode as emergency fallback, not as a high-reliability production setup.

---

## 🧪 Troubleshooting Flow (Quick)

1. Repeated 429 on many mirrors:
	- Lower concurrency slightly
	- Increase request delay a bit
	- Wait for cooldown window
2. Frequent timeouts / unstable speed:
	- Check proxy quality first
	- Remove dead proxies from manual list
3. Throughput is inconsistent batch-to-batch:
	- This can be normal under adaptive cooldown
	- Use better proxy quality for smoother long-run speed

---

## 📋 Proxy Quality Guide

- ✅ **Residential proxies:** best success rate
- ⚠️ **Datacenter proxies:** fast but frequently pre-blocked
- ❌ **Public/free lists:** inconsistent, often already burned

---

## 🔗 Related

- [[Performance-Optimization]]
- [[External-Translation-Memory]] — TM matches skip API entirely, reducing proxy/rate-limit pressure
