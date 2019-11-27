# cd kubernetes-scripts/
# kubectl delete -f office.yml
# kubectl delete -f customer.yml
# kubectl delete -f portfolio.yml
# kubectl delete -f rhythm.yml
# kubectl delete -f identity.yml
kubectl delete -f provisioner.yml
kubectl delete configmaps external-tools-config
kubectl delete configmaps fineract-service-config
kubectl delete configmaps secret-config
kubectl delete configmaps provisioner-datasource-config
kubectl delete -f postgres.yml
kubectl delete -f cassandra.yml
kubectl delete -f eureka.yml
kubectl delete -f activemq.yml
kubectl delete -f ledger.yml