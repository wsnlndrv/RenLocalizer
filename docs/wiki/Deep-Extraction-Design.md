# 🔬 Deep Extraction — Teknik Tasarım Dokümanı

> **Hedef Sürüm:** RenLocalizer v2.7.1  
> **Durum:** ✅ Uygulandı  
> **Yazar:** RenLocalizer Core Team  
> **Bağımlılıklar:** parser.py, rpyc_reader.py, rpymc_reader.py

---

## 📋 İçindekiler
1. [Yönetici Özeti](#-1-yönetici-özeti)
2. [Mevcut Mimari](#-2-mevcut-mimari)
3. [Boşluk Analizi](#-3-boşluk-analizi)
4. [Ren'Py Metin Taşıyan API Kataloğu](#-4-renpy-metin-taşıyan-api-kataloğu)
5. [Deep Extraction Tasarımı](#-5-deep-extraction-tasarımı)
6. [Uygulama Planı](#-6-uygulama-planı)
7. [Yanlış Pozitif Önleme Stratejisi](#-7-yanlış-pozitif-önleme-stratejisi)
8. [Test Matrisi](#-8-test-matrisi)

---

## 🎯 1. Yönetici Özeti

RenLocalizer v2.7.1, `.rpy` ve `.rpyc` dosyalarındaki standart `say` bloklarını, `_()` sarılmış stringleri ve regex tabanlı pattern eşleşmelerini başarıyla çıkarmaktadır. Ancak **gerçek dünya Ren'Py projelerinde** önemli bir yerelleştirme boşluğu mevcuttur:

| Kategori | Örnekler | Mevcut Kapsam |
|---|---|---|
| Bare `define` stringleri | `define quest_title = "The Dark Forest"` | ❌ Kaçırılıyor |
| Bare `default` stringleri | `default player_name = "Adventurer"` | ❌ Kaçırılıyor |
| Karmaşık veri yapıları | `define quests = {"q1": "Kill the dragon"}` | ❌ Kaçırılıyor |
| Python blokları içindeki stringler | `init python: tips = ["Press F1"]` | ⚠️ Kısmi (deep_scan) |
| f-string'ler (.rpy) | `$ msg = f"Welcome {player}"` | ❌ Parser'da yok |
| `renpy.notify()` vb. API çağrıları | `$ renpy.notify("Save complete")` | ✅ RPYC'de var / ⚠️ Parser kısmi |
| Screen action stringleri | `Confirm("Delete save?", ...)` | ✅ RPYC'de var / ⚠️ Parser kısmi |
| `config.*` metin atamaları | `define config.name = "My Great Game"` | ⚠️ Kısmi |
| `gui.*` metin atamaları | `define gui.about = _("About this game")` | ⚠️ Kısmi (`_()` ile) |
| `tooltip` property stringleri | `tooltip "Click to save"` | ❌ Kaçırılıyor |
| `QuickSave(message=...)` | `QuickSave(message="Saved!")` | ❌ Kaçırılıyor |
| `CopyToClipboard(s)` | `CopyToClipboard("Link copied")` | ❌ Kaçırılıyor |
| `FilePageNameInputValue(pattern=...)` | `FilePageNameInputValue("Page {}")` | ❌ Kaçırılıyor |

**Deep Extraction**, bu boşlukları doldurmak için mevcut 4 katmanlı mimariyi geliştiren bir **5. katman** olarak tasarlanmıştır.

---

## 🏗 2. Mevcut Mimari

### 2.1 Parser (`src/core/parser.py` — 3276 satır)

```
Katman 1: Regex Pattern Registry
├── dialogue_re, narration_re, menu_re ...
├── general_define_re → define gui/config.var = "text"
├── default_translatable_re → default var = _("text")
├── notify_re, confirm_re, renpy_input_re
└── pattern_registry (öncelik sıralı eşleşme)

Katman 2: Secondary Passes
├── action_call_re → Confirm(), Notify(), Input()
├── show_text_re → show text "..."
├── window_text_re → window show "..."
├── hidden_args_re → (what_prefix="...")
└── triple/double_underscore_re → ___(), __()

Katman 3: Deep Scan (ayrı mod)
├── deep_scan_strings() → Kapsamlı string taraması
├── _extract_python_blocks_for_ast() → python: blokları
└── Lookback context, anahtar-değer tespiti

Katman 4: is_meaningful_text() Filtresi
├── Uzunluk, encoding, teknik string kontrolü
├── DATA_KEY_WHITELIST / BLACKLIST
└── Ren'Py internal pattern filtreleme
```

### 2.2 RPYC Reader (`src/core/rpyc_reader.py` — 2590 satır)

```
Binary AST Node İşleme
├── FakeDefine → _extract_from_code_obj()
├── FakeDefault → _extract_from_code_obj()
├── FakeUserStatement → çeşitli handler'lar
└── Say, Menu, NVL düğümleri

_extract_strings_from_code() — Regex Tabanlı
├── _("text"), __("text"), ___("text")
├── renpy.notify(), Character(), renpy.say()
├── Text(), !t flag, nvl, config.name
├── gui.text_*, Smart Key scanner
└── Genel string yakalama

_extract_strings_from_code_ast() — AST Tabanlı (DeepStringVisitor)
├── visit_Call: _(), p(), Confirm(), Notify(), MouseTooltip()
│   ui.text(), ui.textbutton(), renpy.input(), renpy.say()
│   achievement.register(), Tooltip()
├── visit_Assign: Bağlam takibi (sol taraf anahtar kelime)
├── visit_Dict: Anahtar bağlam tespiti
├── visit_List: Liste elemanları
├── visit_Constant: Filtreli string yakalama
└── visit_JoinedStr: f-string yeniden oluşturma
```

### 2.3 Önemli Yapısal Gözlemler

| Özellik | Parser (.rpy) | RPYC Reader (.rpyc) |
|---|---|---|
| f-string desteği | ❌ Yok | ✅ `visit_JoinedStr` |
| AST ile derin analiz | ⚠️ Sadece python blokları | ✅ Tüm kod nesneleri |
| `define` bare string | ⚠️ Sadece gui/config prefixli | ✅ `FakeDefine` → `_extract_from_code_obj` |
| `default` bare string | ❌ Sadece `_()` sarılı | ✅ `FakeDefault` → `_extract_from_code_obj` |
| Veri yapısı derinliği | ❌ Tek seviye | ✅ `visit_Dict` + `visit_List` rekursif |
| Smart Key analizi | ❌ Yok | ✅ DATA_KEY_WHITELIST tabanlı |

---

## 🔍 3. Boşluk Analizi

### 3.1 Kritik Boşluklar — Parser (.rpy dosyaları)

#### Gap-P1: Bare `define` Stringleri
```renpy
# ŞU AN KAÇIRILIYOR:
define quest_title = "The Dark Forest"
define npc_greeting = "Hello, traveler!"
define chapter_names = ["Prologue", "Act I", "Finale"]

# ŞU AN YAKALANIYOR (sadece gui/config prefix ile):
define config.name = "My Game"
define gui.about = _("Version 1.0")
```

**Sebep:** `general_define_re` yalnızca `gui.` ve `config.` prefixli değişkenleri hedefler. Oyun geliştiricileri sıklıkla kendi namespace'lerinde metin tanımlar.

#### Gap-P2: Bare `default` Stringleri
```renpy
# ŞU AN KAÇIRILIYOR:
default player_title = "Recruit"
default current_objective = "Explore the cave"
default save_name = "Chapter 1 - Beginning"

# ŞU AN YAKALANIYOR:
default translated_name = _("Default Name")
```

**Sebep:** `default_translatable_re` yalnızca `_()` içine sarılmış stringleri yakalar. Pek çok oyun geliştirici yerelleştirme fonksiyonlarını kullanmaz.

#### Gap-P3: Karmaşık Veri Yapıları
```renpy
# ŞU AN KAÇIRILIYOR:
define quest_data = {
    "title": "Dragon Slayer",
    "desc": "Kill the mighty dragon",
    "reward": "1000 gold"
}

default inventory_labels = ["Sword", "Shield", "Potion"]

define achievements = [
    {"name": "First Blood", "desc": "Win your first battle"},
    {"name": "Explorer", "desc": "Visit all locations"}
]
```

**Sebep:** Parser regex tabanlıdır ve çok satırlı/iç içe veri yapılarını analiz edemez. Sadece `deep_scan_strings()` bunların bir kısmını yakalayabilir, ancak bağlam bilgisi (hangi key'in metin taşıdığı) kaybolur.

#### Gap-P4: f-string'ler (.rpy dosyalarında)
```renpy
# ŞU AN KAÇIRILIYOR:
$ message = f"Welcome back, {player_name}!"
$ status = f"Day {day_count}: {weather_desc}"
$ tooltip_text = f"{item_name} - {item_desc}"
```

**Sebep:** RPYC reader'da `visit_JoinedStr` mevcut ama parser'da eşdeğeri yok. Parser'ın `deep_scan_strings()` fonksiyonu f-prefix'i tanımıyor.

#### Gap-P5: Genişletilmemiş Ren'Py API Çağrıları
```renpy
# ŞU AN KAÇIRILIYOR (parser'da):
$ renpy.confirm("Are you sure?")
$ narrator("And then it happened.")
$ renpy.display_menu([("Option A", "a"), ("Option B", "b")])

# ŞU AN YAKALANIYOR (sadece özel regex ile):
$ renpy.notify("Saved!")  → notify_re ile
```

**Sebep:** Parser'ın bir `renpy.confirm()` regex'i yok. RPYC reader ise AST ile bunları zaten yakalıyor.

#### Gap-P6: Screen Language `tooltip` Property
```renpy
# ŞU AN KAÇIRILIYOR:
textbutton "Save" action FileSave(1) tooltip "Quick save to slot 1"
imagebutton auto "btn_%s" action Start() tooltip "Begin your adventure"
```

**Sebep:** `tooltip` özelliği screen language'de bir property olarak yaşar, regex ile yakalanması zordur.

### 3.2 Orta Boşluklar — RPYC Reader

#### Gap-R1: Eksik Screen Action Metin Çağrıları
```python
# DeepStringVisitor'da EKSİK:
QuickSave(message="Save complete!")
CopyToClipboard("URL copied to clipboard")
FilePageNameInputValue(pattern="Page {}", auto="Auto saves", quick="Quick saves")
Preference("display", "fullscreen")  # İkinci arg çevirilmemeli ama ilk string önemli olabilir
Help("See the manual")
OpenURL(url)  # URL çevrilmemeli — yanlış pozitif riski
```

#### Gap-R2: `config.notify`, `config.name`, `config.window_title` Atamaları
```python
# Kısmen yakalanıyor ama genişletilebilir:
config.name = "My Visual Novel"
config.version = "1.2.3"
config.window_title = "My Game - Episode 2"
```

#### Gap-R3: Named Store Stringleri
```renpy
init python in mystore:
    greeting = "Hello"
    farewell = "Goodbye"

default schedule.day_names = ["Monday", "Tuesday"]
```

**Sebep:** `python in` blokları farklı store'lara yazılabilir, parse mantığı bunu hesaba katmalı.

---

## 📚 4. Ren'Py Metin Taşıyan API Kataloğu

Ren'Py 8.5.3 resmi dokümantasyonundan derlenen kapsamlı çağrı listesi:

### 4.1 Tier-1: Kesinlikle Metin İçeren (Yüksek Öncelik)

| Fonksiyon / Sınıf | Metin Parametresi | Mevcut Kapsam |
|---|---|---|
| `renpy.notify(message)` | `message` | ✅ RPYC, ⚠️ Parser regex |
| `renpy.confirm(message)` | `message` | ✅ RPYC, ❌ Parser |
| `renpy.say(who, what)` | `what` | ✅ RPYC, ❌ Parser |
| `renpy.input(prompt, ...)` | `prompt` (dolaylı) | ✅ RPYC, ⚠️ Parser regex |
| `Confirm(prompt, yes, no)` | `prompt` | ✅ RPYC, ✅ Parser |
| `Notify(message)` | `message` | ✅ RPYC, ✅ Parser |
| `Tooltip(default)` / `tt.Action(value)` | `default`, `value` | ✅ RPYC, ❌ Parser |
| `MouseTooltip(value)` | `value` (string ise) | ✅ RPYC, ❌ Parser |
| `Character(name, ...)` | `name` | ✅ RPYC, ✅ Parser |
| `Text(text)` displayable | `text` | ✅ RPYC regex, ⚠️ Parser kısmi |
| `ui.text(text)` | `text` | ✅ RPYC, ❌ Parser |
| `ui.textbutton(text)` | `text` | ✅ RPYC, ❌ Parser |
| `achievement.register(name, ...)` | `name` + keyword | ✅ RPYC, ❌ Parser |
| `narrator(what)` | `what` | ❌ Hiçbiri (Character proxy) |
| `renpy.display_menu(items)` | tuple[0] her item | ❌ Hiçbiri |

### 4.2 Tier-2: Bağlamsal Metin İçerebilen (Orta Öncelik)

| Fonksiyon / Sınıf | Metin Parametresi | Not |
|---|---|---|
| `QuickSave(message=...)` | `message` | Varsayılan: "Quick save complete." |
| `CopyToClipboard(s)` | `s` | Kullanıcıya gösterilen metin olabilir |
| `Help(help=...)` | `help` | Label adı veya dosya adı — dikkatli filtre |
| `FilePageNameInputValue(pattern, auto, quick)` | `pattern`, `auto`, `quick` | Sayfa isimleri |
| `FileTime(format=...)` | `format` | Zaman formatı (genelde çevrilmez) |
| `config.name` | değer | Oyun adı — çevrilebilir |
| `config.version` | değer | ❌ Çevrilmemeli |
| `config.window_title` | değer | Çevrilebilir |
| `gui.about` | değer | Genelde `_()` ile sarılı |
| `Preference(name, value)` | `name` ilk arg | ❌ Çevrilmemeli (API anahtarı) |

### 4.3 Tier-3: Çevrilmemesi Gereken (Kara Liste)

| Fonksiyon | Parametreler | Sebep |
|---|---|---|
| `OpenURL(url)` | URL | Bozulur |
| `Jump(label)` | Label adı | Kod referansı |
| `Call(label)` | Label adı | Kod referansı |
| `Show(screen)` | Screen adı | Kod referansı |
| `Hide(screen)` | Screen adı | Kod referansı |
| `Play(channel, file)` | Audio dosya | Dosya yolu |
| `Queue(channel, file)` | Audio dosya | Dosya yolu |
| `SetVariable(name, value)` | Değişken adı | Kod referansı |
| `FileLoad/FileSave(name)` | Slot adı | Teknik |
| `Preference("display", ...)` | Her iki arg | API anahtarı |
| `config.save_directory` | Yol | Dosya sistemi |
| `config.keymap` | Dict | Tuş eşlemeleri |

---

## 🧠 5. Deep Extraction Tasarımı

### 5.1 Mimari Genel Bakış

```
                    ┌──────────────────────┐
                    │   Deep Extraction    │
                    │    Orchestrator      │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼──────┐ ┌──────▼───────┐ ┌──────▼──────┐
     │ Parser Deep   │ │ RPYC Deep    │ │  Shared     │
     │ Extractor     │ │ Extractor    │ │  Filters    │
     │ (.rpy files)  │ │ (.rpyc files)│ │  & Config   │
     └────────┬──────┘ └──────┬───────┘ └──────┬──────┘
              │                │                │
     ┌────────▼──────────────────────────────────▼──────┐
     │              DeepExtractionConfig                │
     │  ┌──────────────┐  ┌──────────────────────────┐  │
     │  │ API Registry │  │ Variable Name Heuristics │  │
     │  │ (Tier 1/2/3) │  │ (Whitelist + Blacklist)  │  │
     │  └──────────────┘  └──────────────────────────┘  │
     └──────────────────────────────────────────────────┘
```

### 5.2 Yeni Modül: `src/core/deep_extraction.py`

Bu modül, parser ve RPYC reader'ın **ortak kullanacağı** derin çıkarma mantığını barındırır:

```python
# src/core/deep_extraction.py — Taslak API

class DeepExtractionConfig:
    """Derin çıkarma için merkezi yapılandırma."""
    
    # Tier-1: Bu fonksiyon çağrılarından STRİNG argümanları her zaman çıkar
    TIER1_TEXT_CALLS = {
        # func_name: [pozisyonel_indeks_listesi] veya keyword argüman adları
        "renpy.notify":        {"pos": [0]},
        "renpy.confirm":       {"pos": [0]},
        "renpy.say":           {"pos": [1]},  # what parametresi
        "renpy.input":         {"kw": ["prompt", "default"]},
        "renpy.display_notify":{"pos": [0]},
        "Confirm":             {"pos": [0]},           # prompt
        "Notify":              {"pos": [0]},           # message
        "Tooltip":             {"pos": [0]},           # default value
        "MouseTooltip":        {"pos": [0]},
        "Character":           {"pos": [0]},           # name
        "Text":                {"pos": [0]},
        "ui.text":             {"pos": [0]},
        "ui.textbutton":       {"pos": [0]},
        "achievement.register":{"pos": [0], "kw": ["stat_name"]},
        "narrator":            {"pos": [0]},
        "QuickSave":           {"kw": ["message"]},
        "CopyToClipboard":     {"pos": [0]},
    }
    
    # Tier-2: Bağlam kontrolü ile çıkar (değişken adı ipucu gerekir)
    TIER2_CONTEXTUAL = {
        "FilePageNameInputValue": {"kw": ["pattern", "auto", "quick"]},
        "Help":                   {"pos": [0]},  # Sadece string ise, label değilse
    }
    
    # Tier-3: ASLA çıkarma — false positive kara listesi
    TIER3_BLACKLIST_CALLS = {
        "OpenURL", "Jump", "Call", "Show", "Hide", "ShowTransient",
        "ToggleScreen", "Play", "Queue", "Stop", "SetVariable",
        "ToggleVariable", "SetField", "SetDict", "SetScreenVariable",
        "SetLocalVariable", "FileLoad", "FileSave", "FileDelete",
        "FilePage", "FilePageNext", "FilePagePrevious",
        "Preference",  # İlk arg API anahtarı, çevrilmemeli
        "renpy.jump", "renpy.call", "renpy.show", "renpy.hide",
        "renpy.scene", "renpy.play", "renpy.music.play",
        "renpy.music.queue", "renpy.music.stop",
    }
    
    # Define/Default değişken adı sezgiselleri
    # Bu prefix/suffix'ler, bir bare string'in çevrilebilir olduğunu gösterir
    TRANSLATABLE_VAR_HINTS = {
        "prefixes": [
            "title", "name", "label", "desc", "description", "text",
            "message", "msg", "greeting", "dialogue", "prompt",
            "tooltip", "hint", "quest", "objective", "chapter",
            "status", "note", "about", "caption", "header",
            "subtitle", "credit", "intro", "outro", "warning",
        ],
        "suffixes": [
            "_title", "_name", "_label", "_desc", "_description",
            "_text", "_message", "_msg", "_greeting", "_dialogue",
            "_prompt", "_tooltip", "_hint", "_quest", "_note",
            "_caption", "_header", "_subtitle",
        ],
        "exact": [
            "who", "what", "save_name", "about", "greeting",
        ],
    }
    
    # Define/Default çevrilMEMESİ gereken değişken adı ipuçları
    NON_TRANSLATABLE_VAR_HINTS = {
        "prefixes": [
            "config.", "persistent.", "style.", "_",
            "audio.", "sound.", "music.", "voice.",
            "image", "layer", "transform", "transition",
        ],
        "suffixes": [
            "_path", "_file", "_dir", "_url", "_image", "_img",
            "_icon", "_sound", "_sfx", "_music", "_voice",
            "_audio", "_font", "_style", "_color", "_alpha",
            "_size", "_pos", "_xpos", "_ypos", "_delay",
        ],
        "exact": [
            "version", "save_directory", "window_icon",
        ],
    }


class DeepVariableAnalyzer:
    """Değişken adı sezgisel analizörü."""
    
    def is_likely_translatable(self, var_name: str) -> bool:
        """Değişken adının çevrilebilir metin taşıma olasılığını değerlendirir."""
        # 1. Kesin kara liste kontrolü
        # 2. Kesin beyaz liste kontrolü
        # 3. Prefix/suffix tabanlı sezgisel karar
        # 4. Bilinmez → kullanıcı ayarına bağlı (varsayılan: False = güvenli)
        pass
    
    def classify_define_default(self, var_name: str, value_code: str) -> str:
        """
        Bir define/default ifadesini sınıflandırır.
        Returns: "translatable" | "non_translatable" | "uncertain"
        """
        pass


class FStringReconstructor:
    """
    Parser (.rpy) tarafında f-string'leri yeniden oluşturur.
    RPYC reader'ın visit_JoinedStr mantığının parser eşdeğeri.
    """
    
    def extract_fstring_template(self, fstring_code: str) -> str | None:
        """
        f"Welcome {name}, you have {count} items"
        →  "Welcome [name], you have [count] items"
        
        Çevrilebilir metin varsa şablonu döndürür, yoksa None.
        """
        pass
```

### 5.3 Parser Geliştirmeleri (`src/core/parser.py`)

#### 5.3.1 Yeni Regex Pattern'ler

```python
# --- Bare Define Pattern (Gap-P1) ---
# Captures: define my_var = "text" (any namespace, not just gui/config)
bare_define_string_re = re.compile(
    r'^\s*define\s+'
    r'(?:(?:-?\d+)\s+)?'           # opsiyonel priority
    r'(?P<var_name>[\w.]+)\s*'     # değişken adı
    r'=\s*'                        # atama operatörü
    r'(?P<quote>["\'])(?P<text>.+?)(?P=quote)'  # string değer
    r'\s*$',
    re.IGNORECASE
)

# --- Bare Default Pattern (Gap-P2) ---
# Captures: default var = "text" (without _() wrapper)
bare_default_string_re = re.compile(
    r'^\s*default\s+'
    r'(?P<var_name>[\w.]+)\s*'     # değişken adı
    r'=\s*'
    r'(?P<quote>["\'])(?P<text>.+?)(?P=quote)'
    r'\s*$',
    re.IGNORECASE
)

# --- Python Call Pattern (Gap-P5) ---
# Captures: $ renpy.confirm("text"), $ narrator("text"), etc.
python_text_call_re = re.compile(
    r'^\s*\$\s*'
    r'(?P<func>(?:renpy\.(?:confirm|say|display_notify|display_menu)|narrator))'
    r'\s*\(\s*'
    r'(?:[^,]*,\s*)?'             # opsiyonel ilk arg (who için)
    r'(?P<quote>["\'])(?P<text>.+?)(?P=quote)',
    re.IGNORECASE
)

# --- f-string Pattern (Gap-P4) ---
# Captures: $ var = f"text {expr} more text"
fstring_assign_re = re.compile(
    r'^\s*\$?\s*'
    r'(?:(?:define|default)\s+)?'
    r'[\w.]+\s*=\s*'
    r'f(?P<quote>["\'])(?P<content>.+?)(?P=quote)',
    re.IGNORECASE
)

# --- Screen Tooltip Property (Gap-P6) ---
# Captures: tooltip "text" in screen language
tooltip_property_re = re.compile(
    r'\btooltip\s+(?P<quote>["\'])(?P<text>.+?)(?P=quote)',
    re.IGNORECASE
)
```

#### 5.3.2 Çok Satırlı Yapı Ayrıştırma (Gap-P3)

```python
class MultiLineStructureParser:
    """
    Çok satırlı dict/list define/default blokları için AST tabanlı ayrıştırıcı.
    
    Kullanım senaryosu:
        define quest_data = {
            "title": "Dragon Slayer",
            "desc": "Kill the mighty dragon",
        }
    """
    
    def detect_multiline_start(self, line: str) -> dict | None:
        """
        Tek satırda kapanmayan define/default yapılarını tespit eder.
        Returns: {"var_name": str, "start_char": "{" | "[", "indent": int}
        """
        pass
    
    def collect_block(self, lines: list, start_idx: int, info: dict) -> str:
        """
        Başlangıç satırından itibaren dengelenmiş parantez/köşeli
        ayraç bitene kadar satırları toplar.
        """
        pass
    
    def extract_from_structure(self, var_name: str, code: str) -> list:
        """
        Toplanan kod bloğunu ast.parse ile analiz eder ve
        DATA_KEY_WHITELIST'teki key'lere karşılık gelen string
        değerlerini çıkarır.
        """
        pass
```

#### 5.3.3 f-string Parity (Gap-P4)

Parser'a RPYC reader'ın `visit_JoinedStr` mantığının eşdeğeri eklenir:

```python
def _extract_fstrings_from_line(self, line: str, idx: int) -> list:
    """
    f-string atamalarını tespit eder ve çevrilebilir şablonu çıkarır.
    
    Girdi:  f"Welcome back, {player_name}! Day {day}."
    Çıktı:  "Welcome back, [player_name]! Day [day]."
    
    Eğer statik metin oranı < %30 ise, çıkarma atlanır
    (tamamen dinamik f-string → çeviriye uygun değil).
    """
    pass
```

### 5.4 RPYC Reader Geliştirmeleri (`src/core/rpyc_reader.py`)

#### 5.4.1 DeepStringVisitor Genişletmeleri

```python
# visit_Call'a eklenecek yeni handler'lar:

def visit_Call(self, node):
    func_name = self._get_func_name(node)
    
    # ... mevcut handler'lar ...
    
    # YENİ: QuickSave message argümanı
    if func_name == "QuickSave":
        for kw in node.keywords:
            if kw.arg == "message" and isinstance(kw.value, ast.Constant):
                self._add_string(kw.value.value, "QuickSave.message")
    
    # YENİ: CopyToClipboard string argümanı
    if func_name == "CopyToClipboard":
        if node.args and isinstance(node.args[0], ast.Constant):
            self._add_string(node.args[0].value, "CopyToClipboard")
    
    # YENİ: FilePageNameInputValue metin argümanları
    if func_name == "FilePageNameInputValue":
        for kw in node.keywords:
            if kw.arg in ("pattern", "auto", "quick"):
                if isinstance(kw.value, ast.Constant):
                    self._add_string(kw.value.value, f"FilePageNameInputValue.{kw.arg}")
    
    # YENİ: narrator() doğrudan çağrısı
    if func_name == "narrator":
        if node.args and isinstance(node.args[0], ast.Constant):
            self._add_string(node.args[0].value, "narrator")
    
    # YENİ: renpy.display_menu item tuple'ları
    if func_name in ("renpy.display_menu",):
        if node.args and isinstance(node.args[0], ast.List):
            for elt in node.args[0].elts:
                if isinstance(elt, ast.Tuple) and elt.elts:
                    first = elt.elts[0]
                    if isinstance(first, ast.Constant) and isinstance(first.value, str):
                        self._add_string(first.value, "display_menu.caption")
    
    # Tier-3 Kara Liste kontrolü
    if func_name in DeepExtractionConfig.TIER3_BLACKLIST_CALLS:
        return  # Bu çağrının argümanlarını atla
    
    self.generic_visit(node)
```

#### 5.4.2 Define/Default Smart Filtering Geliştirmesi

```python
def _extract_from_code_obj(self, code_str, var_name=None):
    """
    Geliştirilmiş versiyon: var_name bilgisini DeepVariableAnalyzer'a 
    geçirerek bare string'lerin çevrilebilirlik kararını iyileştirir.
    """
    analyzer = DeepVariableAnalyzer()
    
    if var_name:
        classification = analyzer.classify_define_default(var_name, code_str)
        if classification == "non_translatable":
            return []  # Atla
        # classification == "uncertain" → mevcut mantığa devam et
    
    # ... mevcut _extract_strings_from_code çağrısı ...
```

### 5.5 Yapılandırma Entegrasyonu

`config.json`'a yeni Deep Extraction ayarları:

```json
{
  "deep_extraction": {
    "enabled": true,
    "bare_define_strings": true,
    "bare_default_strings": true,
    "fstring_extraction": true,
    "multiline_structures": true,
    "tooltip_properties": true,
    "extended_api_calls": true,
    "min_static_text_ratio": 0.30,
    "uncertain_vars_strategy": "skip",
    "custom_var_whitelist": [],
    "custom_var_blacklist": []
  }
}
```

**UI entegrasyonu:** Settings panelinde "Deep Extraction" bölümü, her alt özellik için toggle switch.

---

## 🚀 6. Uygulama Planı

### Faz 1: Altyapı (Tahmini: 2-3 gün)

| # | Görev | Dosya | Öncelik |
|---|---|---|---|
| 1.1 | `DeepExtractionConfig` sınıfı oluştur | `src/core/deep_extraction.py` (yeni) | Yüksek |
| 1.2 | `DeepVariableAnalyzer` sınıfı oluştur | `src/core/deep_extraction.py` | Yüksek |
| 1.3 | Config.json'a deep_extraction bölümü ekle | `config.json` | Orta |
| 1.4 | Test dosyası oluştur | `tests/test_deep_extraction.py` (yeni) | Yüksek |

### Faz 2: Parser Geliştirmeleri (Tahmini: 3-4 gün)

| # | Görev | Dosya | Boşluk |
|---|---|---|---|
| 2.1 | `bare_define_string_re` pattern + entegrasyon | `parser.py` | Gap-P1 |
| 2.2 | `bare_default_string_re` pattern + entegrasyon | `parser.py` | Gap-P2 |
| 2.3 | `MultiLineStructureParser` sınıfı | `parser.py` veya `deep_extraction.py` | Gap-P3 |
| 2.4 | `_extract_fstrings_from_line()` metodu | `parser.py` | Gap-P4 |
| 2.5 | `python_text_call_re` pattern + entegrasyon | `parser.py` | Gap-P5 |
| 2.6 | `tooltip_property_re` pattern + entegrasyon | `parser.py` | Gap-P6 |
| 2.7 | Pattern'leri `pattern_registry`'ye entegre et | `parser.py` | Tümü |

### Faz 3: RPYC Reader Geliştirmeleri (Tahmini: 2 gün)

| # | Görev | Dosya | Boşluk |
|---|---|---|---|
| 3.1 | `visit_Call` genişletmeleri (QuickSave, CopyToClipboard vb.) | `rpyc_reader.py` | Gap-R1 |
| 3.2 | `_extract_from_code_obj` smart filtering | `rpyc_reader.py` | Gap-R2 |
| 3.3 | Named store desteği | `rpyc_reader.py` | Gap-R3 |
| 3.4 | Tier-3 kara liste entegrasyonu | `rpyc_reader.py` | Tümü |

### Faz 4: Test & Doğrulama (Tahmini: 2 gün)

| # | Görev |
|---|---|
| 4.1 | Her boşluk için birim testi (en az 3 test/boşluk) |
| 4.2 | Yanlış pozitif regresyon testleri |
| 4.3 | Gerçek oyun projelerinde entegrasyon testi (MysteryOfMilfs, MadAdventure) |
| 4.4 | Performans benchmark (büyük projelerde çıkarma süresi) |

### Faz 5: Dokümantasyon & Yayın (Tahmini: 1 gün)

| # | Görev |
|---|---|
| 5.1 | Advanced-Parsing.md güncellemesi |
| 5.2 | CHANGELOG.md v2.7.1 bölümü |
| 5.3 | Settings UI referansı güncellemesi |

---

## 🛡 7. Yanlış Pozitif Önleme Stratejisi

### 7.1 Çok Katmanlı Filtreleme

```
Çıkarılan String
     │
     ▼
[1. Mevcut is_meaningful_text() filtresi]
     │ Geçti?
     ▼
[2. Teknik String Dedektörü]
     │ Geçti?
     ▼
[3. Değişken Adı Sezgisel Analiz]
     │ Geçti?
     ▼
[4. Minimum Statik Metin Oranı (%30)]
     │ Geçti?
     ▼
[5. Tier-3 Kara Liste Kontrolü]
     │ Geçti?
     ▼
     ✅ Çevrilebilir metin olarak kabul et
```

### 7.2 Teknik String Dedektörü Genişletmeleri

Mevcut filtrelere ek olarak:

```python
TECHNICAL_PATTERNS = [
    # Dosya yolları (uzantılı)
    r'.*\.(rpy|rpyc|rpymc|png|jpg|webp|ogg|mp3|wav|ttf|otf|json|txt)$',
    # Ren'Py internal referanslar
    r'^(screens?|master|transient|overlay|top|bottom)$',
    # Python modül/sınıf isimleri
    r'^[a-z_]+\.[a-z_]+\.[a-z_]+',  # three.dot.qualified.names
    # Renk kodları
    r'^#[0-9a-fA-F]{3,8}$',
    # Sayısal değerler
    r'^\d+(\.\d+)?$',
    # Tek karakter
    r'^.$',
    # Boşluk ve kontrol karakterleri sadece
    r'^\s*$',
    # Değişken placeholder'lar (tamamen dinamik)
    r'^\[[\w.]+\]$',
    r'^\{[\w.]+\}$',
]
```

### 7.3 Değişken Adı Sezgisel Skoru

```python
def _score_var_name(self, var_name: str) -> float:
    """
    Bir değişken adının çevrilebilir metin taşıma olasılığını 0.0-1.0 arasında puanlar.
    
    Örnekler:
        "quest_title"        → 0.95  (suffix _title → yüksek)
        "player_hp"          → 0.05  (suffix _hp → düşük)
        "config.name"        → 0.80  (config.name whitelist'te)
        "persistent.flags"   → 0.02  (persistent prefix → çok düşük)
        "gui.text_size"      → 0.10  (gui prefix ama _size suffix → düşük)
        "chapter_names"      → 0.85  (suffix _names + "chapter" prefix)
    """
    score = 0.5  # Nötr başlangıç
    
    # Prefix kontrolü
    for prefix in DeepExtractionConfig.TRANSLATABLE_VAR_HINTS["prefixes"]:
        if var_name.startswith(prefix) or f".{prefix}" in var_name:
            score += 0.3
            break
    
    for prefix in DeepExtractionConfig.NON_TRANSLATABLE_VAR_HINTS["prefixes"]:
        if var_name.startswith(prefix):
            score -= 0.4
            break
    
    # Suffix kontrolü
    for suffix in DeepExtractionConfig.TRANSLATABLE_VAR_HINTS["suffixes"]:
        if var_name.endswith(suffix):
            score += 0.3
            break
    
    for suffix in DeepExtractionConfig.NON_TRANSLATABLE_VAR_HINTS["suffixes"]:
        if var_name.endswith(suffix):
            score -= 0.4
            break
    
    return max(0.0, min(1.0, score))
```

### 7.4 Güvenli Varsayılan Davranış

| Durum | Davranış | Gerekçe |
|---|---|---|
| Yüksek skor (≥ 0.7) | ✅ Çıkar | Muhtemelen çevrilebilir |
| Orta skor (0.3 - 0.7) | ⚠️ Flag ile çıkar | Kullanıcı onayı gerekebilir |
| Düşük skor (< 0.3) | ❌ Atla | Muhtemelen teknik |
| `uncertain_vars_strategy: "include"` | Tüm orta skorlu dahil | Agresif mod |
| `uncertain_vars_strategy: "skip"` | Tüm orta skorlu hariç | Güvenli mod (varsayılan) |

---

## 🧪 8. Test Matrisi

### 8.1 Boşluk Bazlı Test Senaryoları

```python
# tests/test_deep_extraction.py

class TestBareDefineExtraction:
    """Gap-P1: Bare define string tespiti."""
    
    def test_simple_define_string(self):
        """define quest_title = "The Dark Forest" → çıkarılmalı"""
    
    def test_define_with_priority(self):
        """define -1 title = "My Game" → çıkarılmalı"""
    
    def test_define_config_name(self):
        """define config.name = "Game" → çıkarılmalı (mevcut + yeni)"""
    
    def test_define_technical_var_skipped(self):
        """define audio_volume = "0.5" → atlanmalı (teknik)"""
    
    def test_define_path_var_skipped(self):
        """define save_path = "/saves" → atlanmalı (dosya yolu)"""


class TestBareDefaultExtraction:
    """Gap-P2: Bare default string tespiti."""
    
    def test_simple_default_string(self):
        """default player_name = "Hero" → çıkarılmalı"""
    
    def test_default_with_underscore_func(self):
        """default name = _("Hero") → zaten yakalanıyor, duplikat olmamalı"""
    
    def test_default_store_syntax(self):
        """default mystore.greeting = "Hello" → çıkarılmalı"""


class TestMultiLineStructures:
    """Gap-P3: Çok satırlı veri yapıları."""
    
    def test_dict_with_whitelisted_keys(self):
        """define data = {"title": "X", "id": 5} → sadece "title" çıkarılmalı"""
    
    def test_list_of_strings(self):
        """define names = ["Alice", "Bob"] → çıkarılmalı"""
    
    def test_nested_dict_list(self):
        """define quests = [{"name": "Q1"}] → "name" key'i çıkarılmalı"""


class TestFStringExtraction:
    """Gap-P4: f-string çıkarma."""
    
    def test_fstring_with_meaningful_text(self):
        """f"Welcome {name}!" → "Welcome [name]!" olarak çıkarılmalı"""
    
    def test_fstring_mostly_dynamic_skipped(self):
        """f"{a}{b}{c}" → statik metin < %30, atlanmalı"""
    
    def test_fstring_in_assignment(self):
        """$ msg = f"Day {n}: {desc}" → çıkarılmalı"""


class TestExtendedAPICalls:
    """Gap-P5 + Gap-R1: Genişletilmiş API çağrıları."""
    
    def test_renpy_confirm_parser(self):
        """$ renpy.confirm("Delete save?") → parser'da çıkarılmalı"""
    
    def test_quicksave_message_rpyc(self):
        """QuickSave(message="Saved!") → RPYC'de çıkarılmalı"""
    
    def test_narrator_direct_call(self):
        """$ narrator("And so it began.") → çıkarılmalı"""
    
    def test_display_menu_items(self):
        """renpy.display_menu([("Go left", "l"), ("Go right", "r")]) → caption'lar çıkarılmalı"""


class TestFalsePositivePrevention:
    """Yanlış pozitif regresyon testleri."""
    
    def test_jump_label_not_extracted(self):
        """Jump("start") → atlanmalı"""
    
    def test_openurl_not_extracted(self):
        """OpenURL("https://example.com") → atlanmalı"""
    
    def test_play_audio_not_extracted(self):
        """Play("music", "bgm.ogg") → atlanmalı"""
    
    def test_filepath_string_not_extracted(self):
        """define bg_image = "images/bg.png" → atlanmalı"""
    
    def test_color_hex_not_extracted(self):
        """define text_color = "#ffffff" → atlanmalı"""
    
    def test_number_string_not_extracted(self):
        """default score = "0" → atlanmalı"""
```

### 8.2 Entegrasyon Test Senaryoları

```python
class TestDeepExtractionIntegration:
    """Gerçek oyun dosyaları ile entegrasyon testleri."""
    
    def test_no_regression_on_existing_extraction(self):
        """Deep extraction, mevcut çıkarma sonuçlarını bozmamalı."""
    
    def test_no_duplicate_entries(self):
        """Aynı string hem normal hem deep extraction ile tekrar çıkarılmamalı."""
    
    def test_performance_acceptable(self):
        """1000 satırlık dosyada deep extraction < 2 saniye olmalı."""
    
    def test_config_toggle_works(self):
        """deep_extraction.enabled = false → ek çıkarma yapılmamalı."""
```

---

## 📊 Beklenen Etki

| Metrik | v2.7.0 (Önceki) | v2.7.1 (Deep Extraction) |
|---|---|---|
| `define` bare string kapsamı | ~%15 | ~%85 |
| `default` bare string kapsamı | ~%5 | ~%80 |
| f-string kapsamı (.rpy) | %0 | ~%70 |
| Karmaşık veri yapıları | ~%10 | ~%65 |
| Ren'Py API çağrı kapsamı | ~%60 | ~%90 |
| Tahmini yanlış pozitif oranı | ~%2 | ~%4 (kabul edilebilir) |
| Ekstra çıkarma süresi | 0ms | ~200ms / 1000 satır |

---

## 🔗 İlgili Dokümanlar

- [Advanced Parsing](Advanced-Parsing.md) — Mevcut 4 katmanlı mimari açıklaması
- [Technical Filtering](Technical-Filtering.md) — Teknik string filtreleme kuralları
- [Developer Guide](Developer-Guide.md) — Katkı kılavuzu
- [Output Formats](Output-Formats.md) — Çıktı formatları ve TextType sabitleri
