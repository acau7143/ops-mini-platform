#!/usr/bin/env bash

# 현재 시간
TS=$(date '+%Y-%m-%d_%H:%M:%S')
OUTDIR="evidence/${TS}-deploy"
COMPOSE_FILE="docker-compose.yaml"
SERVICE_URL="http://localhost:8080"
MAX_RETRY=3

log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')]  $1" | tee -a "$OUTDIR/deploy.log"
}


healthcheck(){
        attempt=1
        while [ $attempt -le $MAX_RETRY ]; do
                if curl -sf -o /dev/null $SERVICE_URL; then
                        return 0
                else
                        sleep 3
                        attempt=$((attempt + 1))
                fi
        done
        return 1
}

rollback(){
        log "롤백 시작"
        sudo docker compose down
        sudo docker compose up -d --no-pull
        log "롤백 완료"
}

mkdir -p $OUTDIR
docker ps > ${OUTDIR}/before.txt
docker compose pull
docker compose up -d
if healthcheck; then
        docker ps > $OUTDIR/after.txt
        exit 0
else
        rollback
        exit 1
fi


