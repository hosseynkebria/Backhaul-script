# Backhaul Script

این مخزن یک اسکریپت تعاملی برای راه‌اندازی **Backhaul** به‌صورت سرور یا کلاینت ارائه می‌دهد. اسکریپت قابلیت‌های زیر را پوشش می‌دهد:

- منوی تعاملی برای انتخاب حالت سرور/کلاینت
- انتخاب پروتکل برای هر سمت
- ساخت سرویس systemd
- ری‌استارت سرویس
- انتخاب پورت‌ها و بازه پورت‌های تونل
- توکن پیش‌فرض قابل تغییر
- افزایش تعداد تونل‌ها و بازه پورت تونل
- پشتیبانی از IPv6 با امکان تعیین آدرس Bind

> نکته: به‌دلیل تفاوت نسخه‌های Backhaul، ممکن است لازم باشد آرگومان‌ها را در اسکریپت با CLI نسخه مورد استفاده خودتان هماهنگ کنید.

## پیش‌نیاز

1. فایل اجرایی Backhaul را در مسیر زیر قرار دهید و executable کنید:
   ```bash
   sudo install -m 755 /path/to/backhaul /usr/local/bin/backhaul
   ```

2. اجرای سریع با یک خط دستور (دانلود و اجرای مستقیم منو):
   ```bash
   sudo bash <(curl -Ls https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/Backhaul-script/main/backhaul-menu.sh)
   ```

3. اجرای اسکریپت به‌صورت دستی با دسترسی روت (بعد از دانلود):
   ```bash
   sudo ./backhaul-menu.sh
   ```

## ساخت سرویس

اسکریپت بعد از تنظیمات، سرویس‌های زیر را می‌سازد:

- `backhaul-server.service`
- `backhaul-client.service`

برای ری‌استارت:
```bash
sudo systemctl restart backhaul-server
```

## نکات مهم

- آدرس Bind برای IPv6 را `::` وارد کنید.
- بازه پورت تونل از `start` تا `end` محاسبه می‌شود.
- تنظیمات در `/etc/backhaul/*.env` ذخیره می‌شوند.

## ساختار فایل‌ها

- `backhaul-menu.sh`: اسکریپت اصلی منو.
- `/etc/backhaul/server.env`: تنظیمات سرور.
- `/etc/backhaul/client.env`: تنظیمات کلاینت.
