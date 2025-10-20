#!/bin/bash
WEBHOOK_BOOT="http://192.168.0.59:32000/webhook/pi-boot"
WEBHOOK_RECOVERED="http://192.168.0.59:32000/webhook/n8n-recovered"
CHECK_URL="http://192.168.0.59:32000/"
STATE_FILE="/data/n8n-status/state"

mkdir -p $(dirname "$STATE_FILE")

# --- 1️⃣ Boot trigger ---
if [ ! -f "$STATE_FILE" ]; then
  echo "boot" > "$STATE_FILE"
  echo "$(date): Sending boot webhook..." >> /var/log/n8n-monitor.log
  curl -s -X POST "$WEBHOOK_BOOT" -o /dev/null
fi

# --- 2️⃣ Monitor loop ---
while true; do
  if curl -s --head --request GET "$CHECK_URL" | grep "200 OK" > /dev/null; then
    if grep -q "down" "$STATE_FILE"; then
      echo "up" > "$STATE_FILE"
      echo "$(date): n8n recovered. Sending webhook..." >> /var/log/n8n-monitor.log
      curl -s -X POST "$WEBHOOK_RECOVERED" -o /dev/null
    fi
  else
    if grep -q "up" "$STATE_FILE"; then
      echo "down" > "$STATE_FILE"
      echo "$(date): n8n appears down." >> /var/log/n8n-monitor.log
    fi
  fi
  sleep 30
done
