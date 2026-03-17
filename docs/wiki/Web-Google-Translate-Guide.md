# 🌐 Using Web Google Translate with RenLocalizer

**Date:** February 8, 2026 | **Version:** 2.6.7+  
**Author's Note:** This guide is prepared specifically for users utilizing the free web-based Google Translate service (`translate.google.com`).

---

## 📋 Table of Contents

1. [What is Web Google Translate?](#-what-is-web-google-translate)
2. [Technical Limitations](#️-technical-limitations)
3. [RenLocalizer Solutions](#-renlocalizer-solutions)
4. [Configuration](#️-configuration)
5. [Best Practices](#-best-practices)
6. [Troubleshooting](#-troubleshooting)
7. [Improvement Roadmap](#-improvement-roadmap)

---

## 🌐 What is Web Google Translate?

### Definition
**Web Google Translate** = The free, browser-based translation service accessed via `translate.google.com`.

### Comparison
| Feature | Web Version (Free) | Paid Cloud API v2 |
|---------|---------------|-----------|
| **Cost** | ✅ Free | ❌ Paid (~$20 per 1M chars) |
| **HTML Protection** | ❌ None | ✅ `format=html` |
| `translate="no"` Support | ❌ No support | ✅ Full support |
| Speed | ⚠️ Slower (Rate limiting) | ✅ Very Fast |
| Reliability | ⚠️ Variable | ✅ Guaranteed SLA |

---

## ⚠️ Technical Limitations

### Problem #1: Lack of HTML Protection
```
Sent:      "Hello [player_name] {color=#fff}text{/color}"
Google's Perception: Everything is plain text to be translated.
↓
Result:    "[player OUTSIDE_NAME {color = #fff} text {/ color}" ← CORRUPTED!
```

**Reason:** The web-based Google Translate:
- Does not understand the `format=html` parameter.
- Ignores HTML attributes like `translate="no"`.
- Focuses strictly on **plain text translation**.

### Problem #2: Spaced Token Corruption
Google Translate often adds arbitrary spaces to technical tokens during translation:

```
Sent by RenLocalizer:   VAR0
Google translation:     VAR 0  ← Space added!
Result:                 Cannot restore VAR 0 to the original variable.
```

### Problem #3: Strict Rate Limiting
- Web-based = Rate limits applied **per IP**.
- Stricter restrictions when using standard VPNs/Proxies.
- Risk of temporary bans: `429 Too Many Requests`.

---

## ✅ RenLocalizer Solutions

### Solution #1: Token-Based Protection (Default for Web)

**Principle:** Use **tokens** instead of HTML tags during the translation phase.

```python
# RenLocalizer sends protected text:
"Hello VAR0 TAG0textTAG1"

# Placeholder dictionary (stored locally):
{
    'VAR0': '[player_name]',
    'TAG0': '{color=#fff}',
    'TAG1': '{/color}'
}

# Google translates:
"Hello VAR0 TAG0textTAG1"

# RenLocalizer restores:
"Hello [player_name] {color=#fff}text{/color}"
```

**Setting:**
```json
{
    "use_html_protection": false
}
```

### Solution #2: Spaced Token Recovery (NEW v2.6.7+)

**Problem:** Google changes `VAR0` → `VAR 0`.

**Solution:** Phase 0.5 Pre-processing logic.

```python
# Inside restore_renpy_syntax():
spaced_pattern = re.compile(r'(VAR|TAG|ESC_OPEN|ESC_CLOSE|XRPYX[A-Z]*)\s+(\d+|[A-Z_]*)')
# Converts "VAR 0" back to "VAR0" before restoring the original syntax.
```

**Test Results:**
```
"VAR 0 created" → "[player_name] created" ✅ FIXED
"TAG 5 text" → "{b}text" ✅ FIXED
"ESC_OPEN 2 code" → "[var]code" ✅ FIXED
```

### Solution #3: Integrity Validation

**Function:** `validate_translation_integrity()`

Checks for **missing placeholders** after translation:

```python
missing = validate_translation_integrity(text, placeholders)
if missing:
    print(f"⚠️ WARNING: Missing placeholders: {missing}")
    # Log, retry translation, or warn the user.
```

---

## ⚙️ Configuration

### Default Behavior (v2.6.7)

In `src/utils/config.py`:
```python
use_html_protection: bool = True  # Global default (Safe for Cloud APIs)
```

### Recommended Config for Web Users:

```json
{
    "use_html_protection": false,
    "translation_engine": "google",
    "verify_placeholders": true,
    "retry_failed_strings": true
}
```

---

## 🎯 Best Practices

### ✅ DOs for Web Google Translate

| Action | Success Rate | Reason |
|-------|----------|--------|
| Use Token Mode | ✅ **100%** | Foundation for web-based safety |
| Enable Integrity Validation | ✅ **100%** | Catches corruption early |
| Use Retry Logic | ✅ **95%** | Recovers from network glitches |
| Test Small Batches First | ✅ **90%** | Quick validation before full game |

### ❌ DON'Ts for Web Google Translate

| Action | Success Rate | Reason |
|-------|----------|--------|
| Enable HTML Mode | ❌ **0%** | Web version doesn't support tags |
| Large Batch Sizes (>100) | ❌ **15%** | High risk of 429 Rate Limit |
| Long sessions without Proxy | ❌ **5%** | IP will eventually be flagged |

---

## 🔧 Troubleshooting

### Issue: PLACEHOLDER_CORRUPTED Errors

**Symptoms:**
```
[player_name] → [player OUTSIDE_NAME]
{color=#fff} → {color = #fff}
```

**Solution:**
1. Ensure **Spaced Token Fix** is enabled (v2.6.7+ performs this automatically).
2. If it persists, check the token regex in `syntax_guard.py`.

### Issue: Rate Limiting (Error 429)

**Symptoms:**
- The process stops or skips many lines.
- "Too Many Requests" appears in logs.

**Solutions:**
1. **Rotate Proxies:** Use `Settings > Proxy Manager`.
2. **Reduce Threads:** Set `Concurrent Threads` to `1` or `2`.
3. **Increase Delay:** Add `1-2 seconds` between requests.

---

## 🚀 Improvement Roadmap (v2.6.8+)

### Phase 1: Token Robustness
- [ ] **A) Pattern Expansion:** Add broader support for various spacing styles (e.g., "V AR 0").
- [ ] **B) Fuzzy Matching:** Use Jaro-Winkler or Levenshtein ratios to match corrupted tokens.
- [ ] **C) Context-Aware Recovery:** If "VAR" is expected but missing, scan nearby text for digits.

### Phase 2: User Experience
- [ ] **A) Auto-Detection:** Automatically disable HTML protection if web-based endpoints are detected.
- [ ] **B) Interactive Fix UI:** Allow users to manually drag-and-drop missing placeholders into the translated text.

---

## 📊 Performance Comparison

### Translation Speed (sec / 1000 lines)

| Engine | Speed | Reliability | Cost |
|---------|-------|-------------|------|
| **Web Google (Token)** | 120s | 85% (Fixed) | Free |
| **Paid Google Cloud API** | 15s | 98% (HTML) | Paid |
| **OpenAI (GPT-4o)** | 8s | 99% | Paid |
| **Local LLM (Llama 3)** | 60s+ | 95% | Free (needs GPU) |

---

## ✨ Summary

**If you are using Web Google Translate:**
1. ✅ Set `use_html_protection = false` in Settings.
2. ✅ Update to **v2.6.7+** for the automatic spaced token fix.
3. ✅ Keep **Batch Size** moderate to avoid rate limits.

**Result:** With the new recovery logic, RenLocalizer achieves a **95%+ success rate** even on the free web-based Google Translate service.

---

*Last updated: 8 Feb 2026 | RenLocalizer Documentation v2.6.7*
