#!/bin/sh

# cd kubernetes-scripts
echo "Starting ActiveMQ, Eureka, PostgreSQL and Cassandra ..."
kubectl apply -f activemq.yml
kubectl apply -f eureka.yml
kubectl apply -f postgres.yml
kubectl apply -f cassandra.yml

cassandra_ip=""
postgres_ip=""
eureka_ip=""
activemq_ip=""

echo ""
echo "Sharing Cassandra, PostgreSQL, Eureka and ActiveMQ  IP addresses..."
while [[ ${#cassandra_ip} -eq 0 || ${#postgres_ip} -eq 0 || ${#eureka_ip} -eq 0 || ${#activemq_ip} -eq 0 ]] ; do
     cassandra_ip=$(kubectl describe service cassandra-cluster | grep 'LoadBalancer Ingress' \
          | grep -Eo '[0-9.]*')
     postgres_ip=$(kubectl describe service postgresdb-cluster | grep 'LoadBalancer Ingress'\
          | grep -Eo '[0-9.]*')
     eureka_ip=$(kubectl describe service eureka-cluster | grep 'LoadBalancer Ingress'\
          | grep -Eo '[0-9.]*')
     activemq_ip=$(kubectl describe service activemq-cluster | grep 'LoadBalancer Ingress'\
          | grep -Eo '[0-9.]*')
done


echo ""
echo "Creating default fineract service configuration"
kubectl create configmap external-tools-config \
    --from-literal=ribbon.listOfServers=${eureka_ip}:9090 \
    --from-literal=eureka.client.serviceUrl.defaultZone=http://${eureka_ip}:8761/eureka \
    --from-literal=postgresql.host=${postgres_ip} \
    --from-literal=activemq.brokerUrl=tcp://${activemq_ip}:61616 \
    --from-literal=cassandra.contactPoints=${cassandra_ip}:9042

kubectl create configmap provisioner-datasource-config \
      --from-literal=spring.datasource.url=jdbc:postgresql://${postgres_ip}:5432/seshat

kubectl apply -f config.yml

config_param=$( java -cp ../external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar \
     org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX | \
     sed -e 's/^[ \t]*//' | awk '{print "--from-literal="$1}' )
kubectl create configmap secret-config ${config_param}

echo ""
echo "Starting Provisioner... "
kubectl apply -f provisioner.yml
provisioner_pod=$(kubectl get pods -l app=provisioner-ms --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo "Waiting for provisioner to initialize seshat database... "
sleep 5
while ! kubectl logs ${provisioner_pod} | grep -q "Started ProvisionerApplication in"; do
  sleep 1
done

echo ""
echo "Start remaining Fineract CN microservices... "
kubectl apply -f identity.yml
kubectl apply -f rhythm.yml
# kubectl apply -f office.yml
# kubectl apply -f customer.yml
# kubectl apply -f ledger.yml
# kubectl apply -f portfolio.yml
