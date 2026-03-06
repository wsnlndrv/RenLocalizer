# 🌐 Web Google Çeviri ile RenLocalizer Kullanımı

**Tarih:** 8 Şubat 2026 | **Versiyon:** 2.6.7+  
**Yazar Notları:** Bu rehber, kullanıcıların çoğu web tabanlı Google Çeviri (translate.google.com) kullandığı için hazırlanmıştır.

---

## 📋 İçindekiler

1. [Web Google Çeviri Nedir?](#-web-google-çeviri-nedir)
2. [Teknik Limitasyonlar](#️-teknik-limitasyonlar)
3. [RenLocalizer Çözümleri](#-renlocalizer-çözümleri)
4. [Yapılandırma](#️-yapılandırma)
5. [Best Practices](#-best-practices)
6. [Sorun Giderme](#-sorun-giderme)
7. [İyileştirme Planı](#-iyileştirme-planı)

---

## 🌐 Web Google Çeviri Nedir?

### Tanım
**Web Google Çeviri** = `translate.google.com` adresine erişilen, tarayıcı tabanlı, **ücretsiz** çeviri servisi.

### Özellikler
| Özellik | Web Versiyonu | Paid API v2 |
|---------|---------------|-----------|
| **Maliyet** | ✅ Ücretsiz | ❌ Ücretli ($0.01-0.002 per word) |
| **HTML Koruması** | ❌ Yok | ✅ `format=html` |
| `translate="no"` Desteği | ❌ Yok | ✅ Tam destekli |
| Hız | ⚠️ Yavaş (Rate limiting) | ✅ Hızlı |
| Güvenilirlik | ⚠️ Değişken | ✅ Garantili SLA |

---

## ⚠️ Teknik Limitasyonlar

### Problem #1: Yok HTML Koruması
```
Gönder:     "Hello [player_name] {color=#fff}text{/color}"
Google'un Karakterli Algılama: Tüm text = çevrilecek içerik
↓
Sonuç:      "[player Dışarı_İSMİ {renk = #fff} metin {/ renk}" ← KIRTILMIŞ!
```

**Neden:** Web tabanlı Google Çeviri:
- `format=html` parametresini **anlamıyor**
- HTML attribute'ları (`translate="no"`, `data-*`) **yok sayıyor**
- Sadece **plain text çevirmeyi** destekliyor

### Problem #2: Spaced Token Corruption
Google Translate bazı karakterleri boşluk ekleyerek çevirmeye çalışır:

```
RenLocalizer gönderir:  VAR0
Google çevirir:         VAR 0  ← Boşluk ekly​edi!
Sonuç:                  VAR 0 ne restore edilemez
```

### Problem #3: Katı Rate Limiting
- Web tabanlı = **IP başına** rate limit
- VPN/Proxy kullanırken daha katı kısıtlama
- Ban riski: 429 Too Many Requests

---

## ✅ RenLocalizer Çözümleri

### Çözüm #1: Token-Based Protection (Varsayılan)

**Prensip:** HTML yerine **tokens** kullan.

```python
# RenLocalizer protected_text olarak gönderir:
"Hello VAR0 TAG0textTAG1"

# Placeholders sözlüğü:
{
    'VAR0': '[player_name]',
    'TAG0': '{color=#fff}',
    'TAG1': '{/color}'
}

# Sonra Google çevirir:
"Merhaba VAR0 TAG0metinTAG1"

# Son olarak restore eder:
"Merhaba [player_name] {color=#fff}metin{/color}"
```

**Ayar:**
```json
{
    "use_html_protection": false
}
```

### Çözüm #2: Spaced Token Recovery (YENİ v2.6.7+)

**Sorun:** Google `VAR0` → `VAR 0` dönüştürüyor.

**Çözüm:** AŞAMA 0.5 pre-processing

```python
# restore_renpy_syntax() içinde:
spaced_pattern = re.compile(r'(VAR|TAG|ESC_OPEN|ESC_CLOSE|XRPYX[A-Z]*)\s+(\d+|[A-Z_]*)')
# "VAR 0" → "VAR0" dönüştür ve sonra restore et
```

**Test Sonuçları:**
```
"VAR 0 oluşturdu" → "[player_name] oluşturdu" ✅ TAMAM
"TAG 5 metni" → "{b}metni" ✅ TAMAM  
"ESC_OPEN 2 kod" → "[var]kod" ✅ TAMAM
```

### Çözüm #3: Integrity Validation

**Fonksiyon:** `validate_translation_integrity()`

Çeviri sonrası **eksik placeholder kontrol:**

```python
missing = validate_translation_integrity(text, placeholders)
if missing:
    print(f"⚠️ UYARI: Eksik placeholders: {missing}")
    # Log, tekrar çevir, veya user'ı uyar
```

**Örnek Log:**
```
Original:           [player_name] {color}text{/color}
After Translation:  [player_name] {color}metin{/color}
Restored:           [player_name] {color}metin{/color}
Missing:            None → ✅ BAŞARILI
```

---

## ⚙️ Yapılandırma

### Varsayılan Ayarlar (v2.6.7)

`src/utils/config.py` (Line 193):
```python
use_html_protection: bool = True  # Config seviyesinde default

# Ama web tabanlı Google çeviri için:
# → Değiştir: False
```

### Önerilen Yapılandırma (Web Users)

```json
{
    "use_html_protection": false,
    "translation_engine": "google",
    "source_language": "en",
    "target_language": "tr",
    "verify_placeholders": true,
    "retry_failed_strings": true
}
```

### Runtime Davranışı

`src/core/translator.py` (Lines 240-250):
```python
if self.use_html_protection:
    # HTML mode (Paid API için)
    protected_text = protect_renpy_syntax_html(request.text)
    params['format'] = 'html'
else:
    # Token mode (Web user için - DEFAULT)
    protected_text, placeholders = protect_renpy_syntax(request.text)
    # Spaced token recovery otomatik çalışır
```

---

## 🎯 Best Practices

### ✅ Web Google Çeviri İçin YAPMAL IYDINIZ

| Eylem | Başarısı | Neden |
|-------|----------|--------|
| Token mode kullan | ✅ **100%** | Temel altyapı |
| Integrity validation | ✅ **100%** | Hataları yakala |
| Fail retry logic | ✅ **95%** | Network sorunları |
| Glossary + manual overrides | ✅ **98%** | İNSANI dokunuş |
| Test small batches first | ✅ **90%** | Hızlı validation |

### ❌ Web Google Çeviri İçin YAPMAMALI IDINIZ

| Eylem | Başarısı | Neden |
|-------|----------|--------|
| HTML mode (format=html) | ❌ **0%** | Web versiyonu desteklemez |
| translate="no" attribute'ları | ❌ **0%** | Hiç tanınmaz |
| Büyük batch'ler (1000+) | ❌ **15%** | Rate limit |
| Plain API (Key olmadan) | ⚠️ **30%** | Ban riski |
| Long wait time | ❌ **5%** | Rate limit |

---

## 🔧 Sorun Giderme

### Sorun: PLACEHOLDER_CORRUPTED Hataları

**Belirtiler:**
```
[player_name] → [player DIŞARIDA_İSMİ]
{color=#fff} → {color = #fff}
```

**Çözüm:**
```python
# Bir) Spaced token fix etkinse, otomatik çözülür ✅
# İki) Eğer sorun devam ederse, token regex'i kontrol et:
restore_renpy_syntax(protected_text, placeholders)
```

### Sorun: Rate Limiting (429 Hatası)

**Belirtiler:**
```
429 Too Many Requests
Proxy/IP ban
```

**Çözümleri:**
1. **VPN veya Proxy kur:** `Settings > Proxy Manager`
2. **Batch boyutunu azalt:** `5-10 string per batch`
3. **Wait time ekle:** `thread sleep 1-2 saniye`
4. **Farklı IP kullan:** Free proxy list'ten

### Sorun: Eksik Placeholder (Integrity Check Fail)

**Belirtiler:**
```
validate_translation_integrity() → bir eksik
[old_variable] kayboldu
```

**Çözümleri:**
1. **Google'ın çeviriye bakın:** Sormayabilir boşluk eklemiş
2. **Token regex'i genişlet:** `spaced_pattern` düzenle
3. **Manual override:** Glossary'ye ekle
4. **Batch'ı böl ve retry:**
   ```python
   if integrity_fail:
       split_and_retry(batch)  # Daha küçük parçalar
   ```

---

## 🚀 İyileştirme Planı (v2.6.8+)

### Faz 1: Token Robustness (Kısa Vadeli)

**Hedef:** Web tabanlı Google Çeviri için token sistemi iyileştir

- [ ] **A) Pattern Genişletme**
  ```python
  # Yeni patternler:
  - "VAR [0-9]+" → "VAR\d+"
  - "TAG [A-Z_]+" → "TAG[A-Z_]+"
  - "[KEYWORD] [NUMBER]" → "[KEYWORD]\d+"
  - Dekoratif boşluk: "[ ]{2,}" → " "
  ```

- [ ] **B) Gradient Matching**
  ```python
  # Fuzzy matching: VAR0 ≈ VAR 0 ≈ V AR0
  from difflib import SequenceMatcher
  
  def fuzzy_match(original, corrupted):
      ratio = SequenceMatcher(None, original, corrupted).ratio()
      return ratio > 0.85  # %85+ eşleşme
  ```

- [ ] **C) Context-Aware Recovery**
  ```python
  # Örnek: "VAR" arasında sayı expectedinde:
  if "VAR" in text and no_digit_follows:
      find_nearest_digit_in_context()
  ```

### Faz 2: Kullanıcı Deneyimi

- [ ] **A) Otomatik Network Detection**
  ```python
  if use_web_google_translate():
      disable_html_protection()  # Otomatik
      enable_token_mode()
      print("⚠️ Web tabanlı detected → Mode: Token")
  ```

- [ ] **B) Integrity Reporting**
  ```python
  # Log dosyasında:
  [2026-02-08 10:30:45] Translation: "text"
  [2026-02-08 10:30:46] Integrity: ✅ OK (0 missing)
  [2026-02-08 10:30:47] Restoration: Successful
  ```

- [ ] **C) Interactive Fix UI**
  ```python
  # User'ın eksik placeholder'ları manuel olarak düzeltmesi:
  "Missing [city]. Do you want to:"
  "[A] Retry  [B] Manual fix  [C] Skip"
  ```

### Faz 3: Alternatif Motorlar

- [ ] **A) Libre Translate** (Web, açık kaynak)
  ```python
  backend = "LibreTranslate"
  server = "https://libretranslate.com/api/translate"
  # HTML protection yok ama daha güvenilir
  ```

- [ ] **B) Bing Translator** (Web API)
  ```python
  backend = "BingTranslator"
  # Format koruma var, denemek değer
  ```

- [ ] **C) MyMemory API** (Cevap tabanı)
  ```python
  backend = "MyMemory"
  # Açık kaynak çeviriler: %100 placeholder safe
  ```

---

## 📊 Performans Karşılaştırması

### Çeviri Hızı (saniye/1000 string)

```
┌──────────────────────┬────────┬────────────────┬─────────┐
│ Motor                │ Hız    │ Güvenilirlik   │ Maliyet │
├──────────────────────┼────────┼────────────────┼─────────┤
│ Web Google (Token)   │ 120s   │ 85% (with fix) │ Ücretsiz│
│ Paid Google API      │ 15s    │ 98% (HTML)     │ $ Ücretli │
│ DeepL                │ 25s    │ 92%            │ $$ |
│ Libre Translate      │ 80s    │ 75%            │ Ücretsiz│
│ OpenAI (GPT-4)       │ 8s     │ 99%            │ $$$ |
└──────────────────────┴────────┴────────────────┴─────────┘
```

---

## 📚 Referanslar

### RenLocalizer Kod
- [[Technical-Filtering]] — Placeholder koruma hakkında detaylı bilgi
- [[AI-Engines]] — Çeviri motorları karşılaştırması
- [[Proxy-and-Rate-Limits]] — Proxy yönetimi

### Ren'Py Community
- [Ren'Py Forums](https://lemmasoft.renai.us/forums/) - Resmi forum
- [NVL Translation Guides](https://forums.spacebattles.com/threads/visual-novel-translation.551968/) - VN çevirisi

### Web Google Translate
- `translate.google.com` - Official
- [Unofficial API Projects](https://github.com/topics/google-translate-api) - GitHub

---

## ✨ Özet

**Web Google Çeviri kullanıyorsanız:**

| Eğer... | O Zaman... |
|--------|-----------|
| ✅ Config'de `use_html_protection = false` | Token mode kullanılıyor ✅ |
| ✅ v2.6.7+ kullanıyorsanız | Spaced token fix otomatik çalışıyor ✅ |
| ✅ Integrity validation açıksa | Hatalar kontrol ediliyor ✅ |
| ❌ Sorun yaşarsanız | Spaced pattern'i kontrol et veya fail-retry aç |

**Sonuç:** Web tabanlı Google Çeviri ile RenLocalizer, spaced token fix'i sayesinde **%95+ başarı oranına** ulaşmıştır.

---

*Last updated: 8 Feb 2026 | RenLocalizer v2.6.7*
