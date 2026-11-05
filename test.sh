#!/usr/bin/env bash
# Smoke test. Start the server first (node server.js), then: ./test.sh [base_url]
# NOTE: expects a freshly started server (full inventory, no coins).
B="${1:-http://localhost:8080}"
H='Content-Type: application/json'
pass=0; fail=0
check() { # name expected actual
  if [ "$2" == "$3" ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1 (expected '$2', got '$3')"; fail=$((fail+1)); fi
}
hdr()  { tr -d '\r' | awk -F': ' -v k="$1" 'tolower($1)==tolower(k){print $2}'; }
code() { curl -s -o /dev/null -w '%{http_code}' -H "$H" "$@"; }

check "inventory starts full" "[5,5,5]" "$(curl -s $B/inventory)"
check "GET item" "5" "$(curl -s $B/inventory/1)"
check "insufficient (0 coins) -> 403" "403" "$(code -X PUT $B/inventory/0)"
check "insert 1st coin 204" "204" "$(code -X PUT -d '{"coin":1}' $B/)"
check "X-Coins after 2nd coin" "2" "$(curl -si -X PUT -H "$H" -d '{"coin":1}' $B/ -o /dev/null -D - | hdr X-Coins)" 
# now 2 coins in; insert a 3rd
code -X PUT -d '{"coin":1}' $B/ >/dev/null
R=$(curl -si -X PUT -H "$H" $B/inventory/0)
check "purchase -> 200" "200" "$(echo "$R" | head -1 | awk '{print $2}')"
check "change returned (1)" "1" "$(echo "$R" | hdr X-Coins)"
check "remaining header (4)" "4" "$(echo "$R" | hdr X-Inventory-Remaining)"
check "body quantity" '{"quantity":1}' "$(echo "$R" | tail -1 | tr -d '\r')"
check "inventory updated" "[4,5,5]" "$(curl -s $B/inventory)"
code -X PUT -d '{"coin":1}' $B/ >/dev/null
check "DELETE returns coins" "1" "$(curl -si -X DELETE $B/ -o /dev/null -D - | hdr X-Coins)"
check "DELETE again returns 0" "0" "$(curl -si -X DELETE $B/ -o /dev/null -D - | hdr X-Coins)"
# drain item 2 to test out-of-stock
for i in 1 2 3 4 5; do code -X PUT -d '{"coin":1}' $B/ >/dev/null; code -X PUT -d '{"coin":1}' $B/ >/dev/null; code -X PUT $B/inventory/2 >/dev/null; done
check "item 2 empty" "0" "$(curl -s $B/inventory/2)"
code -X PUT -d '{"coin":1}' $B/ >/dev/null; code -X PUT -d '{"coin":1}' $B/ >/dev/null
R=$(curl -si -X PUT -H "$H" $B/inventory/2)
check "out of stock -> 404" "404" "$(echo "$R" | head -1 | awk '{print $2}')"
check "out of stock keeps coins (X-Coins 2)" "2" "$(echo "$R" | hdr X-Coins)"
curl -s -X DELETE $B/ >/dev/null
echo; echo "passed=$pass failed=$fail"; [ $fail -eq 0 ]
