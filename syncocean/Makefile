build: build.db build.server

build.db:
	docker build --no-cache -t syncocean-db:latest .

build.server:
	cd server && docker build --no-cache -t syncocean-server:latest .

up:
	docker compose up -d

down:
	docker compose down

down.wipe:
	docker compose down -v
