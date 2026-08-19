[![فارسی](https://img.shields.io/badge/🌐-فارسی-22c55e?style=for-the-badge)](README.md)
[![Telegram](https://img.shields.io/badge/✈️-RedProjectX-229ED9?style=for-the-badge&logo=telegram)](https://t.me/RedProjectX)
[![Version](https://img.shields.io/badge/Version-v11-red?style=for-the-badge)](cfscan.sh)

```
██████╗ ███████╗██████╗
██╔══██╗██╔════╝██╔══██╗
██████╔╝█████╗  ██║  ██║
██╔══██╗██╔══╝  ██║  ██║
██║  ██║███████╗██████╔╝
═╝  ╚═╝╚══════╝╚═════╝
```

# 🔴 RED — Cloudflare Clean IP Scanner (Termux)

**Find the cleanest, fastest & most stable Cloudflare IPs — right in Android Termux**

---

## 🚀 One-line Install (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codewave4/Scanner/main/cfscan.sh)
```

## 📦 Manual Install

```bash
pkg update -y && pkg install -y curl gawk grep coreutils unzip
curl -so cfscan.sh https://raw.githubusercontent.com/codewave4/Scanner/main/cfscan.sh
chmod +x cfscan.sh
./cfscan.sh
```

---

## ✨ Features (v11)

| Feature | Description |
|---|---|
| 🌐 Round-Robin all 12 ranges | Every official Cloudflare range tested equally |
| 📶 TCPing ×4 | 4 TCP pings per IP (Loss / Delay / Jitter) |
| 🔌 Multi-port test | 443 / 2053 / 2083 / 8443 + best-port suggestion |
| ⚡ Real DL/UL speed | Light download/upload test for top 10 IPs |
| ⭐ Xray verify | Real test via Xray core with your own config (optional) |
| 🏆 Best-first ranking | Sorted by Loss + Delay + Jitter + Speed |
| 💾 Resume | Recently-tested IPs skipped for 6 hours |
| 🛑 Smart Ctrl+C | Stop anytime + show results found so far |
| 🟢 Live feed | Clean IPs printed green in real time |

---

## 🎮 Usage

| Prompt | Default | Description |
|---|---|---|
| Select [1/2/3] | — | 1=random 2=custom range 3=IP file |
| Number of IPs | 100 | IPs to scan |
| TCPing per IP | 4 | Ping repetitions (accuracy) |
| Scan port | 443 | Scan port |
| Multi-port test | y | Test 4 ports on top IPs |
| Real DL/UL speed | y | Real speed test (~7MB per IP) |
| Xray verify | n | Verify via Xray core |
| Concurrency | 20 | Parallel workers |

---

## 📊 Output

~~~
RANK IP               PORT   LOSS   DELAY    JIT     DOWN   UP     SCORE
1.   188.114.99.62    2083   25%    175ms    251ms   0.00   0.00   61.4
2.   188.114.99.144   2053   25%    174ms    1060ms  0.00   0.00   53.7
```

- 🟢 Green = score ≥ 60 → saved to `~/cf_clean_ips.txt` (best first)
- ⭐ = verified via Xray

---

## 💡 Notes

- Speed test uses ~7MB per top IP; answer `n` if on limited data
- Xray mode downloads the core once (~25MB) and works with vless/TLS configs only
- Lower Jitter = more stable connection, even if Delay is slightly higher

---

## 🔗 Links

- ✈️ Telegram: [@RedProjectX](https://t.me/RedProjectX)
- 📱 Recommended client: [PattNG](https://github.com/patterniha/PattNG/releases)

**Built with ❤️ to bypass restrictions**
