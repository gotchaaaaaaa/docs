#!/bin/bash
# /usr/local/bin/gotcha-cron.sh
# Usage: gotcha-cron.sh <endpoint>
# Signs with HMAC-SHA256("timestamp.", secret) - matches verifyInternalAuth()

ENDPOINT="$1"
SECRET="SET_WITH_INTERNAL_AUTH_SECRET_FROM_ENV"
BASE_URL="http://localhost:3001"
TIMESTAMP=$(date +%s)

# Signature = HMAC-SHA256("timestamp.", secret)
SIGNATURE=$(echo -n "${TIMESTAMP}." | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')

curl -fsS \
  -X POST \
  -H "Content-Type: application/json" \
  -H "x-internal-timestamp: ${TIMESTAMP}" \
  -H "x-internal-signature: ${SIGNATURE}" \
  "${BASE_URL}${ENDPOINT}"


puis : chmod +x /usr/local/bin/gotcha-cron.sh

dans crontab -e :
0 9 * * 1 /usr/local/bin/gotcha-cron.sh /api/cron/weekly-geolocation-reminder >> /var/log/gotcha-geoloc.log 2>&1
*/15 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/cancel-expired-signatures >> /var/log/gotcha-cron.log 2>&1
*/15 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/signature-deadline-reminder >> /var/log/gotcha-cron.log 2>&1
*/10 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/check-contract-evidence >> /var/log/gotcha-evidence.log 2>&1
15 0 * * * /usr/local/bin/gotcha-cron.sh /api/cron/seal-contract-evidence-daily >> /var/log/gotcha-evidence-seal.log 2>&1
0 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/sync-google-calendars >> /var/log/gotcha-calendars.log 2>&1
*/15 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/company-candidates-alerts >> /var/log/gotcha-alerts.log 2>&1
0 * * * * /usr/local/bin/gotcha-cron.sh /api/cron/company-report-followup >> /var/log/gotcha-followup.log 2>&1
0 8 * * * /usr/local/bin/gotcha-cron.sh /api/cron/provider-legal-docs-reminder >> /var/log/gotcha-legal-docs.log 2>&1
