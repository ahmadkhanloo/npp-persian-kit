# کیت فارسی‌سازی Notepad++ (بدون نیاز به ادمین)

این پوشه همان چیزی است که پلاگین `PersianKit` را کامل می‌کند: فونت، تنظیمات ادیتور و استایل **پیش‌نمایش RTL** مارک‌داون.

## چه چیزهایی را تغییر می‌دهد؟

| # | مورد | جزئیات |
|---|---|---|
| ۱ | فونت | نصب **Vazirmatn** (۵ وزن) برای کاربر جاری از پوشهٔ `fonts/` |
| ۲ | `config.xml` | خاموش‌کردن **DirectWrite** (پیش‌نیاز راست‌چین‌شدن) + روشن‌کردن **Word wrap** |
| ۳ | `stylers.xml` | رنگ‌بندی تازهٔ **JSON** (کلید آبی، رشته قرمز، عدد سبز) با Consolas 11 |
| ۴ | `userDefineLangs\markdown*.udl.xml` | فونت ویرایشگر Markdown → **Vazirmatn** |
| ۵ | `plugins\config\persian-markdown*.css` | CSS فارسی پنل **Markdown Panel**: RTL کامل، تیتر/جدول/لیست راست‌چین، بلوک کد LTR، نسخهٔ روشن و دارک |
| ۶ | `plugins\config\NppMarkdownPanel.ini` | CSS فارسی + Zoom + باز شدن خودکار پیش‌نمایش برای `md`/`txt` |

## JSON: رنگ‌بندی تازه + فولد

فقط بلوک زبان `json` در `stylers.xml` عوض می‌شود (تم و بقیهٔ زبان‌ها دست‌نخورده می‌مانند) و نسخهٔ قبلی به‌صورت `stylers.xml.bak-<تاریخ>` بکاپ می‌شود:

| توکن | رنگ | چرا |
|---|---|---|
| نام کلید `"key":` | `#0451A5` پررنگ | ساختار سریع دیده می‌شود |
| رشته | `#A31515` | جایگزین `#800000` کدر |
| عدد | `#098658` | جایگزین `#FF8000` که شبیه خطا بود |
| `true` / `false` / `null` | `#0000C0` پررنگ | یک رنگ واحد برای همهٔ لیترال‌ها |
| escape | `#D12F1B` | |
| URI/IRI | `#0451A5` | |
| توکن نامعتبر | سفید روی `#E45649` | خطا واقعاً دیده می‌شود |
| کامنت `//` و `/* */` | `#008000` ایتالیک | |

به‌علاوه: فونت **Consolas 11** برای کل زبان JSON، ستون **فولد** فعال (باز/بسته‌کردن شاخه‌ها و `View ▸ Fold All`)، و نوار وضعیت زبان را `JSON file` نشان می‌دهد.

**برگشت به قبل:** فایل `stylers.xml.bak-<تاریخ>` را روی `stylers.xml` کپی کن.
**تغییر رنگ دلخواه:** `Settings ▸ Style Configurator ▸ Language: json`.
**تودرتوی JSON:** هر لایه یک پله جلو می‌رود؛ اگر فایل روی «Tab» باشد هر لایه یک TAB، وگرنه `JsonIndentWidth` فاصله (پیش‌فرض ۲) — از `plugins\config\NppPersianKit.ini` قابل تغییر است.
**نمای درختی JSON؟** پلاگین رسمی **JSON Tools** را از `Plugins ▸ Plugins Admin` نصب کن.

## پیش‌نیازها

1. **Notepad++ 8.9+**
2. برای **پیش‌نمایش** مارک‌داون: پلاگین `Plugins ▸ Plugins Admin ▸ "Markdown Panel" ▸ Install`
3. برای **راست‌چین‌شدن با پلاگین**: `PersianKit.dll` را هم نصب کنید (پوشهٔ `src/` و `build/` در همین مخزن) یا از `Ctrl+Alt+R` بومی Notepad++ استفاده کنید.

## نصب

1. **Notepad++ را ببندید.**
2. روی `install.cmd` دوبار کلیک کنید.
3. Notepad++ را باز کنید؛ در یک فایل فارسی، `Ctrl+Alt+R` (یا منوی `Plugins ▸ PersianKit ▸ Persian mode`).

## رفع اشکال

| مشکل | راه‌حل |
|---|---|
| «Cannot run RTL / RTL is not compatible with DirectWrite» | `config.xml` پچ نشده یا Notepad++ ری‌استارت نشده |
| متن پیش‌نمایش ریز/بزرگ است | `Plugins ▸ MarkdownPanel ▸ Settings ▸ Zoom Level` |
| پیش‌نمایش فارسی نیست | در همان Settings، `CSS File` را روی `...\plugins\config\persian-markdown.css` بگذارید |
| لاتین‌ها هم وزیرمتن‌اند | در ادیتور طبیعی است (هر استایل یک فونت دارد). در پیش‌نمایش هم چون کل استایل روی Vazirmatn است، همه‌چیز وزیرمتن است |

## برگشت به حالت قبل

هر فایل تغییرکرده کنار خودش با `*.bak-<تاریخ>` ذخیره شده است؛ فونت‌ها از
`%LOCALAPPDATA%\Microsoft\Windows\Fonts` و کلید رجیستری `HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` حذف شوند.
