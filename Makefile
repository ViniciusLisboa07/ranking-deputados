up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build


bash:
	docker compose exec backend bash

migrate:
	docker compose exec backend rails db:migrate

seed:
	docker compose exec backend rails db:seed