.PHONY: dev prod build up down restart logs ps clean test

# Load .env
ifneq (,$(wildcard .env))
    include .env
    export
endif

COMPOSE_DEV := -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_PROD := -f docker-compose.yml -f docker-compose.prod.yml

dev: ## Start development environment
	@echo "Starting LNMP in DEV mode..."
	docker compose $(COMPOSE_DEV) up -d --build
	@echo "Access: http://localhost:$(NGINX_PORT)"
	@echo "Visit: http://localhost:$(NGINX_PORT)/ for PHP probe"

prod: ## Start production environment
	@echo "Starting LNMP in PROD mode..."
	docker compose $(COMPOSE_PROD) up -d --build
	@echo "Access: http://localhost:$(NGINX_PORT)"

build: ## Build images without starting
	@echo "Building images..."
	docker compose $(COMPOSE_DEV) build

up: dev ## Alias for dev

down: ## Stop all services
	docker compose down --remove-orphans

restart: down up ## Restart all services

logs: ## Tail all logs
	docker compose logs -f

ps: ## Show service status
	docker compose ps

clean: down ## Stop and remove volumes
	docker compose down -v --remove-orphans
	@echo "All data volumes removed."

test: ## Run verification tests
	@echo "Running verification tests..."
	@./test.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
