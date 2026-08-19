#!/data/data/com.termux/files/usr/bin/bash
# ===================================================
#  Cloudflare Clean IP Scanner - Termux Edition (v3)
#  Core inspired by bgscan: direct TCP/TLS probes
# ===================================================
G='\033[1;32m';Y='\033[1;33m';R='\033[1;31m';C='\033[1;36m';B='\033[1m';NC='\033[0m'
PORT=443;TIMEOUT=5
OUT="$HOME/cf_clean_ips.txt";TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
clear
echo -e "${C}${B}+==========================================+
|  Cloudflare Clean IP Scanner - Termux    |
|  v3: direct TCP/TLS probes (bgscan-like) |
+==========================================+${NC}"

for p in curl gawk grep coreutils; do
  command -v "$p" >/dev/null 2>&1 || { echo -e "${Y}Installing $p ...${NC}"; pkg install -y "$p" >/dev/null 2>&1; }
done

echo -e "${C}1)${NC} Random Cloudflare ranges"
echo -e "${C}2)${NC} Custom range (e.g. 198.41.223)"
echo -e "${C}3)${NC} IP list from file (one per line)"
read -p "Select [1/2/3]: " MODE
PREFIX="";FLIST=""
[ "$MODE" = 2 ] && read -p "Range prefix (xxx.xxx.xxx): " PREFIX
[ "$MODE" = 3 ] && read -p "IP list file path: " FLIST
read -p "Number of IPs [100]: " TOTAL;TOTAL=${TOTAL:-100}
read -p "Tests per IP [3]: " TESTS;TESTS=${TESTS:-3}
read -p "Speed-test domain (blank = skip) []: " DD
read -p "Concurrency [10]: " CONC;CONC=${CONC:-10}

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

probe(){ # direct IP, no blocked SNI; any HTTP reply = alive
 local w=$(curl -sk -o /dev/null -w '%{http_code} %{time_connect} %{time_appconnect} %{time_total}' \
   --max-time "$TIMEOUT" "https://$1:$PORT/" 2>/dev/null)
 local code=${w%% *}
 case "$code" in 000|"") echo FAIL;return;; esac
 echo "$w" | awk '{printf "%d %d %d", $2*1000+0.5, ($3-$2)*1000+0.5, $4*1000+0.5}'
}

speed_test(){
 [ -z "$DD" ] && { echo 0.00;return; }
 local w=$(curl -sk -o /dev/null -w '%{http_code} %{speed_download}' \
   --resolve "$DD:443:$1" --max-time 7 "https://$DD/__down?bytes=3000000" 2>/dev/null)
 [ "${w%% *}" = "200" ] || { echo 0.00;return; }
 echo "$w" | awk '{printf "%.2f", $2/1048576}'
}

scan_ip(){
 local ip=$1 ok=0 tcps="" tls_sum=0 t tcp tls tot
 for i in $(seq 1 "$TESTS"); do
  t=$(probe "$ip")
  if [ "$t" != FAIL ]; then
   read -r tcp tls tot <<< "$t"
   ok=$((ok+1)); tcps="$tcps $tcp"; tls_sum=$((tls_sum+tls))
  fi
 done
 [ $ok -eq 0 ] && return
 local loss=$(( (TESTS-ok)*100/TESTS ))
 local tcp_avg=$(echo $tcps | tr ' ' '\n' | grep -v '^$' | sort -n | awk -v n=$ok 'NR==int((n+1)/2){print}')
 local tls_avg=$((tls_sum/ok)) spd=0.00
 if [ -n "$DD" ] && [ $loss -eq 0 ] && [ "$tcp_avg" -le 500 ]; then spd=$(speed_test "$ip"); fi
 local score=$(awk -v ok=$ok -v ts=$TESTS -v tcp=$tcp_avg -v tls=$tls_avg -v spd=$spd -v st=$([ -n "$DD" ] && echo 1 || echo 0) 'BEGIN{
   succ=ok/ts;
   lat=(tcp<=40)?100:100-(tcp-40)*0.25; if(lat<0)lat=0;
   tl=(tls<=120)?100:100-(tls-120)*0.2; if(tl<0)tl=0;
   sp=(spd>=5)?100:spd*20;
   if(st) sc=succ*45+lat*20+tl*10+sp*25; else sc=succ*55+lat*25+tl*20;
   if(sc>100)sc=100; printf "%.1f",sc}')
 echo "$score|$ip|$tcp_avg|$tls_avg|$loss|$spd" >> "$TMP/res"
}

: > "$TMP/res"
echo -e "${C}Scanning...${NC}"
if [ "$MODE" = 3 ]; then mapfile -t IPLIST < "$FLIST"; TOTAL=${#IPLIST[@]}; fi
for i in $(seq 1 "$TOTAL"); do
 if [ "$MODE" = 3 ]; then ip=${IPLIST[$((i-1))]}; else ip=$(rand_ip); fi
 printf "\r${Y}Progress: %d/%d${NC}    " "$i" "$TOTAL"
 scan_ip "$ip" &
 while [ "$(jobs -r | wc -l)" -ge "$CONC" ]; do sleep 0.2; done
done
wait
echo

if [ ! -s "$TMP/res" ]; then echo -e "${R}No responsive IP found.${NC}"; exit 1; fi
sort -t'|' -k1,1rn "$TMP/res" > "$TMP/sorted"

echo -e "${G}${B}Results (sorted by score):${NC}"
printf "${B}%-6s %-18s %-7s %-7s %-6s %-10s${NC}\n" "SCORE" "IP" "TCP" "TLS" "LOSS" "SPEED MB/s"
: > "$OUT"
while IFS='|' read -r sc ip tcp tls loss spd; do
 if awk -v s="$sc" 'BEGIN{exit !(s>=80)}'; then color=$G; echo "$ip" >> "$OUT"
 elif awk -v s="$sc" 'BEGIN{exit !(s>=60)}'; then color=$Y; else color=$R; fi
 printf "${color}%-6s %-18s %-7s %-7s %-6s %-10s${NC}\n" "$sc" "$ip" "${tcp}ms" "${tls}ms" "${loss}%" "$spd"
done < "$TMP/sorted"

echo
echo -e "${G}${B}✔ $(wc -l < "$OUT") clean IPs saved to:${NC} $OUT"
echo -e "${C}View: cat $OUT${NC}"
