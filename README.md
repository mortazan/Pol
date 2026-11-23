# DayFlow

اپلیکیشن فارسی مدیریت کارهای روزانه با Flutter.

## ساختار پروژه

```text
DayFlow-Complete/
├── .github/workflows/android.yml
├── android/
│   ├── app/src/main/AndroidManifest.xml
│   ├── app/src/main/kotlin/com/dayflow/app/MainActivity.kt
│   ├── app/build.gradle
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── gradle/wrapper/gradle-wrapper.properties
├── lib/main.dart
├── pubspec.yaml
└── README.md
```

## آپلود در GitHub و ساخت APK

1. ZIP را استخراج کنید.
2. تمام محتویات داخل پوشه `DayFlow-Complete` را در ریشه Repository آپلود کنید؛ خود پوشه اصلی را به‌عنوان زیرپوشه آپلود نکنید.
3. پوشه مخفی `.github` و کل پوشه `android` را نیز آپلود کنید.
4. بعد از Commit، به تب **Actions** بروید و workflow با نام **Build DayFlow APK** را باز کنید.
5. با هر push به شاخه `main` یا `master` بیلد خودکار اجرا می‌شود. برای اجرای دستی از **Run workflow** استفاده کنید.
6. پس از موفقیت، اجرای workflow را باز کنید و از بخش **Artifacts** فایل `DayFlow-Android-APK` را دانلود کنید.

## ساخت محلی

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

خروجی:
`build/app/outputs/flutter-apk/app-release.apk`

## امکانات MVP

- داشبورد روزانه، تقویم و شمارش کارها
- دسته‌بندی کارها
- یادداشت متنی، تصویر و ضبط یادداشت صوتی
- ذخیره محلی و نمایش کارهای عقب‌افتاده

## محدودیت‌ها

- زمان یادآور در اطلاعات کار ذخیره می‌شود، اما اعلان زمان‌بندی‌شده واقعی هنوز پیاده‌سازی نشده است.
- داده‌ها روی همان دستگاه ذخیره می‌شوند؛ همگام‌سازی ابری وجود ندارد.
- پیوست‌ها با مسیر محلی ذخیره می‌شوند.
- APK در این محیط روی دستگاه یا GitHub Actions اجرا و آزمایش نشده است؛ نتیجه واقعی را باید از اجرای workflow بررسی کرد.
- برای انتشار عمومی، باید کلید امضای release اختصاصی و امن تنظیم شود. APK خروجی فعلی با debug signing برای نصب و تست ساخته می‌شود.
