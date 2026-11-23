# Android platform

این پوشه شامل فایل‌های Gradle، تنظیمات اپلیکیشن اندروید، Manifest و MainActivity برای DayFlow است.
Flutter SDK در زمان اجرای build مسیر SDK را از `android/local.properties` دریافت می‌کند؛ این فایل
محلی و وابسته به ماشین است و نباید در Git ذخیره شود. GitHub Actions باید Flutter را نصب کند و
مستقیماً `flutter pub get` و `flutter build apk --release` را اجرا کند.
