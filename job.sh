#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq unzip p7zip-full binutils >/dev/null 2>&1
mkdir -p w && cd w
OUT=../out; mkdir -p $OUT
R(){ echo "$@" ; }

R "=== 1. APK ==="
curl -sL -o apk.apk "https://github.com/zhaoyi-habs/miniworld-tools/releases/download/mnw-v1/MiniWorld_latest.apk"
ls -la apk.apk; md5sum apk.apk > $OUT/00_apk_md5.txt
unzip -l apk.apk > $OUT/00_ziplist_full.txt 2>&1

R "=== 2. 抽出 ==="
unzip -o -q apk.apk "assets/*.pkg" "lib/armeabi-v7a/liblibGameApp.so" 2>&1 | tail -3
ls -la assets/ lib/armeabi-v7a/ > $OUT/01_extracted.txt 2>&1

R "=== 3. pkg 头 ==="
{ for f in assets/*.pkg; do echo "--- $f"; xxd -l 64 "$f"; done; } > $OUT/02_pkg_headers.txt 2>&1

R "=== 4. strings ==="
strings -n 5 lib/armeabi-v7a/liblibGameApp.so | sort -u > so_all.txt
wc -l so_all.txt > $OUT/03_counts.txt
for f in assets/*.pkg; do strings -n 4 "$f" >> pkg_raw.txt; done
sort -u pkg_raw.txt > pkg_all.txt; rm -f pkg_raw.txt
wc -l pkg_all.txt >> $OUT/03_counts.txt

cd $OUT/..

R "=== 5. 过滤输出 ==="
W=w
# A Service
grep -E '^[A-Za-z][A-Za-z0-9]{2,}(Service|Mgr|Manager)$' $W/so_all.txt | sort -u > out/A_service.txt
# B Component
grep -E '^[A-Za-z][A-Za-z0-9]{2,}(Component|Cmp)$' $W/so_all.txt | sort -u > out/B_component.txt
# C Mini.*
grep -E '^Mini\.' $W/so_all.txt | sort -u > out/C_mini.txt
grep -E '^Mini[A-Z]' $W/so_all.txt | sort -u >> out/C_mini.txt
# D UGC
grep -iE 'ugc' $W/so_all.txt | sort -u > out/D_ugc.txt
grep -iE 'ugc' $W/pkg_all.txt | sort -u >> out/D_ugc.txt
# E Trigger
grep -iE 'trigger' $W/so_all.txt | sort -u | head -3000 > out/E_trigger.txt
# F 点号 API
grep -E '^[A-Za-z][A-Za-z0-9_]{2,30}\.[A-Za-z][A-Za-z0-9_]{2,30}$' $W/so_all.txt | sort -u > out/F_dotted.txt
# G 中文（UTF-8）
grep -oP '(?:(?!\s)[\x{4e00}-\x{9fff}]|[A-Za-z0-9_]){4,40}' $W/so_all.txt | grep -P '[\x{4e00}-\x{9fff}]' | sort -u > out/G_chinese.txt
# H camelCase 函数式
grep -E '^(get|set|add|remove|del|delete|is|has|play|stop|create|destroy|register|unregister|send|show|hide|open|close|update|start|reset|find|can)[A-Z][A-Za-z0-9]{2,40}$' $W/so_all.txt | sort -u > out/H_funcs.txt
# I snake_case
grep -E '^[a-z][a-z0-9]{2,30}(_[a-z0-9]+){1,6}$' $W/so_all.txt | sort -u > out/I_snake.txt
# J pkg 里的 API/脚本线索
grep -iE '^(game|world|player|block|actor|area|backpack|chat|timer|ui| blueprint|script)' $W/pkg_all.txt | sort -u | head -5000 > out/J_pkg_api.txt
ls -la out/
wc -l out/*.txt >> $OUT/03_counts.txt
