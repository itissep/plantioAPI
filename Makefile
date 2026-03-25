PROJECT_NAME=plantio-microservices
COMPOSE=docker compose

.PHONY: up down logs ps build health test test-services test-all \
	up-postgres up-rabbitmq up-infra \
	up-identity up-plants up-feed up-notifications up-gateway \
	down-postgres down-rabbitmq down-infra \
	down-identity down-plants down-feed down-notifications down-gateway

# --- Full stack ---
up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

build:
	$(COMPOSE) build

health:
	bash ./scripts/health-check.sh

# --- Infrastructure only ---
up-postgres:
	$(COMPOSE) up -d postgres

up-rabbitmq:
	$(COMPOSE) up -d rabbitmq

# Postgres + RabbitMQ (без приложений)
up-infra:
	$(COMPOSE) up -d postgres rabbitmq

# --- One app service + its dependencies (compose + --build for that service image) ---
# Identity / Plants / Feed: нужны Postgres и RabbitMQ
up-identity:
	$(COMPOSE) up -d --build postgres rabbitmq identity-service

up-plants:
	$(COMPOSE) up -d --build postgres rabbitmq plants-service

up-feed:
	$(COMPOSE) up -d --build postgres rabbitmq feed-service

# Notifications: в compose зависит только от RabbitMQ
up-notifications:
	$(COMPOSE) up -d --build rabbitmq notifications-service

# Gateway тянет за собой все сервисы из depends_on
up-gateway:
	$(COMPOSE) up -d --build api-gateway

# --- Stop individual pieces (контейнеры остаются, можно снова up) ---
down-postgres:
	$(COMPOSE) stop postgres

down-rabbitmq:
	$(COMPOSE) stop rabbitmq

down-infra:
	$(COMPOSE) stop postgres rabbitmq

down-identity:
	$(COMPOSE) stop identity-service

down-plants:
	$(COMPOSE) stop plants-service

down-feed:
	$(COMPOSE) stop feed-service

down-notifications:
	$(COMPOSE) stop notifications-service

down-gateway:
	$(COMPOSE) stop api-gateway

# Run tests without Docker (in-memory SQLite / no DB)
test:
	swift test

# Run tests only for microservices (no Postgres/RabbitMQ needed)
test-services:
	cd services/identity-service && swift test
	cd services/plants-service && swift test
	cd services/feed-service && swift test
	cd services/notifications-service && swift test
	cd services/api-gateway && swift test

test-all: test test-services
