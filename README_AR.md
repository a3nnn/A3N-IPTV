# A3N IPTV Player — نسخة الكمبيوتر (Windows)

## أول مرة فقط: تجهيز الجهاز

1. **ثبّت Flutter**
   من هنا: https://docs.flutter.dev/get-started/install/windows
   (نزّل الملف المضغوط، فكّه في `C:\flutter`، وأضف `C:\flutter\bin` إلى متغير PATH)

2. **ثبّت Visual Studio 2022 Community** (مجاني)
   وأثناء التثبيت اختر: **Desktop development with C++**

3. **فعّل Developer Mode في ويندوز**
   افتح Run (زر Win + R) واكتب: `ms-settings:developers` وشغّل الخيار.

4. افتح Command Prompt واكتب:
   ```
   flutter doctor
   ```
   لازم يطلع ✓ عند Flutter و Visual Studio و Windows.

## تغيير الهوست والاسم والألوان

كل الإعدادات في ملف واحد: **`lib/config.dart`**

```dart
static const String host = 'http://your-host.com:8080';
```

غيّر الرابط لهوست الـ Xtream حقك، واحفظ الملف. وفي نفس الملف تقدر تغيّر:
- `appName` — اسم التطبيق
- `signature` — التوقيع اللي يطلع فوق يسار
- `primary` و `accent` — الألوان (بصيغة `0xFF` + كود اللون، مثال `0xFF00C2A8`)

بعد أي تعديل، أعد البناء.

## البناء

دبل كليك على **`build_windows.bat`**
أول مرة ياخذ عدة دقائق لأنه ينزّل مكتبات التشغيل. بعد ما يخلص، يفتح لك مجلد:

```
build\windows\x64\runner\Release
```

هذا هو التطبيق. انسخ **المجلد كامل** (مو بس ملف exe) لأي جهاز ويندوز وشغّل `a3n_iptv_player.exe`.

للتجربة أثناء التعديل استخدم `run_debug.bat`.

## الاستخدام

- **Live TV:** اختر الفئة ← القناة تشتغل في المعاينة. اضغط عليها مرة ثانية أو دبل كليك على الفيديو للشاشة الكاملة.
- **في الشاشة الكاملة:** ▲ ▼ لتغيير القناة، Enter لعرض المعلومات، Esc للخروج.
- **النجمة** جنب القناة تضيفها للمفضلة.
- التطبيق يتذكر آخر قناة ويرجع لها عند الفتح.

## إذا صار خطأ

- **فشل البناء:** شغّل `flutter doctor` وأرسل لي النتيجة، أو انسخ لي آخر 30 سطر من الخطأ.
- **القنوات ما تشتغل:** جرّب في `config.dart` تغيّر `liveFormat` إلى `'m3u8'`، أو غيّر `userAgent` إلى `'VLC/3.0.20 LibVLC/3.0.20'`.
