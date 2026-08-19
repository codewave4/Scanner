#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════
#  اسکنر IP تمیز کلادفلر — نسخه Termux
#  تست واقعی TLS + سرعت با curl --resolve
# ═══════════════════════════════════════════════
GREEN='\033[1;32m';YELLOW='\033[1;33m';RED='\033[1;31m';CYAN='\033[1;36m';BOLD='\033[1m';NC='\033[0m'
DOMAIN="speed.cloudflare.com";PORT=443
OUT="$HOME/cf_clean_ips.txt";TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
clear
echo -e "${CYAN}${BOLD}╔════════════════════════════════════╗
║  اسکنر IP تمیز کلادفلر — Termux Edition  ║
╚════════════════════════════════════╝${NC}"

for p in curl gawk grep coreutils; do
  command -v "$p" >/dev/null 2>&1 || { echo -e "${YELLOW}نصب $p ...${NC}"; pkg install -y "$p" >/dev/null 2>&1; }
done

echo -e "${CYAN}1)${NC} اسکن تصادفی از رنج‌های کلادفلر"
echo -e "${CYAN}2)${NC} رنج سفارشی (مثلاً 198.41.223)"
echo -e "${CYAN}3)${NC} لیست IP از فایل (تک‌خطی)"
read -p "انتخاب [1/2/3]: " MODE
PREFIX="";FLIST=""
[ "$MODE" = 2 ] && read -p "پیشوند رنج (xxx.xxx.xxx): " PREFIX
[ "$MODE" = 3 ] && read -p "مسیر فایل IP ها: " FLIST
read -p "تعداد IP برای اسکن [100]: " N;N=${N:-100}
read -p "تعداد تست هر IP [3]: " TESTS;TESTS=${TESTS:-3}
read -p "تست سرعت دانلود؟ y/n [y]: " SPEED;SPEED=${SPEED:-y}
read -p "اتصال همزمان [10]: " CONC;CONC=${CONC:-10}
TIMEOUT=3

rand_ip(){
 if [ -n "$PREFIX" ]; then echo "$PREFIX.$((1+RANDOM%254))";return; fi
 case $((RANDOM%12)) in
  0) echo "104.$((16+RANDOM%8)).$((RANDOM%256)).$((1+RANDOM%254))";;
  1) echo "104.$((24+RANDOM%4)).$((RANDOM%256)).$((1+RANDOM%254))";;
  2) echo "108.162.$((192+RANDOM%64)).$((1+RANDOM%254))";;
  3) echo "131.0.$((72+RANDOM%4)).$((1+RANDOM%254))";;
  4) echo "141.101.$((64+RANDOM%64)).$((1+RANDOM%254))";;
  5) echo "162.$((158+RANDOM%2)).$((RANDOM%256)).$((1+RANDOM%254))";;
  6) echo "172.$((64+RANDOM%8)).$((RANDOM%256)).$((1+RANDOM%254))";;
  7) echo "173.245.$((48+RANDOM%16)).$((1+RANDOM%254))";;
  8) echo "188.114.$((96+RANDOM%16)).$((1+RANDOM%254))";;
  9) echo "190.93.$((240+RANDOM%16)).$((1+RANDOM%254))";;
  10) echo "197.234.$((240+RANDOM%4)).$((1+RANDOM%254))";;
  11) echo "198.41.$((128+RANDOM%128)).$((1+RANDOM%254))";;
 esac
}

test_lat(){
 local t=$(curl -s -o /dev/null -w '%{time_total}' --resolve "$DOMAIN:$PORT:$1" --max-time "$TIMEOUT" "https://$DOMAIN/cdn-cgi/trace" 2>/dev/null)
 [ -z "$t" ] && { echo FAIL;return; }
 awk -v t="$t" 'BEGIN{printf "%d", t*1000+0.5}'
}

test_speed(){
 local s=$(curl -s -o /dev/null -w '%{speed_download}' --resolve "$DOMAIN:$PORT:$1" --max-time 6 "https://$DOMAIN/__down?bytes=2000000" 2>/dev/null)
 [ -z "$s" ] && { echo 0.00;return; }
 awk -v s="$s" 'BEGIN{printf "%.2f", s/1048576}'
}

scan_ip(){
 local ip=$1 ok=0 sum=0 ms
 for i in $(seq 1 "$TESTS"); do
  ms=$(test_lat "$ip")
  if [ "$ms" != FAIL ]; then ok=$((ok+1));sum=$((sum+ms)); fi
 done
 [ $ok -eq 0 ] && return
 local loss=$(( (TESTS-ok)*100/TESTS )) avg=$((sum/ok)) spd=0.00
 if [ "$SPEED" = y ] && [ $loss -eq 0 ] && [ $avg -le 300 ]; then spd=$(test_speed "$ip"); fi
 local score=$(awk -v ok=$ok -v ts=$TESTS -v avg=$avg 'BEGIN{
   succ=ok/ts; lat=(avg<=50)?100:100-(avg-50)*0.28; if(lat<0)lat=0;
   sc=succ*60+lat*0.25+15; if(sc>100)sc=100; printf "%.1f",sc}')
 echo "$score|$ip|$avg|$loss|$spd" >> "$TMP/res"
}

: > "$TMP/res"
echo -e "${CYAN}شروع اسکن...${NC}"
if [ "$MODE" = 3 ]; then mapfile -t IPLIST < "$FLIST"; N=${#IPLIST[@]}; fi
for i in $(seq 1 "$N"); do
 if [ "$MODE" = 3 ]; then ip=${IPLIST[$((i-1))]}; else ip=$(rand_ip); fi
 printf "\r${YELLOW}اسکن: %s/%s${NC}   " "$i" "$N"
 scan_ip "$ip" &
 while [ "$(jobs -r | wc -l)" -ge "$CONC" ]; do sleep 0.2; done
done
wait
echo

if [ ! -s "$TMP/res" ]; then echo -e "${RED}هیچ IP پاسخ‌دهنده‌ای پیدا نشد${NC}"; exit 1; fi
sort -t'|' -k1,1rn "$TMP/res" > "$TMP/sorted"

echo -e "${GREEN}${BOLD}✔ نتایج (مرتب بر اساس امتیاز):${NC}"
printf "${BOLD}%-7s %-18s %-9s %-7s %-10s${NC}\n" "امتیاز" "IP" "پینگ" "لاست" "سرعتMB/s"
: > "$OUT"
while IFS='|' read -r sc ip avg loss spd; do
 if awk -v s="$sc" 'BEGIN{exit !(s>=80)}'; then color=$GREEN; echo "$ip" >> "$OUT"
 elif awk -v s="$sc" 'BEGIN{exit !(s>=60)}'; then color=$YELLOW; else color=$RED; fi
 printf "${color}%-7s %-18s %-9s %-7s %-10s${NC}\n" "$sc" "$ip" "${avg}ms" "${loss}%" "$spd"
done < "$TMP/sorted"

echo
echo -e "${GREEN}${BOLD}✔ $(wc -l < "$OUT") IP پاس‌شده ذخیره شد در:${NC} $OUT"
echo -e "${CYAN}نمایش فایل: cat $OUT${NC}"
