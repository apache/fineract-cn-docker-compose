#!/bin/sh

docker-compose down --remove-orphans
cd external_tools/
docker-compose down
cd ..
docker volume rm external_tools_cassandra-volume
docker volume rm external_tools_postgres-volume