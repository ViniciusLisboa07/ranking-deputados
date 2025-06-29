up:
	docker compose up

down:
	docker compose down

build:
	docker compose build

sidekiq:
	docker compose exec sidekiq sidekiq

bash:
	docker compose exec backend bash

migrate:
	docker compose exec backend rails db:migrate

seed:
	docker compose exec backend rails db:seed