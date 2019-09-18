# Fineract CN Docker-Compose scripts
This project contains Docker Compose Scripts for running Fineract CN especially in Development.

## Requirements
- Docker
- Docker-compose

## Deploy and provision Fineract CN

You can either deploy and provision Fineract CN automatically using bash scripts or manually using postman.

## 1. Deploy Fineract automtically using bash scripts

 - To start up all the Fineract CN services run:

    `bash start-up.sh`
 - Then log the last Fineract CN microservice deployed by docker compose (fineract-cn-notification) to make sure all your Fineract services are now available.

    `docker logs -f fineract-cn-docker-compose_notifications-ms_1`
 - Finally provison the microservices by

    `cd bash_scripts`

    `bash provision.sh playground` #where playground is your tenant name

## 2. Deploy Fineract manually using postman

## Perquisites

### Generate .env file with RSA keys
`java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar  org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env`

This library is taken from [fineract-cn-lang](https://github.com/apache/fineract-cn-lang#generate-and-print-rsa-keys).

If needed you can pull a fresh copy of it:
`wget https://mifos.jfrog.io/mifos/libs-snapshot-local/org/apache/fineract/cn/lang/0.1.0-BUILD-SNAPSHOT/lang-0.1.0-BUILD-SNAPSHOT.jar external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar`

### Add other environment variables to the end of the .env file
`cat env_variables >> .env`

If you run some service from localhost then [add these services to your hosts file](#use-the-postman-scripts-when-running-locally).

## Procedure

### Start external tools (database, cassandra, etc)
```
cd external-tools
docker-compose up
```

### Start micro services
First only start provisioner-ms by running following in project root:

```
docker-compose up provisioner-ms
```
after it has started (and created table seshat to postgres) stop it.
This is just to make sure provisioner gets to create the database the other services require.

### Choose the services you want to run
In the docker-compose.yml (that resides in project root) there are more than 10 services defined.
Running all services together consumes a lot of memory. So you can start a subset of services.

For example you could start the following micro services and an fims-web-app:
```
docker-compose up provisioner-ms identity-ms office-ms customer-ms accounting-ms fims-web-app
```

If you want you can add other micro services (listed in docker-compose.yml) to the list.
For example you could also start `deposit-account-management-ms`

# Provision

## Provisioning the Micro Services Using Postman

We provide a postman-request-collection as well as a postman-environment that defines variables that are used to hold values received in responses.
Both files are located under [postman-initial-requests folder](postman_scripts):
```
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

```
{
    "token": "Bearer eyJhbGciOiJSUzUxMiJ9.eyJhdWQiOiJwcm92aXNpb25lci12MSIsInN1YiI6IndlcGVtbmVmcmV0IiwiL21pZm9zLmlvL3NpZ25hdHVyZVRpbWVzdGFtcCI6IjIwMTctMDQtMThUMDlfNDRfMjIiLCIvbWlmb3MuaW8vdG9rZW5Db250ZW50IjoiUk9MRV9BRE1JTiIsImlzcyI6InN5c3RlbSIsImlhdCI6MTUwMDA1NjgxNywiZXhwIjoxNTAwNDE2ODE3fQ.OfxTUTStJbKQc4rAPW5PLIQYNjCG_uqcNPR4up6pIQBWLDxkgEiU9EF1WrB5NQdzXBJIHqjDFQpaVywm5DersIh4LxPGD3MZj3TqZK5_LUcZvBDTa4Xgb41e3xXkWB4TkN6KqfmiK12Ngjrrj7qZGBdtypDmFmZwKQRZIOL6T3QbI7LpbPGpeWjpWZirFgtcn5B1Z_h3r9rirCzecUdVjlaplQufxDuVFJS0R3N67pyuGQENvCAC716ID5KbokTQtITXfjnCztFuQBbtCPcYLIzxsKv_-E5k6Gd0pv01OC0XpY3NSgfAolVVgvSXKoRnL3NwAMP2yuzX6i8hR_q82Q",
    "accessTokenExpiration": "2019-07-18T22:26:57.784"
}
```

If you don't get a token there is something wrong with your setup. The token is necessary for authentication in other requests thus be sure that this steps works.

Important: Be sure to execute the requests in the right order! If you execute the requests that gives you the initial password (request "03.2 Create Identity Service for Tenant") twice you will not be able to retrieve the initial password again (due to the implementation of the identity service).
If that happens the variable antonyUserPassword is empty (undefined) and you will not be able to sign in antony and change his password (03.3, 03.4).

6. If you didn't start the micro service deposit-account-management-ms with docker-compose then
you can assign deposits app to tenant (in step 07.1 and 07.2) but these services won't work.


#### Debugging help

1. Check if the micro services to which the requests are made are up and running.
Check the container for details of failures (if any):

docker-compose logs provisioner-ms


2. Reach out to [mailing list](https://lists.apache.org/list.html?dev@fineract.apache.org) with the relevant details


### Sign-in using fims-web-app

Prerequisites: Fineract-CN has been successfully provisioned by following the instructions in the previous sections
User ```mifos``` is created in the the last two requests (user creation and role assignment) in the postman request-list.
This user has admin rights and is able to manage offices,customers and thier deposits.

Navigate to http://localhost:8888 in your browser and enter the credentials of the user you want to sign in with.

The following user-profile is available in fims-web-app after above setup was completed successfully:

```
tenant: playground
user: mifos
password: password
```

### Use the Postman scripts when running locally
Postman scripts use service names (postgres, provisioner-ms, etc) when refering to different services.
If you want to use the same Postman scripts when running micro services locally then add into your hosts (/etc/hosts in Unix) file:

```
127.0.0.1 postgres
127.0.0.1 cassandra
127.0.0.1 provisioner-ms
127.0.0.1 identity-ms
127.0.0.1 rhythm-ms
127.0.0.1 office-ms
127.0.0.1 customer-ms
127.0.0.1 accounting-ms
127.0.0.1 portfolio-ms
127.0.0.1 deposit-account-management-ms
127.0.0.1 teller-ms
127.0.0.1 reporting-ms
127.0.0.1 cheques-ms
127.0.0.1 payroll-ms
127.0.0.1 group-ms
127.0.0.1 notifications-ms
127.0.0.1 fims-web-app

```

### How to reset everything and start from scratch

```
cd external-tools
docker-compose stop
docker-compose rm
docker volume rm external_tools_cassandra-volume
docker volume rm external_tools_postgres-volume
docker-compose up
```


## TODO

- Provision the web services using a script
- Adjust scripts for Kubernetes

There are some scripts in [https://github.com/openMF/fineract-cn-containers](https://github.com/openMF/fineract-cn-containers)
that have been developed in the past for this purpose.

## References

Derived from [https://github.com/vishwasbabu/ProvisioningFineractCN](https://github.com/vishwasbabu/ProvisioningFineractCN) ,
[https://github.com/apache/fineract-cn-demo-server](https://github.com/apache/fineract-cn-demo-server)
and [https://github.com/senacor/BankingInTheCloud-Fineract](https://github.com/apache/fineract-cn-demo-server).
