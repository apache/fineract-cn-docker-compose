#!/usr/bin/env bash

cd external_tools
docker-compose stop
docker-compose rm -v -f

docker volume rm external_tools_cassandra-volume
docker volume rm external_tools_postgres-volume

docker-compose pull

docker-compose up -d
sleep 180
cd ..

java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar  org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env
cat env_variables >> .env

docker-compose stop
docker-compose rm -f
docker-compose pull

docker-compose up -d provisioner-ms
sleep 180

docker-compose up -d rhythm-ms identity-ms customer-ms accounting-ms deposit-ms portfolio-ms office-ms teller-ms fims-web-app
sleep 180


