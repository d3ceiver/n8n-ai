#!/bin/sh
LOG_FILE="/var/log/n8n-monitor.log"
N8N_URL="http://192.168.0.59:32000"
WEBHOOK_BOOT="http://192.168.0.59:32000/webhook/pi-boot"

log() {
  echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC'): $1" | tee -a "$LOG_FILE"
}

log "n8n monitor pod started."

# Wait for n8n to be up
log "Waiting for n8n to become available..."
until curl -s --max-time 5 "$N8N_URL" >/dev/null 2>&1; do
  sleep 5
done
log "n8n is now UP → sending boot webhook..."

# Keep trying the webhook until it succeeds
while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBHOOK_BOOT")
  if [ "$STATUS" -eq 200 ]; then
    log "Boot webhook sent successfully!"
    break
  else
    log "Boot webhook failed with HTTP $STATUS. Retrying in 10s..."
    sleep 10
  fi
done

# Continuous monitoring (optional)
while true; do
  if ! curl -s --max-time 5 "$N8N_URL" >/dev/null 2>&1; then
    log "n8n seems DOWN. Retrying..."
  fi
  sleep 60
done
