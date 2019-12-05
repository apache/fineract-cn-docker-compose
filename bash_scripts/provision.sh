#!/bin/bash
set -e

function init-variables {
    CASSANDRA_REPLICATION_TYPE="Simple"
    CASSANDRA_CONTACT_POINTS="cassandra:9042"
    CASSANDRA_CLUSTER_NAME="datacenter1"
    CASSANDRA_REPLICAS="1"

    POSTGRES_DRIVER_CLASS="org.postgresql.Driver"
    POSTGRES_HOST="postgres"
    POSTGRES_PWD="postgres"
    POSTGRESQL_PORT="5432"
    POSTGRESQL_USER="postgres"

    PROVISIONER_URL="http://provisioner-ms:2020/provisioner/v1"
    IDENTITY_URL="http://identity-ms:2021/identity/v1"
    RHYTHM_URL="http://rhythm-ms:2022/rhythm/v1"
    OFFICE_URL="http://office-ms:2023/office/v1"
    CUSTOMER_URL="http://customer-ms:2024/customer/v1"
    ACCOUNTING_URL="http://accounting-ms:2025/accounting/v1"
    PORTFOLIO_URL="http://portfolio-ms:2026/portfolio/v1"
    DEPOSIT_URL="http://deposit-ms:2027/deposit/v1"
    TELLER_URL="http://teller-ms:2028/teller/v1"
    REPORT_URL="http://reporting-ms:2029/report/v1"
    CHEQUES_URL="http://cheques-ms:2030/cheques/v1"
    PAYROLL_URL="http://payroll-ms:2031/payroll/v1"
    GROUP_URL="http://group-ms:2032/group/v1"
    NOTIFICATIONS_URL="http://notifications-ms:2033/notification/v1"

    MS_VENDOR="Apache Fineract"
    IDENTITY_MS_NAME="identity-v1"
    RHYTHM_MS_NAME="rhythm-v1"
    OFFICE_MS_NAME="office-v1"
    CUSTOMER_MS_NAME="customer-v1"
    ACCOUNTING_MS_NAME="accounting-v1"
    PORTFOLIO_MS_NAME="portfolio-v1"
    DEPOSIT_MS_NAME="deposit-v1"
    TELLER_MS_NAME="teller-v1"
    REPORT_MS_NAME="report-v1"
    CHEQUES_MS_NAME="cheques-v1"
    PAYROLL_MS_NAME="payroll-v1"
    GROUP_MS_NAME="group-v1"
    NOTIFICATIONS_MS_NAME="notification-v1"
}

function config-kubernetes-addresss {
    kubectl get services -o=jsonpath="{range .items[*]}{.metadata.name}{\"=\"}{.status.loadBalancer.ingress[0].ip}{\"\n\"}{end}" > cluster_addressess.txt
    while IFS="=" read -r service ip; do
        if [[ ${#ip} -gt 0  ]]
        then
            case "$service" in
                '#'*) ;;
                "cassandra-cluster")    CASSANDRA_CONTACT_POINTS="$ip:9042" ;;
                "postgresdb-cluster")   POSTGRES_HOST="$ip" ;;
                "provisioner-service")   PROVISIONER_URL="http://$ip:2020/provisioner/v1" ;;
                "identity-service")   IDENTITY_URL="http://$ip:2021/identity/v1" ;;
                "rhythm-service")   RHYTHM_URL="http://$ip:2022/rhythm/v1" ;;
                "office-service") OFFICE_URL="http://$ip:2023/office/v1" ;;
                "customer-service")   CUSTOMER_URL="http://$ip:2024/customer/v1" ;;
                "accounting-service")   ACCOUNTING_URL="http://$ip:2025/accounting/v1" ;;
                "portfolio-service")   PORTFOLIO_URL="http://$ip:2026/portfolio/v1" ;;
                "deposit-service")   DEPOSIT_URL="http://$ip:2027/deposit/v1" ;;
                "teller-service")   TELLER_URL="http://$ip:2028/teller/v1" ;;
                "reporting-service")   REPORT_URL="http://$ip:2029/report/v1" ;;
                "cheques-service")   CHEQUES_URL="http://$ip:2030/cheques/v1" ;;
                "payroll-service")   PAYROLL_URL="http://$ip:2031/payroll/v1" ;;
                "group-service")   GROUP_URL="http://$ip:2032/group/v1" ;;
                "notification-service")   NOTIFICATIONS_URL="http://$ip:2033/notification/v1" ;;
            esac
        elif [[ ${service} != "kubernetes"  ]]
        then
            echo "$service ip has not been conigured"
            exit 1
        fi
    done < "cluster_addressess.txt"

    echo "Successfully configured kubernetes ip addresses"
}

function auto-seshat {
    TOKEN=$( curl -s -X POST -H "Content-Type: application/json" \
        "$PROVISIONER_URL"'/auth/token?grant_type=password&client_id=service-runner&username=wepemnefret&password=oS/0IiAME/2unkN1momDrhAdNKOhGykYFH/mJN20' \
         | jq --raw-output '.token' )
}

function login {
    local tenant="$1"
    local username="$2"
    local password="$3"

    ACCESS_TOKEN=$( curl -s -X POST -H "Content-Type: application/json" -H "User: guest" -H "X-Tenant-Identifier: $tenant" \
       "${IDENTITY_URL}/token?grant_type=password&username=${username}&password=${password}" \
        | jq --raw-output '.accessToken' )
}

function create-application {
    local name="$1"
    local description="$2"
    local vendor="$3"
    local homepage="$4"

    curl -X POST -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
    --data '{ "name": "'"$name"'", "description": "'"$description"'", "vendor": "'"$vendor"'", "homepage": "'"$homepage"'" }' \
     ${PROVISIONER_URL}/applications
    echo "Created microservice: $name"
}

function get-application {
    echo ""
    echo "Microservices: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/applications | jq '.'
}

function delete-application {
    local service_name="$1"

    curl -X delete -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/applications/${service_name}
    echo "Deleted microservice: $name"
}

function create-tenant {
    local identifier="$1"
    local name="$2"
    local description="$3"
    local database_name="$4"

    curl -X POST -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
    --data '{
	"identifier": "'$identifier'",
	"name": "'$name'",
	"description": "'"$description"'",
	"cassandraConnectionInfo": {
		"clusterName": "'$CASSANDRA_CLUSTER_NAME'",
		"contactPoints": "'$CASSANDRA_CONTACT_POINTS'",
		"keyspace": "'$database_name'",
		"replicationType": "'$CASSANDRA_REPLICATION_TYPE'",
		"replicas": "'$CASSANDRA_REPLICAS'"
	},
	"databaseConnectionInfo": {
		"driverClass": "'$POSTGRES_DRIVER_CLASS'",
		"databaseName": "'$database_name'",
		"host": "'$POSTGRES_HOST'",
		"port": "'$POSTGRESQL_PORT'",
		"user": "'$POSTGRESQL_USER'",
		"password": "'$POSTGRES_PWD'"
	}}' \
    ${PROVISIONER_URL}/tenants
    echo "Created tenant: $database_name"
}

function get-tenants {
    echo ""
    echo "Tenants: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/tenants | jq '.'
}

function assign-identity-ms {
    local tenant="$1"

    ADMIN_PASSWORD=$( curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" -H "X-Tenant-Identifier: $tenant" \
	--data '{ "name": "'"$IDENTITY_MS_NAME"'" }' \
	${PROVISIONER_URL}/tenants/${tenant}/identityservice | jq --raw-output '.adminPassword')
    echo "Assigned identity microservice for tenant $tenant"
}

function get-tenant-services {
    local tenant="$1"

    echo ""
    echo "$tenant services: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" -H "X-Tenant-Identifier: $tenant" ${PROVISIONER_URL}/tenants/$tenant/applications | jq '.'
}

function create-scheduler-role {
    local tenant="$1"

    curl -H "Content-Type: application/json" -H "User: antony" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "scheduler",
                "permissions": [
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__app_self",
                                "allowedOperations": ["CHANGE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "portfolio__v1__khepri",
                                "allowedOperations": ["CHANGE"]
                        }
                ]
        }' \
        ${IDENTITY_URL}/roles
    echo "Created scheduler role"
}

function create-org-admin-role {
    local tenant="$1"

    curl -H "Content-Type: application/json" -H "User: antony" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "orgadmin",
                "permissions": [
                        {
                                "permittableEndpointGroupIdentifier": "office__v1__employees",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "office__v1__offices",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__users",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__roles",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__self",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "accounting__v1__ledger",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "accounting__v1__account",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        }
                ]
        }' \
        ${IDENTITY_URL}/roles
    echo "Created organisation administrator role"
}

function create-user {
    local tenant="$1"
    local user="$2"
    local user_identifier="$3"
    local password="$4"
    local role="$5"

    curl -s -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "'"$user_identifier"'",
                "password": "'"$password"'",
                "role": "'"$role"'"
        }' \
        ${IDENTITY_URL}/users | jq '.'
    echo "Created user: $user_identifier"
}

function get-users {
    local tenant="$1"
    local user="$2"

    echo ""
    echo "Users: "
    curl -s -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" ${IDENTITY_URL}/users | jq '.'
}

function update-password {
    local tenant="$1"
    local user="$2"
    local password="$3"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "password": "'"$password"'"
        }' \
        ${IDENTITY_URL}/users/${user}/password | jq '.'
    echo "Updated $user password"
}

function provision-app {
    local tenant="$1"
    local service="$2"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
	--data '[{ "name": "'"$service"'" }]' \
	${PROVISIONER_URL}/tenants/${tenant}/applications | jq '.'
    echo "Provisioned microservice, $service for tenant, $tenant"
}

function set-application-permission-enabled-for-user {
    local tenant="$1"
    local service="$2"
    local permission="$3"
    local user="$4"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
	--data 'true' \
	${IDENTITY_URL}/applications/${service}/permissions/${permission}/users/${user}/enabled | jq '.'
    echo "Enabled permission, $permission for service $service"
}

function create_chart_of_accounts {
    local ledger_file="ledgers.csv"
    local accounts_file="accounts.csv"
    local tenant="$1"
    local user="$2"

    create_ledgers "$ledger_file" "$tenant" "$user"
    create_accounts "$accounts_file" "$tenant" "$user"
}

function create_accounts {
    local accounts_file="$1"
    local tenant="$2"
    local user="$3"

    echo ""
    echo "Creating accounts..."
    while IFS="," read -r parent_id id name; do
        if [ "$parent_id" != "parentIdentifier" ]; then
            local ledger_arr
            local ledger_type

            IFS=',' read -ra ledger_arr <<< $( grep $parent_id -m 1 ledgers.csv )
            ledger_type=${ledger_arr[3]}
            create_account "$tenant" "$user" "$parent_id" "$id" "$name" "$ledger_type"
        fi
    done < "$accounts_file"
}

function create_ledgers {
    local ledger_file="$1"
    local tenant="$2"
    local user="$3"

    echo ""
    echo "Creating ledgers..."
    while IFS="," read -r parent_id id description ledger_type show; do
        if [ "$parent_id" != "parentIdentifier" ]; then
            if [ -z "$parent_id" ]; then
                create_ledger "$tenant" "$user" "$id" "$description" "$ledger_type" "$show"
                sleep 5s
            else
                update_ledger "$tenant" "$user" "$id" "$parent_id" "$description" "$ledger_type" "$show"
            fi
        fi

    done < "$ledger_file"
}

function create_account {
    local tenant="$1"
    local user="$2"
    local parent_id="$3"
    local id="$4"
    local name="$5"
    local type="$6"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$type"'",
            "identifier": "'"$id"'",
            "name": '"$name"',
            "name": '"$name"',
            "holders": [],
            "signatureAuthorities": [],
            "balance": 0.0,
            "ledger": "'"$parent_id"'"
        }' \
        ${ACCOUNTING_URL}/accounts
    echo ""
    echo "Created account $id : $name"
}

function create_ledger {
    local tenant="$1"
    local user="$2"
    local id="$3"
    local description="$4"
    local ledger_type="$5"
    local show="$6"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$ledger_type"'",
            "identifier": "'"$id"'",
            "name": "'"$id"'",
            "description": '"$description"',
            "showAccountsInChart": '$show'
        }' \
        ${ACCOUNTING_URL}/ledgers
    echo ""
    echo "Created ledge account $id : $description"
}

function update_ledger {
    local tenant="$1"
    local user="$2"
    local id="$3"
    local parent_id="$4"
    local description="$5"
    local ledger_type="$6"
    local show="$7"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$ledger_type"'",
            "identifier": "'"$id"'",
            "name": "'"$id"'",
            "description": '"$description"',
            "parentLedgerIdentifier": "'"$parent_id"'",
            "showAccountsInChart": '$show'
        }' \
        ${ACCOUNTING_URL}/ledgers/${parent_id}
    echo "Add ledge account $id : $description to $parent_id"
}

init-variables
if [[ "$1" == "--deploy-on-kubernetes" ]]; then
    config-kubernetes-addresss
    TENANT=$2
elif [[ "$2" == "--deploy-on-kubernetes" ]]; then
    config-kubernetes-addresss
    TENANT=$1
else
    TENANT=$1
fi

auto-seshat
create-application "$IDENTITY_MS_NAME" "" "$MS_VENDOR" "$IDENTITY_URL"
create-application "$RHYTHM_MS_NAME" "" "$MS_VENDOR" "$RHYTHM_URL"
create-application "$OFFICE_MS_NAME" "" "$MS_VENDOR" "$OFFICE_URL"
create-application "$CUSTOMER_MS_NAME" "" "$MS_VENDOR" "$CUSTOMER_URL"
create-application "$ACCOUNTING_MS_NAME" "" "$MS_VENDOR" "$ACCOUNTING_URL"
create-application "$PORTFOLIO_MS_NAME" "" "$MS_VENDOR" "$PORTFOLIO_URL"
create-application "$DEPOSIT_MS_NAME" "" "$MS_VENDOR" "$DEPOSIT_URL"
create-application "$TELLER_MS_NAME" "" "$MS_VENDOR" "$TELLER_URL"
create-application "$REPORT_MS_NAME" "" "$MS_VENDOR" "$REPORT_URL"
create-application "$CHEQUES_MS_NAME" "" "$MS_VENDOR" "$CHEQUES_URL"
create-application "$PAYROLL_MS_NAME" "" "$MS_VENDOR" "$PAYROLL_URL"
create-application "$GROUP_MS_NAME" "" "$MS_VENDOR" "$GROUP_URL"
create-application "$NOTIFICATIONS_MS_NAME" "" "$MS_VENDOR" "$NOTIFICATIONS_URL"

# Set tenant identifier
create-tenant ${TENANT} "${TENANT}" "All in one Demo Server" ${TENANT}
assign-identity-ms ${TENANT}
login ${TENANT} "antony" $ADMIN_PASSWORD
provision-app ${TENANT} $RHYTHM_MS_NAME
provision-app ${TENANT} $OFFICE_MS_NAME
provision-app ${TENANT} $CUSTOMER_MS_NAME
create-org-admin-role ${TENANT}
# Base64Encode(init1@l23) = aW5pdDFAbDIz
create-user ${TENANT} "antony" "operator" "aW5pdDFAbDIz" "orgadmin"
login ${TENANT} "operator" "aW5pdDFAbDIz"
update-password ${TENANT} "operator" "aW5pdDFAbDIz"
login ${TENANT} "antony" $ADMIN_PASSWORD
create-scheduler-role ${TENANT}
# Base64Encode(p4ssw0rd) = cDRzc3cwcmQ=
create-user ${TENANT} "antony" "imhotep" "cDRzc3cwcmQ=" "scheduler"
login ${TENANT} "imhotep" "cDRzc3cwcmQ="
update-password ${TENANT} "imhotep" "cDRzc3cwcmQ="
login ${TENANT} "imhotep" "cDRzc3cwcmQ="
echo "Waiting for Rhythm to provision"
sleep 15s
set-application-permission-enabled-for-user ${TENANT} $RHYTHM_MS_NAME "identity__v1__app_self" "imhotep"
provision-app ${TENANT} $ACCOUNTING_MS_NAME
provision-app ${TENANT} $PORTFOLIO_MS_NAME
echo "Waiting for Portfolio to provision."
sleep 45s
set-application-permission-enabled-for-user ${TENANT} $RHYTHM_MS_NAME "portfolio__v1__khepri" "imhotep"
provision-app ${TENANT} $DEPOSIT_MS_NAME
provision-app ${TENANT} $TELLER_MS_NAME
provision-app ${TENANT} $REPORT_MS_NAME
provision-app ${TENANT} $CHEQUES_MS_NAME
provision-app ${TENANT} $PAYROLL_MS_NAME
provision-app ${TENANT} $GROUP_MS_NAME
provision-app ${TENANT} $NOTIFICATIONS_MS_NAME
login ${TENANT} "operator" "aW5pdDFAbDIz"
create_chart_of_accounts ${TENANT} "operator"
echo "COMPLETED PROVISIONING PROCESS."
