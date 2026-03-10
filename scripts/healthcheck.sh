#!/usr/bin/env bash

RESULT=$(systemctl is-active nginx)
STATE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
PORT=$(ss -lntp | grep -q ":80")

if [[ "$RESULT" == "active" && "$STATE" == "200" && "PORT" ]]; then
        echo "PASS: nginx state = $RESULT, http state=$STATE, port 80 listening"
        exit 0
else
        echo "FAIL: nginx state = $RESULT, http state=$STATE, port not listening"
        exit 1;
fi
