<div align="center">

```
██████╗ ███████╗██████╗
██╔══██╗██╔════╝██╔══██╗
██████╔╝█████╗  ██║  ██║
██╔══██╗██╔══╝  ██║  ██║
██║  ██║███████╗██████╔╝
═╝  ╚═╝╚══════╝╚═════╝
~~~

# 🔴 RED — اسکنر IP تمیز کلادفلر (Termux)

**ابزار پیدا کردن تمیزترین، سریع‌ترین و پایدارترین IP های کلادفلر — مستقیم در ترموکس اندروید**

[![English](https://img.shields.io/badge/🌐_Read_in-English-2563eb?style=for-the-badge)](README.en.md)
[![Telegram](https://img.shields.io/badge/✈️-RedProjectX-229ED9?style=for-the-badge&logo=telegram)](https://t.me/RedProjectX)
[![Version](https://img.shields.io/badge/نسخه-v11-red?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)]()

</div>

---

## 🚀 نصب تک‌دستوری (پیشنهادی)

فقط این یک خط رو در Termux وارد کن:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codewave4/Scanner/main/cfscan.sh)
```

## 📦 نصب دستی

```bash
pkg update -y && pkg install -y curl gawk grep coreutils unzip
curl -so cfscan.sh https://raw.githubusercontent.com/codewave4/Scanner/main/cfscan.sh
chmod +x cfscan.sh
./cfscan.sh
```

---

## ✨ ویژگی‌ها (v11)

| ویژگی | توضیح |
|---|---|
| 🌐 **Round-Robin هر ۱۲ رنج** | همه رنج‌های رسمی کلادفلر به‌طور مساوی تست می‌شن |
| 📶 **TCPing ×۴** | هر IP چهار بار پینگ TCP می‌شه (Loss / Delay / Jitter) |
| 🔌 **تست چند پورت** | ۴۴۳ / ۲۰۵۳ / ۲۰۸۳ / ۸۴۴۳ + پیشنهاد بهترین پورت |
| ⚡ **سرعت واقعی DL/UL** | تست دانلود/آپلود سبک برای ۱۰ IP برتر |
| ⭐ **تأیید Xray** | تست واقعی با هسته Xray و کانفیگ خودت (اختیاری) |
| 🏆 **رتبه‌بندی بهترین-اول** | مرتب‌سازی بر اساس Loss + Delay + Jitter + سرعت |
| 💾 **ادامه اسکن (Resume)** | IPهای تست‌شده تا ۶ ساعت رد می‌شن |
| 🛑 **Ctrl+C هوشمند** | توقف در هر لحظه + نمایش نتایج تا اون لحظه |
| 🟢 **نمایش زنده** | IPهای تمیز همون لحظه سبز چاپ می‌شن |

---

## 🎮 راهنمای استفاده

| سوال | پیش‌فرض | توضیح |
|---|---|---|
| Select [1/2/3] | — | ۱=تصادفی ۲=رنج سفارشی ۳=فایل IP |
| Number of IPs | 100 | تعداد IP برای اسکن |
| TCPing per IP | 4 | تکرار پینگ (دقت بیشتر) |
| Scan port | 443 | پورت اسکن |
| Multi-port test | y | تست ۴ پورت برای برترها |
| Real DL/UL speed | y | تست سرعت واقعی (~۷MB هر IP) |
| Xray verify | n | تأیید با هسته Xray |
| Concurrency | 20 | اتصال همزمان |

---

## 📊 خروجی

~~~
RANK IP               PORT   LOSS   DELAY    JIT     DOWN   UP     SCORE
1.   188.114.99.62    2083   25%    175ms    251ms   0.00   0.00   61.4
2.   188.114.99.144   2053   25%    174ms    1060ms  0.00   0.00   53.7
~~~

- 🟢 **سبز** = امتیاز ≥ ۶۰ → ذخیره در `~/cf_clean_ips.txt` (بهترین اول)
- ⭐ = تأییدشده با Xray

---

## 💡 نکته‌ها

- تست سرعت برای هر IP برتر ~۷MB مصرف می‌کنه؛ اگه نت محدوده جواب `n` بده
- حالت Xray بار اول هسته رو دانلود می‌کنه (~۲۵MB) و فقط با کانفیگ **vless/TLS** کار می‌کنه
- Jitter پایین‌تر = اتصال پایدارتر، حتی اگه Delay کمی بیشتر باشه

---

## 🔗 لینک‌ها

- ✈️ تلگرام: [@RedProjectX](https://t.me/RedProjectX)
- 📱 کلاینت پیشنهادی: [PattNG](https://github.com/patterniha/PattNG/releases)

<div align="center">

**ساخته‌شده با ❤️ برای دور زدن محدودیت‌ها**

</div>
