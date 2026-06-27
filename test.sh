#!/usr/bin/env bash
set -euo pipefail

########################################
# LNMP Platform - Self-Verification Script
# Usage: ./test.sh
########################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
NGINX_URL="http://localhost:${NGINX_PORT:-80}"

print_result() {
    local name="$1"
    local result="$2"
    if [ "$result" = "PASS" ]; then
        echo -e "  ${GREEN}[PASS]${NC} $name"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${NC} $name"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "============================================"
echo "  LNMP Platform - Test Suite"
echo "============================================"
echo ""

# 1. Test PHP probe page
echo "[Test] PHP probe page access..."
if curl -s -o /dev/null -w "%{http_code}" "$NGINX_URL/" | grep -q "200"; then
    print_result "PHP probe page returns 200" "PASS"
else
    print_result "PHP probe page returns 200" "FAIL"
fi

# 2. Test Nginx health endpoint
echo "[Test] Nginx health endpoint..."
if curl -s "$NGINX_URL/health" | grep -q "healthy"; then
    print_result "Nginx health endpoint" "PASS"
else
    print_result "Nginx health endpoint" "FAIL"
fi

# 3. Test PHP-FPM is running
echo "[Test] PHP-FPM container status..."
if docker inspect --format='{{.State.Status}}' lnmp-php 2>/dev/null | grep -q "running"; then
    print_result "PHP-FPM container running" "PASS"
else
    print_result "PHP-FPM container running" "FAIL"
fi

# 4. Test MySQL connection via PHP
echo "[Test] MySQL connection via PHP probe..."
if curl -s "$NGINX_URL/" | grep -q "MySQL"; then
    print_result "MySQL reachable via PHP" "PASS"
else
    print_result "MySQL reachable via PHP" "FAIL"
fi

# 5. Test Redis connection via PHP
echo "[Test] Redis connection via PHP probe..."
if curl -s "$NGINX_URL/" | grep -q "Redis"; then
    print_result "Redis reachable via PHP" "PASS"
else
    print_result "Redis reachable via PHP" "FAIL"
fi

# 6. Test Prometheus is scraping
echo "[Test] Prometheus targets..."
if curl -s "http://localhost:${PROMETHEUS_PORT:-9090}/api/v1/targets" | grep -q '"health":"up"'; then
    print_result "Prometheus has healthy targets" "PASS"
else
    print_result "Prometheus has healthy targets" "FAIL"
fi

# 7. Test Grafana health
echo "[Test] Grafana API health..."
if curl -s "http://localhost:${GRAFANA_PORT:-3000}/api/health" | grep -q "ok"; then
    print_result "Grafana API healthy" "PASS"
else
    print_result "Grafana API healthy" "FAIL"
fi

# 8. Test Kibana health
echo "[Test] Kibana status..."
KIBANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${KIBANA_PORT:-5601}/api/status" 2>/dev/null || echo "000")
if [ "$KIBANA_STATUS" = "200" ]; then
    print_result "Kibana accessible" "PASS"
else
    print_result "Kibana accessible (status: $KIBANA_STATUS)" "FAIL"
fi

# 9. Test maintenance page fallback (php container down)
echo "[Test] PHP-FPM failure -> maintenance page..."
docker stop lnmp-php 2>/dev/null || true
sleep 3
if curl -s -o /dev/null -w "%{http_code}" "$NGINX_URL/index.php" | grep -q "200"; then
    print_result "Maintenance page after PHP-FPM down" "PASS"
else
    print_result "Maintenance page after PHP-FPM down" "FAIL"
fi
docker start lnmp-php 2>/dev/null || true

# 10. Test alertmanager
echo "[Test] Alertmanager status..."
if curl -s "http://localhost:${ALERTMANAGER_PORT:-9093}/-/ready" | grep -q "OK"; then
    print_result "Alertmanager ready" "PASS"
else
    print_result "Alertmanager ready" "FAIL"
fi

# Summary
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "============================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
