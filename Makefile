PROJECT_NAME=plantio-microservices
COMPOSE=docker compose

.PHONY: up down logs ps build health test test-services test-all \
	up-postgres up-rabbitmq up-infra \
	up-identity up-plants up-feed up-notifications up-gateway \
	down-postgres down-rabbitmq down-infra \
	down-identity down-plants down-feed down-notifications down-gateway

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

# Инфра
up-postgres:
	$(COMPOSE) up -d postgres

up-rabbitmq:
	$(COMPOSE) up -d rabbitmq

# Postgres + RabbitMQ (для локальных прогонов)
up-infra:
	$(COMPOSE) up -d postgres rabbitmq

# Один сервис + его зависимости
# Identity / Plants / Feed: нужны Postgres и RabbitMQ
up-identity:
	$(COMPOSE) up -d --build postgres rabbitmq identity-service

up-plants:
	$(COMPOSE) up -d --build postgres rabbitmq plants-service

up-feed:
	$(COMPOSE) up -d --build postgres rabbitmq feed-service

# Notifications: зависит только от RabbitMQ
up-notifications:
	$(COMPOSE) up -d --build rabbitmq notifications-service

# API Gateway: зависит от всех
up-gateway:
	$(COMPOSE) up -d --build api-gateway

# Остановка контейнеров
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

# Тесты (in-memory SQLite)
test:
	swift test

# Тесты для микросервисов (без Postgres/RabbitMQ)
test-services:
	cd services/identity-service && swift test
	cd services/plants-service && swift test
	cd services/feed-service && swift test
	cd services/notifications-service && swift test
	cd services/api-gateway && swift test

test-all: test test-services
