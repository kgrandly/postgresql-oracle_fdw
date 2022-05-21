build:
	unzip instantclient-basic-linux.x64-19.14.0.0.0dbru.zip
	unzip instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip
	unzip oracle_fdw-2.4.0.zip
	docker build --no-cache -t postgres-oracle_fdw:latest .
	rm -rf instantclient_19_14
	rm -rf oracle_fdw-2.4.0

build.oracle:
	cp oracle-xe-11.2.0-1.0.x86_64.rpm.zip oracle/docker-images/OracleDatabase/SingleInstance/dockerfiles/11.2.0.2
	sh oracle/docker-images/OracleDatabase/SingleInstance/dockerfiles/buildContainerImage.sh -v 11.2.0.2 -x
	rm -f oracle/docker-images/OracleDatabase/SingleInstance/dockerfiles/11.2.0.2/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

up:
	docker compose up -d

down:
	docker compose down

down.wipe:
	docker compose down -v
