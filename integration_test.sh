#!/usr/bin/env bash

rm .env
cd external_tools
docker-compose stop
docker-compose rm -v -f

docker volume rm external_tools_cassandra-volume
docker volume rm external_tools_postgres-volume

docker-compose pull

docker-compose up -d
echo "Started external tools. Now waiting for them to start up."
sleep 180
cd ..

java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar  org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env
cat env_variables >> .env
echo "env variables saved into .env"

docker-compose stop
docker-compose rm -f
docker-compose pull

docker-compose up -d provisioner-ms
echo "Started provision-ms. Now waiting it to provision (create schema 'seshat' to Postgres and Cassandra)."
sleep 180

docker-compose up -d rhythm-ms identity-ms customer-ms accounting-ms deposit-ms portfolio-ms office-ms teller-ms fims-web-app
echo "Started set of micro services. Now waiting for them to start up"
sleep 240

echo "Start provisioning the system with Postman scripts."
cd postman_scripts
newman run Fineract-CN-Initial-Requests_PART1.postman_collection.json -e Fineract-Cn-Initial-Setup-Environment.postman_environment.json

echo "Finished."
