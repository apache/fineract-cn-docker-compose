#!/bin/sh
set -e

# Start up Eureka, ActiveMQ, Cassandra and Postgres
cd external_tools/
docker-compose up -d
cassandra_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cassandra)
postgres_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres)

#Test Cassandra and Postgres
echo "Waiting for Cassandra and Postgres ..."
while ! nc -z "${cassandra_ip}" 9042 ; do
  sleep 1
done
while ! nc -z "${postgres_ip}" 5432 ; do
  sleep 1
done
echo "Cassandra and Postgres are up and running..."
cd ..

# Start up Fineract CN microservices
java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env
cat env_variables >> .env

echo "Starting Provisioner... "
docker-compose up -d provisioner-ms
# Make sure provisioner is up and running
echo "Waiting for provisioner to initialize database... "
while ! docker logs fineract-cn-docker-compose_provisioner-ms_1 | grep -q "Started ProvisionerApplication in"; do
  sleep 1
done
echo "Start remaining Fineract CN microservices... "
docker-compose up -d
echo "Successfully started fineract services."