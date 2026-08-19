#!/data/data/com.termux/files/usr/bin/bash
# ===================================================
#  RED | Cloudflare Clean IP Scanner - Termux (v11)
#  Best-first ranking by Loss+Delay+Jitter+Speed
# ===================================================
G='\033[1;32m';Y='\033[1;33m';R='\033[1;31m';C='\033[1;36m';B='\033[1m';NC='\033[0m'
TIMEOUT=3;PASS=60
OUT="$HOME/cf_clean_ips.txt";DONE="$HOME/.red_done";LNK="$HOME/.red_link"
TMP=$(mktemp -d);XDIR="$HOME/red_xray"
DLBYTES=5000000;ULBYTES=2000000
trap 'rm -rf "$TMP"; exec 9>&-' EXIT
trap 'echo; echo -e "${Y}Stopped — showing results...${NC}"; show_results; exit' INT
clear
echo -e "${R}${B}"
cat <<'EOF'
██████╗ ███████╗██████╗
██╔══██╗██╔════╝██╔══██╗
██████╔╝█████╗  ██║  ██║
██╔══██╗██╔══╝  ██║  ██║
██║  ██║███████╗██████╔╝
╚═╝  ╚═╝╚══════╝╚═════╝
EOF
echo -e "${NC}${B}   ⚡ CLOUDFLARE CLEAN IP SCANNER${NC}"
echo -e "${C}   v11: best-first ranking (Loss+Delay+Jitter+Speed)"
echo -e "${C}   t.me/RedProjectX${NC}"
echo -e "${C}──────────────────────────────────────────────${NC}"
echo

for p in curl gawk grep coreutils unzip; do
  command -v "$p" >/dev/null 2>&1 || { echo -e "${Y}Installing $p ...${NC}"; pkg install -y "$p" >/dev/null 2>&1; }
done

echo -e "${C}1)${NC} Random Cloudflare ranges (ALL 12, round-robin)"
echo -e "${C}2)${NC} Custom range (e.g. 198.41.223)"
echo -e "${C}3)${NC} IP list from file (one per line)"
read -p "Select [1/2/3]: " MODE
PREFIX="";FLIST=""
[ "$MODE" = 2 ] && read -p "Range prefix (xxx.xxx.xxx): " PREFIX
[ "$MODE" = 3 ] && read -p "IP list file path: " FLIST
read -p "Number of IPs [100]: " TOTAL;TOTAL=${TOTAL:-100}
read -p "TCPing per IP [4]: " TESTS;TESTS=${TESTS:-4}
read -p "Scan port [443]: " PORT;PORT=${PORT:-443}
read -p "Multi-port test top10 (443/2053/2083/8443)? y/n [y]: " MP;MP=${MP:-y}
read -p "Real DL/UL speed top10? y/n [y]: " SPD;SPD=${SPD:-y}
read -p "Xray real verify top5 (DL via Xray)? y/n [n]: " XR;XR=${XR:-n}
read -p "Concurrency [20]: " CONC;CONC=${CONC:-20}

recent(){ [ -f "$DONE" ] && awk -F'|' -v ip="$1" -v now="$(date +%s)" '$1==ip && now-$2<21600{f=1} END{exit !f}' "$DONE"; }

rand_ip(){
 if [ -n "$PREFIX" ]; then echo "$PREFIX.$((1+RANDOM%254))";return; fi
 case $(( $1 % 12 )) in
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

probe(){
 local w=$(curl -sk -o /dev/null -w '%{http_code} %{time_connect} %{time_appconnect} %{time_total}' \
   --max-time "$TIMEOUT" "https://$1:$PORT/" 2>/dev/null)
 local code=${w%% *}
 case "$code" in 000|"") echo FAIL;return;; esac
 echo "$w" | awk '{printf "%d %d %d", $2*1000+0.5, ($3-$2)*1000+0.5, $4*1000+0.5}'
}

dl_test(){
 local w=$(curl -sk -o /dev/null -w '%{http_code} %{speed_download}' --resolve "speed.cloudflare.com:443:$1" --max-time 15 "https://speed.cloudflare.com/__down?bytes=$DLBYTES" 2>/dev/null)
 [ "${w%% *}" = "200" ] || { echo 0.00;return; }
 echo "$w" | awk '{printf "%.2f", $2/1048576}'
}
ul_test(){
 local f="$TMP/up.bin"; [ -f "$f" ] || head -c $ULBYTES /dev/urandom > "$f"
 local w=$(curl -sk -o /dev/null -w '%{http_code} %{speed_upload}' --resolve "speed.cloudflare.com:443:$1" --max-time 15 -X POST --data-binary @"$f" "https://speed.cloudflare.com/__up" 2>/dev/null)
 [ "${w%% *}" = "200" ] || { echo 0.00;return; }
 echo "$w" | awk '{printf "%.2f", $2/1048576}'
}

best_port(){
 local bp=$PORT bt=999999
 for p in 443 2053 2083 8443; do
  local t=$(curl -sk -o /dev/null -w '%{time_connect}' --max-time 2 "https://$1:$p/" 2>/dev/null)
  local ms=$(awk -v t="$t" 'BEGIN{printf "%d", t*1000+0.5}')
  if [ "$ms" -gt 0 ] && [ "$ms" -lt "$bt" ]; then bt=$ms; bp=$p; fi
 done
 echo "$bp"
}

scan_ip(){
 local ip=$1 ok=0 att=0 fails=0 tcps="" tls_sum=0 t tcp tls tot
 for i in $(seq 1 "$TESTS"); do
  att=$((att+1))
  t=$(probe "$ip")
  if [ "$t" = FAIL ]; then fails=$((fails+1)); [ $fails -ge 2 ] && break; continue; fi
  read -r tcp tls tot <<< "$t"
  ok=$((ok+1)); tcps="$tcps $tcp"; tls_sum=$((tls_sum+tls))
 done
 echo "$ip|$(date +%s)" >> "$DONE"
 [ $ok -eq 0 ] && return
 local loss=$(( (att-ok)*100/att ))
 local tcp_avg=$(echo $tcps | tr ' ' '\n' | grep -v '^$' | sort -n | awk -v n=$ok 'NR==int((n+1)/2){print}')
 local jit=$(echo $tcps | tr ' ' '\n' | grep -v '^$' | sort -n | awk 'NR==1{m=$1}{M=$1}END{print M-m}')
 [ -z "$jit" ] && jit=0
 local score=$(awk -v loss=$loss -v tcp=$tcp_avg -v jit=$jit 'BEGIN{
   dly=(tcp<=40)?100:100-(tcp-40)*0.25; if(dly<0)dly=0;
   jt=(jit<=20)?100:100-(jit-20)*0.3;  if(jt<0)jt=0;
   sc=(100-loss)*0.45 + dly*0.30 + jt*0.25; printf "%.1f",sc}')
 if awk -v s="$score" -v p=$PASS 'BEGIN{exit !(s>=p)}'; then echo -e "${G}✔ $ip | TCP ${tcp_avg}ms | JIT ${jit}ms | SCORE $score${NC}"; fi
 echo "$score|$ip|$tcp_avg|$loss|$jit" >> "$TMP/res"
}

urldec(){ printf '%b' "${1//%/\\x}"; }
getp(){ echo "$B_PARAMS" | tr '&' '\n' | grep -m1 "^$1=" | cut -d= -f2- | urldec; }
setup_xray(){
 [ -x "$XDIR/xray" ] && return 0
 echo -e "${Y}Downloading Xray core...${NC}"; mkdir -p "$XDIR"
 case "$(uname -m)" in
  aarch64|arm64) ASSET="Xray-android-arm64-v8a.zip";;
  armv7*|armv7l) ASSET="Xray-android-arm32-v8a.zip";;
  x86_64) ASSET="Xray-linux-64.zip";;
  *) ASSET="Xray-android-arm64-v8a.zip";;
 esac
 curl -sL -o "$XDIR/x.zip" "https://github.com/XTLS/Xray-core/releases/latest/download/$ASSET" || return 1
 unzip -oq "$XDIR/x.zip" -d "$XDIR" && chmod +x "$XDIR/xray"
}
parse_base(){
 local u="${BASE#vless://}"; B_ID="${u%%@*}"; local rest="${u#*@}"
 local hp="${rest%%\?*}"; B_PORT="${hp##*:}"; [ "$B_PORT" = "$hp" ] && B_PORT=443
 case "$rest" in *\?*) B_PARAMS="${rest#*\?}"; B_PARAMS="${B_PARAMS%%#*}";; *) B_PARAMS="";; esac
 B_SNI=$(getp sni); [ -z "$B_SNI" ] && B_SNI=$(getp servername); [ -z "$B_SNI" ] && B_SNI="${hp%%:*}"
 B_NET=$(getp type); [ -z "$B_NET" ] && B_NET=ws
 B_PATH=$(getp path); [ -z "$B_PATH" ] && B_PATH=/
 B_HOST=$(getp host); [ -z "$B_HOST" ] && B_HOST="$B_SNI"
 B_SEC=$(getp security); [ -z "$B_SEC" ] && B_SEC=tls
}
xray_verify(){
 local ip=$1 WSPART=""
 case "$B_NET" in
  ws) WSPART=',"wsSettings":{"path":"'"$B_PATH"'","headers":{"host":"'"$B_HOST"'"}}';;
  grpc) WSPART=',"grpcSettings":{"serviceName":"'"$B_PATH"'"}';;
 esac
 cat > "$XDIR/cfg.json" <<EOF
{"log":{"loglevel":"none"},"inbounds":[{"port":10808,"listen":"127.0.0.1","protocol":"socks","settings":{"auth":"noauth","udp":false}}],"outbounds":[{"protocol":"vless","settings":{"address":"$ip","port":$B_PORT,"vusers":[{"id":"$B_ID","encryption":"none","level":8}]},"streamSettings":{"network":"$B_NET","security":"$B_SEC","tlsSettings":{"serverName":"$B_SNI","allowInsecure":true}$WSPART}}]}
EOF
 "$XDIR/xray" run -c "$XDIR/cfg.json" >/dev/null 2>&1 &
 local xp=$!; sleep 1.2
 local w=$(curl -s -o /dev/null -w '%{http_code} %{time_total}' -x socks5h://127.0.0.1:10808 --max-time 7 "https://$B_SNI/" 2>/dev/null)
 local lat=FAIL; case "${w%% *}" in 000|"") ;; *) lat=$(echo "$w" | awk '{printf "%d",$2*1000+0.5}');; esac
 local dl=0.00
 if [ "$lat" != FAIL ]; then
  local d=$(curl -s -o /dev/null -w '%{http_code} %{speed_download}' -x socks5h://127.0.0.1:10808 --max-time 15 "https://speed.cloudflare.com/__down?bytes=$DLBYTES" 2>/dev/null)
  [ "${d%% *}" = "200" ] && dl=$(echo "$d" | awk '{printf "%.2f", $2/1048576}')
 fi
 kill $xp 2>/dev/null
 echo "$lat|$dl"
}

show_results(){
 [ -s "$TMP/res" ] || { echo -e "${R}No responsive IP found.${NC}"; return; }
 : > "$TMP/prt"
 if [ "$MP" = y ]; then
  echo -e "${C}Multi-port test (top 10)...${NC}"
  while IFS='|' read -r sc ip r; do bp=$(best_port "$ip"); echo "$ip|$bp" >> "$TMP/prt"; echo -e "${C}  $ip best port: $bp${NC}"; done < <(sort -t'|' -k1,1rn "$TMP/res" | head -10)
 fi
 : > "$TMP/spd"
 if [ "$SPD" = y ]; then
  echo -e "${C}Speed stage (top 10, real DL/UL)...${NC}"
  while IFS='|' read -r sc ip r; do
   dl=$(dl_test "$ip"); ul=$(ul_test "$ip")
   echo "$ip|$dl|$ul" >> "$TMP/spd"; echo -e "${C}  $ip ↓$dl ↑$ul MB/s${NC}"
  done < <(sort -t'|' -k1,1rn "$TMP/res" | head -10)
 fi
 : > "$TMP/xr"
 if [ "$XR" = y ]; then
  if [ ! -f "$LNK" ]; then read -p "Paste your vless link for Xray verify: " vv; echo "$vv" > "$LNK"; fi
  BASE=$(cat "$LNK")
  if [[ "$BASE" == vless://* ]] && setup_xray; then
   parse_base
   if [ "$B_SEC" = tls ]; then
    echo -e "${C}Xray real verify (top 5, DL via Xray)...${NC}"
    while IFS='|' read -r sc ip r; do
     res=$(xray_verify "$ip"); xl=${res%%|*}; xd=${res##*|}
     if [ "$xl" != FAIL ]; then echo -e "${G}  ⭐ $ip via Xray: ${xl}ms ↓$xd MB/s${NC}"; echo "$ip|$xl|$xd" >> "$TMP/xr"; fi
    done < <(sort -t'|' -k1,1rn "$TMP/res" | head -5)
   else echo -e "${Y}Xray verify skipped (non-TLS)${NC}"; fi
  else echo -e "${Y}Xray verify unavailable${NC}"; fi
 fi
 # combine + final quality score + best-first sort
 : > "$TMP/comb"
 while IFS='|' read -r sc ip tcp loss jit; do
  dl=$(awk -F'|' -v ip="$ip" '$1==ip{print $2}' "$TMP/spd"); [ -z "$dl" ] && dl=0
  ul=$(awk -F'|' -v ip="$ip" '$1==ip{print $3}' "$TMP/spd"); [ -z "$ul" ] && ul=0
  bp=$(awk -F'|' -v ip="$ip" '$1==ip{print $2}' "$TMP/prt"); [ -z "$bp" ] && bp=$PORT
  xl=$(awk -F'|' -v ip="$ip" '$1==ip{print $2}' "$TMP/xr"); [ -z "$xl" ] && xl=-
  q=$(awk -v sc="$sc" -v dl="$dl" -v ul="$ul" 'BEGIN{sp=dl+ul; q=sc; if(sp>0){s2=(sp*8>100)?100:sp*8; q=sc*0.7+s2*0.3} printf "%.1f",q}')
  echo "$q|$ip|$bp|$loss|$tcp|$jit|$dl|$ul|$xl" >> "$TMP/comb"
 done < "$TMP/res"
 sort -t'|' -k1,1rn "$TMP/comb" > "$TMP/final"
 echo; echo -e "${G}${B}Results (best first):${NC}"
 printf "${B}%-4s %-16s %-6s %-6s %-7s %-6s %-8s %-8s %-6s${NC}\n" "RANK" "IP" "PORT" "LOSS" "DELAY" "JIT" "DOWN" "UP" "SCORE"
 : > "$OUT"; local rank=0
 while IFS='|' read -r q ip bp loss tcp jit dl ul xl; do
  rank=$((rank+1))
  if awk -v s="$q" -v p=$PASS 'BEGIN{exit !(s>=p)}'; then color=$G; echo "$ip" >> "$OUT"; else color=$Y; fi
  [ "$xl" != "-" ] && q="${q}⭐"
  printf "${color}%-4s %-16s %-6s %-6s %-7s %-6s %-8s %-8s %-6s${NC}\n" "$rank." "$ip" "$bp" "$loss%" "${tcp}ms" "${jit}ms" "$dl" "$ul" "$q"
 done < "$TMP/final"
 echo
 echo -e "${R}${B}RED${NC} ${G}✔ $(wc -l < "$OUT") clean IPs saved (best first) to:${NC} $OUT"
}

: > "$TMP/res"
echo -e "${C}Scanning... (green = clean, Ctrl+C = stop & show)${NC}"
if [ "$MODE" = 3 ]; then mapfile -t IPLIST < "$FLIST"; TOTAL=${#IPLIST[@]}; fi
mkfifo "$TMP/fifo"; exec 9<>"$TMP/fifo"
for i in $(seq 1 "$CONC"); do echo >&9; done
for i in $(seq 1 "$TOTAL"); do
 if [ "$MODE" = 3 ]; then ip=${IPLIST[$((i-1))]}; else
  for try in 1 2 3; do ip=$(rand_ip "$i"); recent "$ip" || break; done
 fi
 printf "\r${Y}Progress: %d/%d${NC}          " "$i" "$TOTAL"
 read -u 9
 { scan_ip "$ip"; echo >&9; } &
done
wait
exec 9>&-
echo
show_results
