#!/bin/sh
set -e

echo "Createing docker service network"
docker network create --driver=bridge --subnet=172.16.238.0/24 external_tools_default

cd external_tools/
docker-compose up -d
cassandra_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cassandra)
postgres_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres)

# #Test Cassandra and Postgres
echo "Waiting for Cassandra and Postgres ..."
while ! nc -z "${cassandra_ip}" 9042 ; do
  sleep 1
done
while ! nc -z "${postgres_ip}" 5432 ; do
  sleep 1
done
echo "Cassandra and Postgres are up and running..."
cd ..

echo "Starting up Fineract CN microservices..."
wget https://mifos.jfrog.io/mifos/libs-snapshot-local/org/apache/fineract/cn/lang/0.1.0-BUILD-SNAPSHOT/lang-0.1.0-BUILD-SNAPSHOT.jar
java -cp lang-0.1.0-BUILD-SNAPSHOT.jar org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env
cat env_variables >> .env

docker-compose up -d
echo "Successfully started fineract services."
