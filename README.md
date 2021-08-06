# Fineract CN Docker-Compose scripts
This project contains Docker and Kubernetes Scripts for deploying Fineract CN, especially in Development.

## Requirements

### Fineract CN Libraries

01. fineract-cn-lang
02. fineract-cn-postgresql
03. fineract-cn-anubis
04. fineract-cn-permitted-feign-client
05. fineract-cn-identity
06. fineract-cn-api
07. fineract-cn-async
08. fineract-cn-cassandra
09. fineract-cn-crypto
10. fineract-cn-test

### Environment Variables 

The following variables are required for publishg the binary artifacts. Values are examples, change them to fit your environment.
```console
ARTIFACTORY_URL = 'https://url-to-artifactory/artifactory/'
ARTIFACTORY_USER = 'user'
ARTIFACTORY_PASSWORD = 'password'
ARTIFACTORY_REPOKEY = 'libs-snapshot-local'
```
### Software Platform 

1. Kubernetes
2. Docker
3. Docker-compose
4. Java

# Deploy and provision Fineract CN using Kubernetes
Make sure you set up and connect to your Kubernetes cluster. You can follow [this](https://cwiki.apache.org/confluence/display/FINERACT/Install+and+configure+kubectl+and+Google+Cloud+SDK+on+ubuntu+16.04) guide to set up a Kubernetes cluster on GKE.

 - Enter the Kubernetes directory.
```console
cd kubernetes_scripts
```
 - To deploy all the Fineract CN services on your cluster, run :
```console
bash kubectl-start-up.sh
```
 - You should make sure an external ip address had been assigned to all the deployed services by running:
```console
kubectl get services
```
 - Finally provison the microservices by running:
```console
cd bash_scripts
bash provision.sh --deploy-on-kubernetes playground # where playground is your tenant name
```
 - To shut down and reset you cluster, run:
```console
bash kubectl-shut-down.sh
```
# Deploy and provision Fineract CN using Docker and Docker-compose

You can either deploy and provision Fineract CN automatically using bash scripts or manually using Postman.

## Hints:
- Postman is the preferred approach if you want to understand what is happening and, Bash is preferred when you already understand what's happening so, you simply what to automate the process.

- With Postman, you have more flexibility in deciding which service gets to be deployed and provisioned, therefore, making it the preferred route if you have limited resources.

# 1. Deploy and provision Fineract automatically using bash scripts

 - To start up all the Fineract CN services run:
```console
bash start-up.sh
```
 - Then log the last Fineract CN microservice deployed by docker compose (fineract-cn-notification) to make sure all your Fineract services are now available.
```console
docker logs -f fineract-cn-docker-compose_notifications-ms_1
```
 - Finally provison the microservices by
```console
cd bash_scripts
bash provision.sh playground # where playground is your tenant name
```
## 2. Deploy Fineract manually using postman

## Perquisites

### Generate .env file with RSA keys
```console
java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar  org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env
```
This library is taken from [fineract-cn-lang](https://github.com/apache/fineract-cn-lang#generate-and-print-rsa-keys).

If needed you can pull a fresh copy of it:
```console
wget https://mifos.jfrog.io/mifos/libs-snapshot-local/org/apache/fineract/cn/lang/0.1.0-BUILD-SNAPSHOT/lang-0.1.0-BUILD-SNAPSHOT.jar external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar
```
### Add other environment variables to the end of the .env file
```console
cat env_variables >> .env
```
If you run some service from localhost then [add these services to your hosts file](#use-the-postman-scripts-when-running-locally).

## Procedure

### Start external tools (database, cassandra, etc)
```console
cd external_tools
docker-compose up
```

### Start micro services
First only start provisioner-ms by running following in project root:

```console
docker-compose up provisioner-ms
```
after it has started (and created table seshat to Postgre database) you can start rest of the services.
This is just to make sure provisioner gets to create the database the other services require.

### Choose the services you want to run
In the docker-compose.yml (that resides in project root) there are more than 10 services defined.
Running all services together consumes a lot of memory. So you can start a subset of services.

For example you could start the following additional micro services and an fims-web-app:
```console
docker-compose up rhythm-ms identity-ms customer-ms accounting-ms deposit-ms portfolio-ms office-ms teller-ms fims-web-app
```
If you want you can add other micro services (listed in docker-compose.yml) to the list.

Wait for all the started services (except provisioner) to appear at [Eureka console](http://eureka:8761/).

# Provision

## Description of provisioning logic

Provisioning logic is described briefly [here](https://cwiki.apache.org/confluence/display/FINERACT/Fineract+CN+demo-server).
Instead demo_server we have Postman scripts and we use 'playground' as tenant name we want to provision.

## Provisioning the Micro Services Using Postman

We provide a postman-request-collection as well as a postman-environment that defines variables that are used to hold values received in responses.
Both files are located under [postman-initial-requests folder](postman_scripts):
```console
postman_scripts/Fineract-Cn-Initial-Requests.postman_collection.json
postman_scripts/Fineract-Cn-Initial-Setup-Environment.postman_environment.json
```

Initialize Postman as follows:

1. Start Postman and load both files into Postman by clicking ```Import``` and then selecting the file.
2. You will see the collection "Fineract-Cn-Initial-Requests" in the left sidebar.
3. Open the collection by clicking on it.
4. Select the environment "Fineract-Cn-Initial-Setup-Environment" in the environment drop-down (top right corner in Postman).
5. Execute the requests one by one by selecting them in the collection and then pressing "Send".

The first request will retrieve a token. The response should look like this, with a different token:

```json
{
    "token": "Bearer eyJhbGciOiJSUzUxMiJ9.eyJhdWQiOiJwcm92aXNpb25lci12MSIsInN1YiI6IndlcGVtbmVmcmV0IiwiL21pZm9zLmlvL3NpZ25hdHVyZVRpbWVzdGFtcCI6IjIwMTctMDQtMThUMDlfNDRfMjIiLCIvbWlmb3MuaW8vdG9rZW5Db250ZW50IjoiUk9MRV9BRE1JTiIsImlzcyI6InN5c3RlbSIsImlhdCI6MTUwMDA1NjgxNywiZXhwIjoxNTAwNDE2ODE3fQ.OfxTUTStJbKQc4rAPW5PLIQYNjCG_uqcNPR4up6pIQBWLDxkgEiU9EF1WrB5NQdzXBJIHqjDFQpaVywm5DersIh4LxPGD3MZj3TqZK5_LUcZvBDTa4Xgb41e3xXkWB4TkN6KqfmiK12Ngjrrj7qZGBdtypDmFmZwKQRZIOL6T3QbI7LpbPGpeWjpWZirFgtcn5B1Z_h3r9rirCzecUdVjlaplQufxDuVFJS0R3N67pyuGQENvCAC716ID5KbokTQtITXfjnCztFuQBbtCPcYLIzxsKv_-E5k6Gd0pv01OC0XpY3NSgfAolVVgvSXKoRnL3NwAMP2yuzX6i8hR_q82Q",
    "accessTokenExpiration": "2019-07-18T22:26:57.784"
}
```

If you don't get a token there is something wrong with your setup. The token is necessary for authentication in other requests thus be sure that this steps works.
Important: Be sure to execute the requests in the right order!
The outcome is often stored in variables - check the Tests section of the requests.

Use the Postman Runner to import accounts in step 08.1.
Use the accounts_with_type.csv file found in postman_scripts and [follow the instructions](https://learning.getpostman.com/docs/postman/collection_runs/working_with_data_files/).


#### Debugging help

1. Check if the micro services to which the requests are made are up and running.
Check the container for details of failures (if any):
```console
docker-compose logs provisioner-ms
```
2. Check that apps have registered with eureka: http://localhost:8761/

3. Reach out to [mailing list](https://lists.apache.org/list.html?dev@fineract.apache.org) with the relevant details


# Sign-in using fims-web-app

Prerequisites: Fineract-CN has been successfully provisioned by following the instructions in the previous sections
User ```mifos``` is created in the the last two requests (user creation and role assignment) in the postman request-list.
This user has admin rights and is able to manage offices,customers and thier deposits.

Navigate to http://localhost:8888 in your browser and enter the credentials of the user you want to sign in with.

The following user-profile is available in fims-web-app after above setup was completed successfully:

```console
tenant: playground
user: mifos
password: password
```

### Use the Postman scripts when running locally
Postman scripts use service names (postgres, provisioner-ms, etc) when referring to different services.
If you want to use the same Postman scripts when running micro services locally then add into your hosts (/etc/hosts in Unix) file:

```console
127.0.0.1 eureka
127.0.0.1 postgres
127.0.0.1 cassandra
127.0.0.1 provisioner-ms
127.0.0.1 identity-ms
127.0.0.1 rhythm-ms
127.0.0.1 office-ms
127.0.0.1 customer-ms
127.0.0.1 accounting-ms
127.0.0.1 portfolio-ms
127.0.0.1 deposit-ms
127.0.0.1 teller-ms
127.0.0.1 reporting-ms
127.0.0.1 cheques-ms
127.0.0.1 payroll-ms
127.0.0.1 group-ms
127.0.0.1 notifications-ms
127.0.0.1 fims-web-app

```

### How to reset everything and start from scratch

Run 
```console
./shut-down-and-reset.sh 
```
or

```console
cd external_tools
docker-compose stop
docker-compose rm
docker volume rm external_tools_cassandra-volume
docker volume rm external_tools_postgres-volume
docker-compose up
```

## Integration tests
We have a shell script that verifies if the setup still works.
For this install [Newman](https://learning.getpostman.com/docs/postman/collection_runs/command_line_integration_with_newman/) and
run the script ./integration_test.sh. It takes about 15minutes to complete.
Beware that the script overwrites contents of .env file.

## Note:
**These scripts are ideal for a docker swarm deployment environment. If you are to deploy Fineract CN using Docker swarm you will have remove the network configuration from the docker-compose script and implement a load balancer (using docker swarm) that reflects the network configuration you just removed from the compose file.**

### Automating Postman scripts
You can use [Newman](https://learning.getpostman.com/docs/postman/collection_runs/command_line_integration_with_newman/) to run Postman scripts from command line.

## TODO
- Adjust scripts for Kubernetes

There are some scripts in [https://github.com/openMF/fineract-cn-containers](https://github.com/openMF/fineract-cn-containers)
that have been developed in the past for this purpose.

## References

Derived from [https://github.com/vishwasbabu/ProvisioningFineractCN](https://github.com/vishwasbabu/ProvisioningFineractCN) ,
[https://github.com/apache/fineract-cn-demo-server](https://github.com/apache/fineract-cn-demo-server)
and [https://github.com/senacor/BankingInTheCloud-Fineract](https://github.com/apache/fineract-cn-demo-server).
