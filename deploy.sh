#!/usr/bin/env bash
set -euo pipefail

########################################
# LNMP Platform - One-Click Deploy Script
# Usage:
#   ./deploy.sh            # default: dev
#   ./deploy.sh dev        # development
#   ./deploy.sh prod       # production
########################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Check prerequisites ---
check_prereqs() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    if ! docker compose version &>/dev/null && ! docker-compose --version &>/dev/null; then
        log_error "Docker Compose is not available."
        exit 1
    fi
    log_info "Docker: $(docker --version)"
    log_info "Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null)"
}

# --- Setup .env ---
setup_env() {
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            log_warn ".env file created from .env.example. Edit it before deploying to production."
        else
            log_error ".env.example not found."
            exit 1
        fi
    else
        log_info ".env file already exists."
    fi
}

# --- Wait for healthy ---
wait_healthy() {
    local service="$1"
    local timeout="${2:-120}"
    local interval=5
    local elapsed=0

    log_info "Waiting for $service to be healthy (timeout: ${timeout}s)..."
    while [ $elapsed -lt $timeout ]; do
        local status
        status=$(docker inspect --format='{{json .State.Health.Status}}' "$service" 2>/dev/null || echo "null")
        if [ "$status" = '"healthy"' ]; then
            log_info "$service is healthy."
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    log_error "$service health check timed out after ${timeout}s."
    return 1
}

# --- Main ---
main() {
    local env="${1:-dev}"

    echo "============================================"
    echo "  LNMP Platform - Deploy ($env)"
    echo "============================================"

    check_prereqs
    setup_env

    # Source .env
    set -a; source .env; set +a

    # Determine compose files
    local compose_cmd="docker compose"
    local compose_files="-f docker-compose.yml"

    case "$env" in
        dev|development)
            compose_files="$compose_files -f docker-compose.dev.yml"
            ;;
        prod|production)
            compose_files="$compose_files -f docker-compose.prod.yml"
            ;;
        *)
            log_error "Unknown environment: $env. Use dev or prod."
            exit 1
            ;;
    esac

    log_info "Pulling and starting services..."
    $compose_cmd $compose_files up -d --build

    log_info "Waiting for all services to become healthy..."
    wait_healthy "lnmp-nginx" 120 || true
    wait_healthy "lnmp-mysql" 120 || true
    wait_healthy "lnmp-redis" 60  || true
    wait_healthy "lnmp-es" 180    || true
    wait_healthy "lnmp-grafana" 120 || true
    wait_healthy "lnmp-prometheus" 60 || true

    echo ""
    echo "============================================"
    echo "  Deployment Complete!"
    echo "============================================"
    echo ""
    echo "  Website:      http://localhost:${NGINX_PORT:-80}"
    echo "  Kibana:       http://localhost:${KIBANA_PORT:-5601}"
    echo "  Grafana:      http://localhost:${GRAFANA_PORT:-3000}  (admin/admin)"
    echo "  Prometheus:   http://localhost:${PROMETHEUS_PORT:-9090}"
    echo "  Alertmanager: http://localhost:${ALERTMANAGER_PORT:-9093}"
    echo ""
    echo "  PHP Probe:    http://localhost:${NGINX_PORT:-80}/"
    echo ""
    echo "  To check status: docker compose ps"
    echo "  To view logs:    docker compose logs -f"
    echo ""
}

main "$@"
