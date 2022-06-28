# Creating Helm Chart

By running the following commands the helm chart for Fineract-CN can be generated and deployed on a Kubernetes Cluster.

1. `helm dep up fineract-cn`

2. `helm package fineract-cn`

3. `helm repo index .`

4. Create Secret Config

    export config_param=$( java -cp ./external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar \
        org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX | \
        sed -e 's/^[ \t]*//' | awk '{print "--from-literal="$1}' )
    ...
    kubectl create configmap secret-config ${config_param} -n fineract-cn

5. `helm install fineract-cn ./fineract-cn/ --namespace="fineract-cn" --create-namespace`