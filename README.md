# Fineract CN Docker-Compose scripts
This project contains Docker Compose Scripts for running Fineract CN especially in Development.

## Requirements
- Docker
- Docker-compose

## Perquisites

### Start-up Fineract CN microservices using bash script
 `bash start-up.sh`

### Generate .env file with RSA keys
`java -cp external_tools/lang-0.1.0-BUILD-SNAPSHOT.jar  org.apache.fineract.cn.lang.security.RsaKeyPairFactory UNIX > .env`

This library is taken from [fineract-cn-lang](https://github.com/apache/fineract-cn-lang#generate-and-print-rsa-keys).
If needed you can pull a fresh copy of it:

`wget https://mifos.jfrog.io/mifos/libs-snapshot-local/org/apache/fineract/cn/lang/0.1.0-BUILD-SNAPSHOT/lang-0.1.0-BUILD-SNAPSHOT.jar lang-0.1.0-BUILD-SNAPSHOT.jar`

### Add other environment variables to the end of the .env file
`cat env_variables >> .env`

If you run some service from localhost then you need to change the host parameter to 'localhost' of that service in .env file.

## Procedure

### Start external tools (database, cassandra, etc)
```
cd external-tools
docker-compose up
```

### Choose the services you want to run
In the docker-compose.yml (that resides in project root) comment out the services  you don't want to run.
Running all services together consumes a lot of memory.


### Start micro services

In project root directory run:
```
docker-compose up
```

## TODO

- Provision the web services
- Adjust scripts for Kubernetes

There are some scripts in [https://github.com/openMF/fineract-cn-containers](https://github.com/openMF/fineract-cn-containers)
that have been developed in the past for this purpose.
