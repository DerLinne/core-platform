# Installation

This document describes how to:

+ create the Docker image for the [Ansible Control Node](#installation-of-acn) (ACN) that is used to setup a Kubernetes cluster and deploy the Urban Data Platform into that cluster.
+ install [MicroK8s](#microk8s) on a Linux server, running Debian or Ubuntu .
+ deploy the [WebGIS prototype](#webgis-prototype) into MicroK8s.
+ deploy [CKAN](#ckan) into MicroK8s.
+ deploy [FROST](#frost) into MicroK8s.
+ deploy [DataFlow Stack](#dataflow-stack) into MicroK8s.
+ deploy [Context Management Stack](#context-management-stack) into MicroK8s.
+ deploy [Identity Management Stack](#identity-management-stack) into MicroK8s.

## Prerequisites
- [git](https://git-scm.com)
- [docker](https://www.docker.com/)
- a ([locale](http://localhost:5000/v2/_catalog)) Docker-Registry
- [Packer](https://packer.io)
- a [good](https://neovim.io/), [command line usable](https://www.vim.org/) Editor.
- a SSH key pair for the ACN user _acn_.
- a SSH key pair to access this Git repository, since it is set to _private_.
- IP address and FQDN of the Linux server where you want to install [MicroK8s](https://microk8s.io).
- Credentials to access the Linux server.
- Setup DNS records to be used with [Let's Encrypt](https://letsencrypt.org/)
- An email address for [cert-manager](https://cert-manager.io)


## Installation of ACN
```
# clone this repository
git clone git@gitlab.com:berlintxl/futr-hub/platform/data-platform-k8s.git
cd 01_setup_acn

# Edit the file 'secrets', if you need/want to provide credentials
# to log into Docker Hub
cp secrets.template secrets
vim secrets
source secrets

# Edit the file packer.env and source it.
# You need to provide:
# - the name of the SSH key for the user 'acn'
# - the name of the SSH key to access this Git repository, since it
#   is set to private.
cp packer.env.template packer.env
vim packer.env
source packer.env

# Validate the Packer file
packer validate ubuntu-20.04_docker.json

# Build the Docker image
packer build ubuntu-20.04_docker.json
```

**NOTES**
If you need to log into Docker Hub, please

- set the proper values for `DOCKER_USER` and `DOCKER_TOKEN` in the file `secrets` and source it.
- run `packer build` with the parameter `-var 'docker_login=true'`.


If the Docker image `ubuntu:20.04` is already in your local Docker registry, you can run `packer build` with the parameter `-var 'pull_image=false'`.

If you do not want Packer to push the image into the locale Docker registry, you have to edit the file `packer.env` and set the value for `FUTR_HUB_DOCKER_REGISTRY` accordingly.

If you have not set up the locale Docker registry, please run the following  command
```
docker run -d -p 5000:5000 --restart=always --name registry registry:latest
```
and edit the configuration of your Docker Daemon like the following.

```docker
"insecure-registries": [
    "localhost:5000",
  ]
```

## MicroK8s
This section describes how to install [MicroK8s](https://microk8s.io) on a Linux server via Ansible.

**NOTE**
> The installation is suited for Debian/Ubuntu If you use a different Linux distribution, the installation might fail!

All required files are located in the folder `02_setup_k8s`.

### Prerequisites
You need to make a copy of the file
`02_setup_k8s/inventory.default`
and set proper values for:

- k8s-master ansible_host
- ansible_password
- cert_manager_le_mail

before you run the Ansible playbook.

```
cd 02_setup_k8s

cp inventory.default inventory

# edit the values for the above mentioned variables.
vim inventory
```

### Installation
Please, execute the following steps to install MicroK8s.

```
# run the Ansible playbooks
cd 02_setup_k8s

ansible-playbook -i inventory -u root playbook.yml

# Wait ...
```
**NOTE**
> The file `playbook.yml` just imports the three files `setup_k8s_playbook_0[1-3]`.

**IMPORTANT**
> During the installation, the SSHD of the Linux server will be configured in a way, so that the user 'root' can no longer login with a password.

After Ansible has finished the installation, you will find the file
`/home/acn/.kube/k8s-master_config`
in the ACN container. This file will also be available in the directory `/home/acn/.kube/`, on the Linux server where you installed MicroK8s.

**NOTE**
> YOU SHOULD COPY THIS KUBECONFIG FILE TO YOUR LOCAL WORKSTATION!

### Verification
To verify the installation of MicroK8s was successfull, please execute the following command within the ACN container.
```
kubectl --kubeconfig=$HOME/.kube/k8s-master_config cluster-info
```

You should the following output:
```
Kubernetes control plane is running at https://<ip_of_your_server>:16443
CoreDNS is running at https://<ip_of_your_server>:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://<ip_of_your_server>:16443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

**NOTE**
> The IP address should match the one of your Linux server.



## WebGIS prototype
This section describes how to install the following components:

+ [PostGIS](#postgis)
+ [pgAdmin](#pgadmin)
+ [Masterportal](#masterportal)
+ [QGIS Server](#qgis-server)

### Prerequisites
- Your DNS server is setup properly, so you can create [Let's Encrypt](https://letsencrypt.org/) certificats for the Linux server, where you deployed your Kubernetes cluster onto.

- You have created an [access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) to have read-/write-access to the GitLab container registry.

- You have a kubeconfig-file, that allows you to access the K8s API server with kubectl.

**NOTE**
> If you installed MicroK8s, you will already have a kubeconfig-file in the directory `~/.kube/` with the name `k8s-master_config`.

To verify, you can connect to your K8s API server, simply run the following commands.
```
export KUBECONFIG=$HOME/.kube/k8s-master_config
kubectl cluster-info

kubectl get pods --namespace kube-system
```


The deployments of

+ CKAN
+ FROST Server
+ Grafana
+ PostgreSQL/PostGIS
+ pgAdmin
+ QGIS Server

require credentials and settings, that are defined in the inventory file of Ansible.
To setup those, you have to make a copy of the file `03_setup_k8s_platform/inventory.default` 

```
cd 03_setup_k8s_platform
cp inventory.default inventory
vim inventory
```

and set proper values for the inventory, before you continue with the installation.

**NOTE**
Please, take special note of the variable `ENVIRONMENT`. With this variable you can decide, which images of Masterportal and QGIS Server and which (sub-) domains are used.

```ini
[k8s_cluster]
k8s-master ansible_host="<ip_address>"

[localhost]
127.0.0.1   ansible_connection=local

[localhost:vars]
ansible_python_interpreter="{{ ansible_playbook_python }}"

[k8s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_password=<initial_root_password>

[all:vars]
# Common Data
FUTR_HUB_ACN_SSHKEY_PATH=$HOME/.ssh/
FUTR_HUB_ACN_SSHKEY=<name_of_keyfile>

kubeconfig_file=<name_for_local_kubeconfig_file>
working_user=<name_for_localhost_user>
working_group=<name_for_localhost_group>

# (Sub-)Domain for the Installation
DOMAIN="<domainname>"

# Name of the envrionment where to deploy to
#   - 'prod',
#   - 'staging',
#   - 'dev1' or
#   - 'dev2'.
ENVIRONMENT="<deploy_to_this_environment>"

## IDM Users
PLATFORM_ADMIN_FIRST_NAME="<firstname>"
PLATFORM_ADMIN_SURNAME="<surename>"
PLATFORM_ADMIN_EMAIL="<mail_of_platform_admin>"
IDM_REALM_MASTER_USERNAME="<mail_of_platform_admin>"
IDM_REALM_MASTER_PASSWORD="<initial_password_for_platform_admin"

# Gitlab Repo Access
GITLAB_REGISTRY_ACCESS_USER_EMAIL="<Your_GitLab_User_Email>"
GITLAB_REGISTRY_ACCESS_USER="<Your_GitLab_User>"
GITLAB_REGISTRY_ACCESS_TOKEN="<Your_GitLab_Registry_Token>"

# microk8s Config
microk8s_version='1.21/stable'

# Cert-Manager LE Email Address
cert_manager_le_mail='<le_email_address>'

## Minio settings
#
## Access Key for MinIO Tenant, base64 encoded (e.g. echo -n 'minio' | base64)
minio_tenant_accesskey='<your_access_key>'
## Secret Key for MinIO Tenant, base64 encoded (e.g. echo -n 'minio123' | base64)
minio_tenant_secretkey='<your_access_secret>'
## Passphrase to encrypt jwt payload, base64 encoded (e.g. echo -n 'SECRET' | base64)
MINIO_TENANT_CONSOLE_PBKDF_PASSPHRASE='<your_console_passphrase'
## Salt to encrypt jwt payload, base64 encoded (e.g. echo -n 'SECRET' | base64)
MINIO_TENANT_CONSOLE_PBKDF_SALT='<your_console_salt'
## MinIO User Access Key (used for Console Login), base64 encoded (e.g.  echo -n 'YOURCONSOLEACCESS' | base64)
MINIO_TENANT_CONSOLE_ACCESS_KEY='<your_soncole_access_ke>'
## MinIO User Secret Key (used for Console Login), base64 encoded (e.g. echo -n 'YOURCONSOLESECRET' | base64)
MINIO_TENANT_CONSOLE_SECRET_KEY='<your_soncole_access_ke>'

## IDM Settings
#
IDM_SCOPE='openid'
IDM_CLIENT='<your_keycloak_client>'
IDM_CLIENT_SECRET='<your_keycloak_client_secret>'
IDM_ENDP_AUTHORIZE='<your_authorize_url>'
IDM_ENDP_TOKEN='<your_token_url>'
IDM_ENDP_USER_INFO='<your_user_info_url>'
# -- server specific cookie for the secret; create a new one with `openssl rand -base64 32 | head -c 32 | base64`
OAUTH_COOKIE_SECRET='<see_generation_hint_above'
#

## IDM General Values
#
IDM_REALM = '<realm name for the platform>'
IDM_ADMIN_K8S_SECRET_NAME = '<k8s secret name for platform admin credentials>'
IDM_DB_ADMIN_SECRET_NAME = '<k8s secret name for idm database credentials>'


## Email Server values and credentials
#
EMAIL_SERVER = '<email server used to send emails i.e. smtp.x.x>'
EMAIL_USER = '<username to access email server>'
EMAIL_PASSWORD = 'password to access email server'
EMAIL_FROM = '<email address used as "from">'


# Since TimescaleDB is deployed via Zalando operator, we do not need to set TIMESCALE_PASSWORD.
# This is done by the operator during deployment of TimescaleDB.
#TIMESCALE_PASSWORD='<your_desired_timescaledb_password>'

## Master Portal Settings
#
MP_IDM_CLIENT='<your_keycloak_client>'
MP_IDM_CLIENT_SECRET='<your_keycloak_client_secret>'
MP_IDM_ENDP_USER_INFO='<your_user_info_url>'
# -- server specific cookie for the secret; create a new one with `openssl rand -base64 32 | head -c 32 | base64`
MP_OAUTH_COOKIE_SECRET='<see_generation_hint_above'

## Context Management Stack
CMS_MONGO_INITDB_DATABASE='<name_of_orion_database>'
CMS_MONGO_INITDB_ROOT_USERNAME='<name_of_mongodb_admin>'
CMS_MONGO_INITDB_ROOT_PASSWORD='<password_of_mongodb_admin>'
CMS_ORION_MONGODB_USER='<your_orion_mongodb_user>'
CMS_ORION_MONGODB_PASSWORD='<your_orion_mongodb_user_password>'

## CKAN Values
CKAN_MASTER_DB_USER='<username>'
CKAN_MASTER_DB_USER_PASSWORD='<password>'
CKAN_DB_USER='<username>'
CKAN_DB_USER_PASSWORD='<password>'
CKAN_DATASTORE_RWDB_USER='<username>'
CKAN_DATASTORE_RWDB_USER_PASSWORD='<password>'
CKAN_DATASTORE_RODB_USER='<username>'
CKAN_DATASTORE_RODB_USER_PASSWORD='<password>'
CKAN_SYSADMIN_NAME='<username>'
CKAN_SYSADMIN_PASSWORD='<password>'
CKAN_SYSADMIN_APITOKEN='<apitoken_from_ckan>'
CKAN_SYSADMIN_EMAIL='<emailaddress_of_ckan_admin>'
CKAN_SITE_TITLE='<title_of_ckan_site>'
CKAN_SITE_ID='<id_of_ckan_site>'
CKAN_SMTP_SERVER_AND_PORT='<servername:port>'
CKAN_SMTP_USER='<username>'
CKAN_SMTP_USER_PASSWORD='<password>'
CKAN_SMTP_EMAIL='<emailadress>'


# Grafana Values
GRAFANA_ADMIN='<username>'
GRAFANA_ADMIN_PASSWORD='<password>'


# Frost Values
FROST_DB_USERNAME='<username>'
FROST_DB_PASSWORD='<password>'

# Geodata Values
MAPSERVER_POSTGIS_USER='<username>'
MAPSERVER_POSTGIS_USER_PASSWORD='<password>'
MAPSERVER_POSTGIS_HOST='<hostname>'
MAPSERVER_POSTGIS_DB='<dbname>'
WEBGIS_POSTGRES_ADMIN='<admin_name>'
WEBGIS_POSTGRES_ADMIN_PASSWORD='<admin_password>'

# PGAdmin Values
PGADMIN_DEFAULT_EMAIL='<username>'
PGADMIN_DEFAULT_PASSWORD='<password>'
PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION='True'

# LDAP Values
LDAP_ADMIN_USERNAME='<username>'
LDAP_ADMIN_PASSWORD='<password>'
LDAP_USERS='<username>'
LDAP_PASSWORDS='<password>'
LDAP_ROOT='<root_dn>'
LDAP_USER_DC='<user_dc>'
LDAP_GROUP='<groupname>'
LDAP_EXTRA_SCHEMAS='<schemas>'

```

**NOTE**
To further customize the installation, you may want to take a look at the files in the folder `03_setup_k8s_platform/vars`, especially `default.yml`.

```yaml
---
# file: 03_setup_k8s_platform/vars/default.yml

# ChartMuseum
CM_PORT: 8879
CM_STORAGE: local
CM_STORAGE_LOCAL_ROOTDIR: ~/futr_hub_apps
CM_CONTEXT_PATH: charts

# Helm
HELM_REPO_URL: http://127.0.0.1
HELM_REPO_NAME: futr-hub

# Kubernetes
K8S_KUBECONFIG: "{{ lookup('env','HOME') }}/.kube/{{ kubeconfig_file }}"
K8S_CONTEXT: microk8s

K8S_NAMESPACE_APIMSTACK: apim-stack
K8S_NAMESPACE_GEODATA: geodata-stack
K8S_NAMESPACE_CKAN: metadata-stack
K8S_NAMESPACE_FROST: frost-server
K8S_NAMESPACE_POSTGRES_OPERATOR: operator-stack
K8S_NAMESPACE_PUBLIC: public-stack
K8S_NAMESPACE_DATAFLOWSTACK: dataflow-stack
K8S_NAMESPACE_MINIO_OPERATOR: operator-stack
K8S_NAMESPACE_DATA_MANAGEMENT: data-management-stack
K8S_NAMESPACE_MONITORING: monitoring-logging-stack
K8S_NAMESPACE_CONTEXT_MANAGEMENT_STACK: context-management-stack
K8S_NAMESPACE_IDMSTACK: idm-stack
K8S_NAMESPACE_KEYCLOAK_OPERATOR: idm-stack
K8S_INGRESS_CLASS: public

# GitLab-API-URL
GITLAB_API_URL: "https://gitlab.com/api/v4"

## IDM Clients
IDM_CLIENT_API_ACCESS: "api-access"
IDM_CLIENT_GRAFANA: "grafana"
IDM_CLIENT_GRAVITEE: "gravitee"
IDM_CLIENT_ADMIN_TOOLS: "admin_tools"
IDM_CLIENT_MASTERPORTAL: "masterportal"
IDM_CLIENT_CKAN: "ckan"
IDM_CLIENT_MINIO: "minio"

## IDM Groups
IDM_GROUP_DEFAULT_TENANT_NAME: "default_dataspace"

```


### PostGIS
To install [PostGIS](https://postgis.net/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_postgis_playbook.yml`.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_postgis_playbook.yml
```

When the deployment has been finished, you can then connect to the PostGIS server with the user and password, set with the Ansible inventory variables `WEBGIS_POSTGRES_ADMIN` and `WEBGIS_POSTGRES_ADMIN_PASSWORD`.


**NOTE**
> To further customize the deployment of PostGIS, you may edit the file `03_setup_k8s_platform/vars/webgis_postgis.yml`.

If you use the default values, then PostGIS can be accessed via port 5432 on the following DNS name from within your cluster:

`geodata-postgis-webgis-postgis.geodata-stack.svc.cluster.local`

To get the PostGIS user run:
```
export POSTGRES_USER=$(
    kubectl get secret --namespace geodata-stack \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_user}" | base64 -d
)
```

To get the password for this user run:
```
export POSTGRES_PASSWORD=$(
    kubectl get secret --namespace geodata-stack \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_password}" | base64 -d
)
```

To connect to your database from outside the cluster, using `psql` execute the following commands:
```
kubectl port-forward --namespace geodata-stack \
    svc/geodata-postgis-webgis-postgis 5432:5432 &

PGUSER="$POSTGRES_USER" PGPASSWORD="$POSTGRES_PASSWORD" psql \
    --host 127.0.0.1 \
    --port 5432
```

To check for PostGIS extension run (within psql):
```psql
postgres=# \dx
                                        List of installed extensions
          Name          | Version |   Schema   |                        Description
------------------------+---------+------------+------------------------------------------------------------
 fuzzystrmatch          | 1.1     | public     | determine similarities and distance between strings
 plpgsql                | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis                | 3.1.0   | public     | PostGIS geometry and geography spatial types and functions
 postgis_tiger_geocoder | 3.1.0   | tiger      | PostGIS tiger geocoder and reverse geocoder
 postgis_topology       | 3.1.0   | topology   | PostGIS topology spatial types and functions
(5 rows)
```

### pgAdmin
To install [pgAdmin](https://www.pgadmin.org/) as part of the WebGIS prototype, you must first set the values of

- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`

in the Ansible inventory file, before you run the Ansible playbook `deploy_webgis_pgadmin_playbook.yml`.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_pgadmin_playbook.yml
```

**NOTE**
> To further customize the deployment of pgAdmin, you simply need to edit the file `03_setup_k8s_platform/vars/webgis_pgadmin.yml`.

To connect to the web-interface, please execute the following commands.
```
export POD_NAME=$(
    kubectl get pods --namespace geodata-stack \
    -l "app.kubernetes.io/name=pgadmin4,app.kubernetes.io/instance=geodata-pgadmin" \
    -o jsonpath="{.items[0].metadata.name}"
)

kubectl port-forward --namespace geodata-stack $POD_NAME 8080:80
```

Now you can access pgAdmin's web-interface with the URL `https://pgadmin.your.domain`. If you have set the Ansible inventory variable `ENVIRONMENT` to a value other than `prod`, you have to add this value as a subdomain to the URL, e.g. `https://pgadmin.staging.your.domain`.

To login, use the values of the inventory's variables `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`.

A server defintion for the PostGIS database is already provided, using the values of the PostGIS installation.


### Masterportal

**IMPORTANT**
Since there is no official Docker image for Masterportal, you will have to create your own.
How to create such an image will be described further [below](#how-to-build-the-masterportal-docker-image).

To install [Masterportal](https://bitbucket.org/geowerkstatt-hamburg/masterportal/src/dev/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_masterportal_playbook.yml`. Before doing this, please install the Masterportal specific OAuth2 Proxy.

To activate the authentication for masterportal set the following variables in the `inventory`:

```
# Master Portal Settings
MP_IDM_CLIENT='<your_keycloak_client>'
MP_IDM_CLIENT_SECRET='<your_keycloak_client_secret>'
MP_IDM_ENDP_USER_INFO='<your_user_info_url>'
# -- server specific cookie for the secret; create a new one with `openssl rand -base64 32 | head -c 32 | base64`
MP_OAUTH_COOKIE_SECRET='<see_generation_hint_above'
```

Install OAuth2 Proxy for Masterportal
```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_oauth2_masterportal_proxy.yml
```

Install Masterportal (after you have created the Docker image).
```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_masterportal_playbook.yml
```

To access the Masterportal you have to open the URL `https://masterportal.your.domain/` in your Web browser, whereas `your.domain` is the value you set the Ansible inventory variable `DOMAIN` to. If you have set the Ansible inventory variable `ENVIRONMENT` to a value other than `prod`, you have to add this value as a subdomain to the URL, e.g. `https://masterportal.staging.your.domain`.

Since there is no official Docker image for Masterportal you will have to create your own.

#### How to build the Masterportal Docker image
To build the Docker image, use this Dockerfile.

```docker
FROM nginx:1.19

COPY static /usr/share/nginx/html

VOLUME /usr/share/nginx/html
VOLUME /etc/nginx

```

and tag the image with the value of the Ansible inventory variable `ENVIRONMENT`.
The folder `static` contains the code `2.7.2` of Masterportal (`mastercode/2_7_2`) and the configuration/adjustments (`webgis-masterportal`).

**NOTE**
You have to make sure that the URLs within `static/webgis-masterportal/resources/services-internet.json`, pointing to your QGIS Server, match your environment.

If you want to automatically replace the URLs within `static/webgis-masterportal/resources/services-internet.json` to match the value of `ENVIRONMENT`, you may install the following script as a Git pre-commit hook and replace the values of `OLD_MAPSERVER` and `NEW_MAPSERVER` accordingly.

```bash
# After creating the script `pre-commit.sh` in your Git working directory ...
chmod +x pre-commit.sh 
ln -s ../../pre-commit.sh .git/hooks/pre-commit
```
<br>

```bash
#!/bin/sh

# Replace the URL of the FUTR-HUB mapserver for environment 'staging' within
# the file services-internet.json.

# Where to find services-internet.json?
REPO_PATH=$(git rev-parse --show-toplevel --sq)
SUBFOLDER='static/webgis-masterportal/resources'
SERVICES_INTERNET="${REPO_PATH}/${SUBFOLDER}/services-internet.json"

# services-internet.json: Set default/old URL.
OLD_MAPSERVER='mapserver.old.domain/qgis-server'
# This will be replaced with the following URL.
NEW_MAPSERVER='mapserver.staging.new.domain/qgis-server'

if [ ! -f "${SERVICES_INTERNET}" ]; then
  echo "Could not find file services-internet.json"
  exit 1
fi

# Perform string replacement.
sed -i "s|${OLD_MAPSERVER}|${NEW_MAPSERVER}|g" "${SERVICES_INTERNET}"

# (Re-)Add project.qgs file
git add "${SERVICES_INTERNET}"


# Paranoia check
grep -e "${OLD_MAPSERVER}" "${SERVICES_INTERNET}"
PARANOIA=$?
if [ $PARANOIA -ne 0 ]; then
  exit 0
else
  echo "ERROR: some replacements were unsuccessful."
  exit 1
fi
```

If you use a Gitlab CI/CD pipeline, you may want to create a branch for each environment (prod, staging, dev1 and dev2) and use the following configuration (it uses `staging` as environment) to build the Docker image and push it into the Gitlab registry.

```yaml
workflow: # run pipeline jobs for tags and pushes to staging by default
  rules:
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == "staging"

services:
  - docker:dind

stages:
  - build

do build:
  tags:
    - shared
  image: docker:stable
  stage: build
  before_script:
    - docker info
    - env
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY

  script:
    - docker build -t "$CI_COMMIT_BRANCH" .
    - docker tag "$CI_COMMIT_BRANCH" "$CI_REGISTRY_IMAGE:$CI_COMMIT_BRANCH"
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_BRANCH"

```

**NOTE**
Please, make sure that you change the line

```yaml
    - if: $CI_COMMIT_BRANCH == "staging"
```
if you use a different value for `ENVIRONMENT`.


### QGIS Server

**IMPORTANT**
Since there is no official Docker image for QGIS Server, you will have to create your own. 
How to create such an image will be described further [below](#how-to-build-the-qgis-server-docker-image).


To install [QGIS Server](https://docs.qgis.org/3.16/en/docs/server_manual/index.html) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_qgisserver_playbook.yml`, after you have created the Docker image of QGIS Server.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_qgisserver_playbook.yml
```

The deployment creates the ConfigMap `qgis-nginx.conf` and the Secret `geodata-qgisserver-webgis-qgisserver`.
The later one contains the values for the file `pg_service.conf` that is mounted into the QGIS Server pod. An according database and its user will be created within the PostGIS Pod.

The file `pg_service.conf` has the following content.

```ini
[qwc_geodb]
host=name-of-yourwebgis-postgis
port=5432
dbname=name_of_your_qgis_database
user=user_to_access_qgis_database
password=password_to_access_qgis_database
sslmode=disable
```

The values of

- host
- dbname
- user
- password

are set in the Ansible inventory through these variables.

- MAPSERVER_POSTGIS_HOST
- MAPSERVER_POSTGIS_DB
- MAPSERVER_POSTGIS_USER
- MAPSERVER_POSTGIS_USER_PASSWORD


The QGIS project file `project.qgs` is part of the QGIS Server Docker image, that you host in a [GitLab repository](https://gitlab.com/berlintxl/futr-hub/platform/qgis-server-customizing/-/blob/master/project.qgs).

You have to define the the path to this GitLab project in the file `03_setup_k8s_platform/vars/webgis_qgisserver.yml`.

```yaml

# file: 03_setup_k8s_platform/vars/webgis_qgisserver.yml

server_image_repository: "the/path/to/QGIS_Docker_image/GitLab_project"
```

If you want QGIS Server to use a new version of your QGIS project file, you have to

+ commit your new `project.qgs` into the Git repo of the QGIS Server Docker image,
+ wait until the new image has been build and then
+ update the QGIS Server Pod by running the Ansible playbook `update_qgis_project.yml`.

```
cd 03_setup_k8s_platform
ansible-playbook -i inventory update_qgis_project_playbook.yml
```

To reach your QGIS Server from the Internet via HTTPS, you have to

- make sure, that the Nginx Ingress Controler and the CertManager are setup for your K8s cluster.
- set `DOMAIN=<your domain>` in the Ansible inventory file.
- make sure that `ingress_enabled` in `vars/webgis_qgisserver.yml` is set to `true`.

If you want to change the host name from `mapserver` to something else, please edit 

- `nginx_server_name`
- `ingress_host`

in the file `vars/webgis_qgisserver.yml` accordingly and make sure your DNS server can resolve this host name. Also keep in mind to change any URLs that are pointing to the Mapserver, e.g. Masterportal.

To allow access to the data of QGIS Server, [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) is enabled in the Nginx ConfigMap `qgis-nginx.conf`. You can set the value of the HTTP header `Access-Control-Allow-Origin` for request methods `POST`, `GET` and `OPTIONS`, using the parameter `nginx_cors_origin`. The default is, that every host of your domain `DOMAIN` can use those access methods.

You can either edit the content of the Nginx ConfigMap by using `kubectl edit`, after deployment, or by editing the template file `files/helmcharts/webgis-qgisserver/templates/http-configmap.yaml` before deployment.


To verify that the deployment was successful, open the URL

https://mapserver.your.domain/qgis/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities

in your Web browser.


#### How to build the QGIS Server Docker image
To build the Docker image, use this Dockerfile.

```docker
FROM debian:buster-slim

ENV LANG=en_EN.UTF-8


RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        gnupg \
        ca-certificates \
        wget \
        locales \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    # Add the current key for package downloading - As the key changes every year at least
    # Please refer to QGIS install documentation and replace it with the latest one https://www.qgis.org/en/site/forusers/alldownloads.html#linux
    && wget -O - https://qgis.org/downloads/qgis-2021.gpg.key | gpg --import \
    && gpg --export --armor 46B5721DBBD2996A | apt-key add - \
    && echo "deb http://qgis.org/debian buster main" >> /etc/apt/sources.list.d/qgis.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        qgis-server \
        spawn-fcgi \
        xauth \
        xvfb \
    && apt-get remove --purge -y \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m qgis

ENV TINI_VERSION v0.17.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_SERVER_LOG_STDERR 1
ENV QGIS_SERVER_LOG_LEVEL 2

COPY data /data/qgis
RUN chmod -R 777 /data/qgis/
RUN chown -R qgis:qgis /data/qgis

COPY cmd.sh /home/qgis/cmd.sh
RUN chmod -R 777 /home/qgis/cmd.sh
RUN chown qgis:qgis /home/qgis/cmd.sh

USER qgis
WORKDIR /home/qgis

ENTRYPOINT ["/tini", "--"]

CMD ["/home/qgis/cmd.sh"]

```

and tag the image with the value of the Ansible inventory variable ENVIRONMENT.

The script `cmd.sh` has the following content.

```bash
#!/bin/bash

[[ $DEBUG == "1" ]] && env

exec /usr/bin/xvfb-run --auto-servernum --server-num=1 /usr/bin/spawn-fcgi -p 5555 -n -d /home/qgis -- /usr/lib/cgi-bin/qgis_mapserv.fcgi
```

**NOTE**
Your QGIS project file `project.qgs` should be put within the directory `data`. If you need to put the project file in a subfolder within the directory `data`, you also have to change the value of `qgis_data_dir` in the file `vars/webgis_qgisserver.yml`, before you deploy QGIS Server.


If you use a Gitlab CI/CD pipeline, you may want to create a branch for each environment (prod, staging, dev1 and dev2) and use the following configuration to build the Docker image and push it into the Gitlab registry.

```yaml
services:
  - docker:dind

stages:
  - build

do build:
  tags:
    - shared
  image: docker:stable
  stage: build
  before_script:
    - docker info
    - env
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY

  script:
    - docker build -t "$CI_COMMIT_BRANCH" .
    - docker tag "$CI_COMMIT_BRANCH" "$CI_REGISTRY_IMAGE:$CI_COMMIT_BRANCH"
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_BRANCH"


```

**NOTE**
You have to make sure that the URLs within `project.qgs`, pointing to your QGIS Server, match your environment.

If you want to automatically replace the URLs within `project.qgs` to match the value of `ENVIRONMENT` (in this case: `staging`), you may install the following script as a Git pre-commit hook and replace the values of `SUBFOLDER`, `OLD_WFSUrl`, `NEW_WFSUrl`, `OLD_WMSOnlineResource` and `NEW_WMSOnlineResource` accordingly. It also removes credentials that might be in the project file.

```bash
# After creating the script `pre-commit.sh` in your Git working directory ...
chmod +x pre-commit.sh 
ln -s ../../pre-commit.sh .git/hooks/pre-commit
```
<br>

```bash
#!/bin/sh

# Perform the followinbg string replacements in file project.qgs:
#
# - s/dbname=.* host=.* port=[0-9]*/service='qwc_geodb'/g
# - s/authcfg=[0-9a-zAZ]*//g

# Where to find project.qgs?
REPO_PATH=$(git rev-parse --show-toplevel --sq)
SUBFOLDER='data/wfsbasis'
PROJECT_QGS="${REPO_PATH}/${SUBFOLDER}/project.qgs"

# Name of service to be used by PostgreSQL
PG_SERVICE_CONF='qwc_geodb'

# project.qgs: Set default/old values of WFSUrl and WMSOnlineResource.
OLD_WFSUrl='mapserver.old.domain/qgis-server'
OLD_WMSOnlineResource='mapserver.old.domain/qgis-server'
# Those will be replaced with the following values.
NEW_WFSUrl='mapserver.staging.new.domain/qgis-server'
NEW_WMSOnlineResource='mapserver.staging.new.domain/qgis-server'

if [ ! -f "${PROJECT_QGS}" ]; then
  echo "Could not find file project.qgs"
  exit 1
fi

# Perform string replacement.
sed -i "s/user='[^\']*'\s\{0,1\}//g" "${PROJECT_QGS}"
sed -i "s/password='[^\']*'\s\{0,1\}//g" "${PROJECT_QGS}"
sed -i "s/dbname=.* host=.* port=[0-9]*/service='${PG_SERVICE_CONF}'/g" "${PROJECT_QGS}"
sed -i "s/authcfg=[0-9a-zAZ]*//g" "${PROJECT_QGS}"
sed -i "s|${OLD_WFSUrl}|${NEW_WFSUrl}|g" "${PROJECT_QGS}"
sed -i "s|${OLD_WMSOnlineResource}|${NEW_WMSOnlineResource}|g" "${PROJECT_QGS}"

# (Re-)Add project.qgs file
git add "${PROJECT_QGS}"


# Paranoia check
grep \
  -e "user" \
  -e "password" \
  -e "dbname=" \
  -e "host=" \
  -e "port=" \
  -e "authcfg=" \
  -e "${OLD_WFSUrl}" \
  -e "${OLD_WMSOnlineResource}" "${PROJECT_QGS}"
PARANOIA=$?
if [ $PARANOIA -ne 0 ]; then
  exit 0
else
  echo "ERROR: some replacements were unsuccessful."
  exit 1
fi
```

## CKAN

[CKAN](https://ckan.org) is a data management system and in this chapter we will describe how to deploy it into MicroK8s.

The deployment is done via Ansible, using the Helm chart [keitaro-charts/ckan](https://github.com/keitaroinc/ckan-helm) from [Keitaro](https://keitaro.com/).

To deploy CKAN, simply run the Ansible playbook `deploy_ckan_playbook.yml`. This will deploy CKAN in the K8s namespace _ckan_.

---
**IMPORTANT**
Please, make sure you edit the file `vars/ckan_ckan.yml` before you run the playbook!
Especially keys beginning with

+ ckan_ ,
+ smtp_ ,
+ ingress_ and
+ tls_

If you want to use Træfik as your ingress controller, you have to set
```
# Set to true, if using ingress-nginx
ingress_enabled: false
...
# Set to true, if using Træfik
ingressRoute_enabled: true
ingressRoute_host: "<FQDN.of.your.ckan.site>"
```

The FQDN of the key `ckan_siteUrl` has to match the FQDN of `ingress_host`, resp. ingressRoute_host!

---

```yaml
---
# file: 03_setup_k8s_platform/vars/ckan_ckan.yml

HELM_REPO_NAME: keitaro-charts
HELM_REPO_URL: https://keitaro-charts.storage.googleapis.com
HELM_CHART_NAME: ckan
HELM_RELEASE_NAME: ckan

image_registry: "docker.io"
image_repository: "keitaro/ckan"
image_tag: "2.9.2"
image_pullPolicy: IfNotPresent

pvc_enabled: true
pvc_size: "1Gi"

DBDeploymentName: "postgres"
RedisName: "redis"
SolrName: "solr"
DatapusherName: "datapusher"
DBHost: "postgres"
MasterDBName: "postgres"
MasterDBUser: "{{ CKAN_MASTER_DB_USER }}"
MasterDBPass: "{{ CKAN_MASTER_DB_USER_PASSWORD }}"

CkanDBName: "ckan_default"
CkanDBUser: "{{ CKAN_DB_USER }}"
CkanDBPass: "{{ CKAN_DB_USER_PASSWORD }}"
DatastoreDBName: "datastore_default"
DatastoreRWDBUser: "{{ CKAN_DATASTORE_RODB_USER }}"
DatastoreRWDBPass: "{{ CKAN_DATASTORE_RODB_USER_PASSWORD }}"
DatastoreRODBUser: "{{ CKAN_DATASTORE_RWDB_USER }}"
DatastoreRODBPass: "{{ CKAN_DATASTORE_RWDB_USER_PASSWORD }}"

ckan_sysadminName: "{{ CKAN_SYSADMIN_NAME }}"
ckan_sysadminPassword: "{{ CKAN_SYSADMIN_PASSWORD }}"
ckan_sysadminApiToken: "{{ CKAN_SYSADMIN_APITOKEN }}"
ckan_sysadminEmail: "postmaster@domain.com"
ckan_siteTitle: "Site Title here"
ckan_siteId: "site-id-here"
ckan_siteUrl: "https://<Your_FQDN>"
ckan_ckanPlugins: "envvars image_view text_view recline_view datastore datapusher"
ckan_storagePath: "/var/lib/ckan/default"
ckan_activityStreamsEmailNotifications: "false"
ckan_debug: "false"
ckan_maintenanceMode: "false"

psql_initialize: true

solr_url: "http://solr-headless:8983/solr/ckancollection"

redis_url: "redis://redis-headless:6379/0"

spatialBackend: "solr"

locale_offered: "en"
locale_default: "en"

datapusherUrl: "http://datapusher-headless:8000"

datapusherCallbackUrlBase: http://ckan

smtp_server: "smtpServerURLorIP:port"
smtp_user: "{{ CKAN_SMTP_USER }}"
smtp_password: "{{ CKAN_SMTP_USER_PASSWORD }}"
smtp_mailFrom: "postmaster@domain.com"
smtp_tls : "enabled"
smtp_starttls: "true"

issues_sendEmailNotifications: "false"

extraEnv: []

readiness_initialDelaySeconds: 10
readiness_periodSeconds: 10
readiness_failureThreshold: 6
readiness_timeoutSeconds: 10

liveness_initialDelaySeconds: 10
liveness_periodSeconds: 10
liveness_failureThreshold: 6
liveness_timeoutSeconds: 10

serviceAccount_create: false
serviceAccount_annotations: {}
serviceAccount_name:

podSecurityContext: {}

securityContext: {}

service_type: ClusterIP
service_port: 80

# Set to true, if using ingress-nginx
ingress_enabled: true
ingress_class: "public"
ingress_host: "<Your_FQDN>"
tls_acme: true
tls_secretName: "<Your_FQDN>-tls"

# Set to true, if using Træfik
ingressRoute_enabled: false
ingressRoute_host: "<Your_FQDN>"

datapusher_enabled: true
datapusher_maxContentLength: "102400000"
datapusher_chunkSize: "10240000"
datapusher_insertRows: "50000"
datapusher_downloadTimeout: "300"
datapusher_datapusherSslVerify: "False"
datapusherRewriteResources: "True"
datapusher_datapusherRewriteUrl: "http://ckan"

redis_enabled: true
redis_cluster_enabled: false
redis_master_persistence_enabled: false
redis_master_persistence_size: 1Gi
redis_usePassword: false

solr_enabled: true
solr_initialize_enabled: true
solr_initialize_numShards: 2
solr_initialize_replicationFactor: 1
solr_initialize_maxShardsPerNode: 10
solr_initialize_configsetName: ckanConfigSet
solr_replicaCount: 1
solr_volumeClaimTemplates_storageSize: 5Gi
solr_image_repository: solr
solr_image_tag: "6.6.6"
solr_zookeeper_replicaCount: 1
solr_zookeeper_persistence_size: 1Gi

postgresql_enabled: true
postgresql_persistence_size: 1Gi

```

For more information about the values that are set in `vars/ckan_ckan.yml`, see [this](https://github.com/keitaroinc/ckan-helm#chart-values) link. And for more information about the administration and configuration, please consult CKAN's official [documentation](https://docs.ckan.org/en/2.9/).

---


```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_ckan_playbook.yml
```


Now you have to generate an API Token for the sysadmin user using the CKAN UI and replace the secret with the new value at runtime.

```
kubectl -n ckan create secret generic ckansysadminapitoken --from-literal=sysadminApiToken={insert_generated_api_token_here} --dry-run -o yaml | kubectl apply -f -
```

**NOTE**
>If you want to re-deploy/update your CKAN deployment, please use your API Token as value for the key `ckan_sysadminApiToken` in the file `vars/ckan_ckan.yml`.

### FROST

[FROST Server](https://fraunhoferiosb.github.io/FROST-Server/) is a server implementation of the OGC SensorThings API, and in this chapter we will describe how to deploy it into MicroK8s.

The deployment is done via Ansible, using the Helm chart [frost-server](https://github.com/FraunhoferIOSB/FROST-Server/tree/master/helm/frost-server).

To deploy FROST Server, simply run the Ansible playbook `deploy_frost_playbook.yml`. This will deploy FROST Server in the K8s namespace _frost-server_.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_frost_playbook.yml
```


You can than reach FROST Server with this URL: http://frost.your.domain:30888/FROST-Server/

**NOTE**
>This installation of FROST Server does use PostgreSQL + PostGIS extension, deployed via the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator). Therefore, during the installation, the PostGIS server deployed by the Helm chart will be deleted.

You can change values regarding FROST Server by editing the file `vars/frost_frost.yml`.

**IMPORTANT**
If you change the value `name` in file `vars/frost_frost.yml` **YOU HAVE TO CHANGE** the value `cluster_team` in `vars/frost_postgis` to the same value!

**VERY IMPORTANT**
DO NOT CHANGE THE VALUES

```yaml
frost_db_database: "sensorthings"
frost_db_username: "{{ FROST_DB_USERNAME }}"
```

IN FILE `vars/frost_frost.yml` UNLESS YOU KNOW WHAT YOU ARE DOING!

```yaml
---
# file: 03_setup_k8s_platform/vars/frost_frost.yml

HELM_REPO_NAME: fraunhoferiosb
HELM_REPO_URL: https://fraunhoferiosb.github.io/helm-charts/
HELM_CHART_NAME: frost-server
HELM_RELEASE_NAME: frost-server

# FROST settings
name: frost-server
frost_enableActuation: true
frost_http_replicas: 1
frost_http_ports_http_nodePort: 30888
frost_http_ports_http_servicePort: 80
frost_http_ingress_enabled: false
frost_http_ingress_rewriteAnnotation: nginx.ingress.kubernetes.io/rewrite-target
frost_http_ingress_rewriteTraget: /FROST-Server/$1
frost_http_ingress_path: /(.*)
frost_http_serviceHost: frost-server-frost-server-http.frost-server
frost_http_serviceProtocol: http
frost_http_servicePort: null
frost_http_urlSubPath: null
frost_http_defaultCount: false
frost_http_defaultTop: 100
frost_http_maxTop: 1000
frost_http_maxDataSize: 25000000
frost_http_useAbsoluteNavigationLinks: true
frost_http_db_autoUpdate: true
frost_http_db_alwaysOrderbyId: false
frost_http_db_maximumConnection: 10
frost_http_db_maximumIdleConnection: 10
frost_http_db_minimumIdleConnection: 10
frost_http_bus_sendWorkerPoolSize: 10
frost_http_bus_sendQueueSize: 100
frost_http_bus_recvWorkerPoolSize: 10
frost_http_bus_recvQueueSize: 100
frost_http_bus_maxInFlight: 50
frost_http_image_registry: docker.io
frost_http_image_repository: fraunhoferiosb/frost-server-http
frost_http_image_tag: 1.13.1
frost_http_image_pullPolicy: IfNotPresent
frost_db_ports_postgresql_servicePort: 5432
frost_db_persistence_enabled: false
frost_db_persistence_existingClaim: null
frost_db_persistence_storageClassName: null
frost_db_persistence_accessModes: ReadWriteOnce
frost_db_persistence_capacity: 10Gi
frost_db_persistence_local_nodeMountPath: /mnt/frost-server-db
# NOTE: the value of frost_db_password will be replaced with the password, created by Zalando PostgreSQL operator)
frost_db_database: "sensorthings"
frost_db_username: "{{ FROST_DB_USERNAME }}"
frost_db_password: "{{ FROST_DB_PASSWORD }}"
frost_db_idGenerationMode: ServerGeneratedOnly
frost_db_implementationClass: de.fraunhofer.iosb.ilt.sta.persistence.postgres.longid.PostgresPersistenceManagerLong
frost_db_image_registry: docker.io
frost_db_image_repository: postgis/postgis
frost_db_image_tag: 11-2.5-alpine
frost_db_image_pullPolicy: IfNotPresent
frost_mqtt_enabled: true
frost_mqtt_replicas: 1
frost_mqtt_ports_mqtt_nodePort:
frost_mqtt_ports_mqtt_servicePort: 1833
frost_mqtt_ports_websocket_nodePort:
frost_mqtt_ports_websocket_servicePort: 9876
frost_mqtt_stickySessionTimeout: 10800
frost_mqtt_qos: 2
frost_mqtt_subscribeMessageQueueSize: 100
frost_mqtt_subscribeThreadPoolSize: 10
frost_mqtt_createMessageQueueSize: 100
frost_mqtt_createThreadPoolSize: 10
frost_mqtt_maxInFlight: 50
frost_mqtt_waitForEnter: false
frost_mqtt_db_alwaysOrderbyId: false
frost_mqtt_db_maximumConnection: 10
frost_mqtt_db_maximumIdleConnection: 10
frost_mqtt_db_minimumIdleConnection: 10
frost_mqtt_bus_sendWorkerPoolSize: 10
frost_mqtt_bus_sendQueueSize: 100
frost_mqtt_bus_recvWorkerPoolSize: 10
frost_mqtt_bus_recvQueueSize: 100
frost_mqtt_bus_maxInFlight: 50
frost_mqtt_image_registry: docker.io
frost_mqtt_image_repository: fraunhoferiosb/frost-server-mqtt
frost_mqtt_image_tag: 1.13.1
frost_mqtt_image_pullPolicy: IfNotPresent
frost_bus_ports_bus_servicePort: 1883
frost_bus_implementationClass: de.fraunhofer.iosb.ilt.sta.messagebus.MqttMessageBus
frost_bus_topicName: FROST-Bus
frost_bus_qosLevel: 2
frost_bus_image_registry: docker.io
frost_bus_image_repository: eclipse-mosquitto
frost_bus_image_tag: 1.4.12
frost_bus_image_pullPolicy: IfNotPresent

```

```yaml
---
# file: 03_setup_k8s_platform/vars/frost_postgis.yml
# Settings for Zalando operator for PostgreSQL
cluster_name: "frost-server-db"
cluster_team: "frost-server"

```

### Data Management Stack

To install the data Management sSteck, the following Values have to be set in the `ìnventory` for the payload playbook.


```yaml
## Minio settings

## Access Key for MinIO Tenant, base64 encoded (e.g. echo -n 'minio' | base64)
minio_tenant_accesskey='<your_access_key>'
## Secret Key for MinIO Tenant, base64 encoded (e.g. echo -n 'minio123' | base64)
minio_tenant_secretkey='<your_access_secret>'
## Passphrase to encrypt jwt payload, base64 encoded (e.g. echo -n 'SECRET' | base64)
MINIO_TENANT_CONSOLE_PBKDF_PASSPHRASE='<your_console_passphrase'
## Salt to encrypt jwt payload, base64 encoded (e.g. echo -n 'SECRET' | base64)
MINIO_TENANT_CONSOLE_PBKDF_SALT='<your_console_salt'
## MinIO User Access Key (used for Console Login), base64 encoded (e.g.  echo -n 'YOURCONSOLEACCESS' | base64)
MINIO_TENANT_CONSOLE_ACCESS_KEY='<your_soncole_access_ke>'
## MinIO User Secret Key (used for Console Login), base64 encoded (e.g. echo -n 'YOURCONSOLESECRET' | base64)
MINIO_TENANT_CONSOLE_SECRET_KEY='<your_soncole_access_ke>'
```

For minio the creation of each values is described in the comment above the needed values.

The IDM Settings have to be taken from the corresponding IDM to use.

The TimescaleDB Password can be free defined.

To set these values, execute the following:

```bash
cd 03_setup_k8s_platform
cp inventory.default inventory

# edit the values for the above mentioned variables.
vim inventory
```

After doing this, you can install the stack by step for step executing these commands:


Install PostgreSQL Operator
```
ansible-playbook -i inventory deploy_postgres_operator_playbook.yml
```

Install first TimescaleDB
```
ansible-playbook -i inventory deploy_timescale_playbook.yml
```

Install and configure Grafana
```
ansible-playbook -i inventory deploy_grafana_playbook.yml
```

Install minio Operator
```
ansible-playbook -i inventory deploy_minio_operator_playbook.yml
```

Install Minio Tenant
```
ansible-playbook -i inventory deploy_minio_tenant_playbook.yml 
```
### Public Stack

To install the public Stack set the following variables in the `inventory`:

```
## IDM Settings

IDM_SCOPE='openid'
IDM_CLIENT='<you_keycloak_client>'
IDM_CLIENT_SECRET='<your_keycloak_client_secret>'
IDM_ENDP_AUTHORIZE='<your_authorize_url>'
IDM_ENDP_TOKEN='<your_token_url>'
IDM_ENDP_USER_INFO='<your_user_info_url>'
```

Install OAuth2 Proxy Tenant
```
ansible-playbook -i inventory deploy_public_oauth2_playbook.yml 
```



## Monitoring Stack

Make sure the above mentioned IDM Settings are correctly set for deployment.

Install Loki & Promtail
```
ansible-playbook -i inventory deploy_monitoring_loki.yml
```

Install Grafana
```
ansible-playbook -i inventory deploy_monitoring_grafana.yml
```

## DataFlow Stack

The DataFlow Stack contains event-driven applications, that use [NodeRed](https://nodered.org/).
As of now the following NodeRed applications are deployed:

- [01_show_last_tweet](https://nr-show-last-tweet.your.domain)
- [05_luftdaten_info](https://nr-luftdaten-info.your.domain)
- [06_sensebox](https://nr-sensebox.your.domain)
- [07_switch_lights](https://nr-switch-lights.your.domain)
- [08_indicate_energy](https://nr-indicate-energy.your.domain)
- [09_paxcounter](https://nr-paxcounter.your.domain)

For further details, please take a look at [this](https://gitlab.com/berlintxl/futr-hub/platform/data-platform/-/tree/master/05_usecases) GitLab repository.

The deployment is done via Ansible, using this [Helm chart](https://gitlab.com/berlintxl/futr-hub/platform/data-platform-k8s/-/tree/master/03_setup_k8s_platform/files/helmcharts/dataflow-nodered), that is derived from the (now deprecated) Helm chart [stable/node-red](https://github.com/helm/charts/tree/master/stable/node-red) .

To deploy NodeRed, simply run the Ansible playbook `deploy_frost_playbook.yml`. This will deploy all NodeRed applications in the K8s namespace _dataflow-stack_.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_dataflow_stack.yml
```


If you want to deploy a certain NodeRed application (use case), you can use tags.

```
cd 03_setup_k8s_platform

ansible-playbook -i inventory deploy_dataflow_stack.yml --tags "uc01"
```

The following tags are available:

| Tag  | Use Case               |
| :--- | :----------------------|
| uc01 | 01_show_last_tweet.yml |
| uc05 | 05_luftdaten_info.yml  |
| uc06 | 06_sensebox.yml        |
| uc07 | 07_switch_lights.yml   |
| uc08 | 08_indicate_energy.yml |
| uc09 | 09_paxcounter.yml      |

If you want to add other use cases, you simply

- create a new Ansible task-file in `03_setup_k8s_platform/tasks/dataflow-stack/`,
- create a new Ansible var-file in `03_setup_k8s_platform/vars/dataflow-stack/`,
- import the Ansible task-file in the Ansible playbook `03_setup_k8s_platform/deploy_dataflow_stack.yml`, and
- tag this import, using `tags`.

The values of the Helm chart are overriden by using the Ansible template `03_setup_k8s_platform/templates/dataflow-stack/dataflow_nodered_values.yaml.j2`,

```yaml
# Default values for dataflow-nodered.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: "{{ nodered.replicaCount }}"

strategyType: "{{ nodered.strategyType }}"

image:
  repository: "{{ nodered.image_repository }}"
  tag: "{{ nodered.image_tag }}"
  pullPolicy: "{{ nodered.image_pullPolicy }}"

nameOverride: "{{ nodered.nameOverride }}"
fullnameOverride: "{{ nodered.fullnameOverride }}"

livenessProbePath: "{{ nodered.livenessProbePath }}"
readinessProbePath: "{{ nodered.readinessProbePath }}"

flows: "{{ nodered.flows }}"
safeMode: "{{ nodered.safeMode }}"
enableProjects: "{{ nodered.enableProjects }}"
nodeOptions: "{{ nodered.nodeOptions }}"
extraEnvs: {{ nodered.extraEnvs }}
timezone: "{{ nodered.timezone }}"

podAnnotations: {}

service:
  type: "{{ nodered.service_type }}"
  port: "{{ nodered.service_port }}"

ingress:
  enabled: "{{ nodered.ingress_enabled }}"
  annotations:
    kubernetes.io/ingress.class: "{{ nodered.ingress_class }}"
    kubernetes.io/tls-acme: "{{ nodered.ingress_tls_acme }}"

  hosts:
    - host: "{{ nodered.ingress_host }}"
      paths:
        - path: "{{ nodered.ingress_host_path }}"
          pathType: "{{ nodered.ingress_host_pathType }}"

  tls:
    - secretName: "{{ nodered.ingress_tls_secret }}"
      hosts:
        - "{{ nodered.ingress_host }}"

persistence:
  enabled: "{{ nodered.persistence_enabled }}"
  storageClass: "{{ nodered.persistence_storageClass }}"
  accessMode: "{{ nodered.persistence_accessMode }}"
  size: "{{ nodered.persistence_size }}"
  subPath: "{{ nodered.persistence_subPath }}"

resources: {}

nodeSelector: {}

tolerations: []

affinity: {}
```

and the values defined in the file `03_setup_k8s_platform/vars/dataflow-stack/<use_case>`.

```yaml
---
# file: 03_setup_k8s_platform/vars/dataflow-stack/xy_name_of_use_case.yml

# Helm Chart settings --->
HELM_REPO_NAME: stable
# HELM_CHART_NAME: node-red
HELM_CHART_NAME: dataflow-nodered
HELM_RELEASE_NAME: nr-show-last-tweet

replicaCount: 1
strategyType: Recreate
# -
image_repository: nodered/node-red
image_tag: "1.2.9"
image_pullPolicy: IfNotPresent
# -
nameOverride: ""
fullnameOverride: ""
# -
livenessProbePath: /
readinessProbePath: /
# -
flows: "sc-node-red-flows"  // <- Change name if necessary.
safeMode: "false"
enableProjects: "true"      // <- NodeRed projects are enabled automatically.
nodeOptions: ""
extraEnvs: []               // <- If you need to set further environment variables.
timezone: "UTC"
# -
service_type: ClusterIP
service_port: 1888
# -
ingress_enabled: true
ingress_class: public
ingress_tls_acme: true
ingress_host: "nr-show-last-tweet.{{ DOMAIN }}"
ingress_host_path: "/"
ingress_host_pathType: ImplementationSpecific
ingress_tls_secret: "nr-show-last-tweet.{{ DOMAIN }}-tls"
# -
persistence_enabled: true
persistence_storageClass: microk8s-hostpath
persistence_accessMode: ReadWriteOnce
persistence_size: 5Gi
persistence_subPath: null
# <--- Helm Chart settings

# Use Case settings --->
NR_SETTINGS: "<name_of_use_case>-settings.js"   // <- Set name of your use case.
NR_REPO_TARGET_FOLDER: "sc-node-red-flows"      // <- directory where you clone your NodeRed project. Needs to be the same value as parameter `flows` above.
FLOW_PROJECT: "gitlab.com/berlintxl/futr-hub/use-cases/show-latest-tweet-of-twitter-account/platform-node-red-flows.git"                // <- URL of Git repo with where your NodeRed project resides.
# <--- Use Case settings

```

## Context Management Stack

To deploy the Context Management Stack into Kubernetes, you have to set values for the following variables in your inventory file.

```ini
...
## Context Management Stack
CMS_MONGO_INITDB_DATABASE='<name_of_orion_database>'
CMS_MONGO_INITDB_ROOT_USERNAME='<name_of_mongodb_admin>'
CMS_MONGO_INITDB_ROOT_PASSWORD='<password_of_mongodb_admin>'
CMS_ORION_MONGODB_USER='<your_orion_mongodb_user>'
CMS_ORION_MONGODB_PASSWORD='<your_orion_mongodb_user_password>'
```

before you run the Ansible playbook `03_setup_k8s_platform/deploy_context_management_stack.yml`.

```bash
cd 03_setup_k8s_platform
ansible-playbook -i inventory deploy_context_management_stack.yml
```

This will deploy

- MongoDB (version 3.6)
- QuantumLeap
- Orion

and also configure the Orion API in Gravitee.

**Important**
This playbook uses the Ansible-Galaxy collection `community.mongodb`, which also requires the Python module `pymongo`.
As of July 2021, both are not part of the ACN, so you have to install them manually.

```shell
$ ansible-galaxy collection install community.mongodb
$ pip3 install pymongo
```
Also, before you run this playbook, please make sure, you already have deployed the [Data Management Stack](#data-management-stack), since QuantumLeap will use its instance of TimescaleDB!

**NOTE**
> You can run individual tasks by using the following tags: "mongodb", "quantumleap", "orion" and "config_orion".

### MongoDB
The deployment of MongoDB is done by calling the file `tasks/context_management-stack/install_mongodb.yml`, which reads the files `vars/context-management-stack/mongodb.yml` and `templates/context-management-stack/mongodb.yml`.

After the deployment of MongoDB has finished, Ansible will create a MongoDB user with the name of`CMS_ORION_MONGODB_USER`.

#### The file `vars/context-management-stack/mongodb.yml`
```yaml
---
# file: 03_setup_k8s_platform/vars/context_management-stack/mongodb.yml

image_tag: "3.6"

securityContext_fsGroup: 1001
securityContext_runAsUser: 1001

database: "{{ CMS_MONGO_INITDB_DATABASE }}"
root_username: "{{ CMS_MONGO_INITDB_ROOT_USERNAME }}"
root_password: "{{ CMS_MONGO_INITDB_ROOT_PASSWORD }}"
username: "{{ CMS_ORION_MONGODB_USER }}"
password: "{{ CMS_ORION_MONGODB_PASSWORD }}"

extra_flags: "--nojournal --storageEngine wiredTiger --maxConns 5000"

service_name: orion-mongodb
port: 27017

pv_storageClass: microk8s-hostpath
pv_accessMode: ReadWriteOnce
pv_size: 8Gi
```

### QuantumLeap
The deployment of QuantumLeap is done by calling the file `tasks/context_management-stack/install_quantumleap.yml`, which reads the files `vars/context-management-stack/quantumleap.yml` and `templates/context-management-stack/quantumleap.yml`.

#### The file `vars/context-management-stack/quantumleap.yml`
```yaml
---
# file: 03_setup_k8s_platform/vars/context_management-stack/quantumleap.yml

# Namespace where Service for TimescaleDB resides
timescale_namespace: "{{ default.K8S_NAMESPACE_DATA_MANAGEMENT | lower }}"
timescale_service: "futrhub-timescale"

# Quantum Leap
image_tag: "0.8.1"
smartsdk_image_tag: "quantumleap-pg-init:0.8.0@sha256:bb262755211e96eed6d6f8a12e25a899123140c6c9bd7ba3a72cc3c0e77f60fc"
```

### Orion
The deployment of Orion is done by calling the file `tasks/context_management-stack/install_orion.yml`, which reads the files `vars/context-management-stack/orion.yml` and `templates/context-management-stack/orion.yml`.

After the deployment of Orion, the Ansible task file `tasks/context_management-stack/configure_orion.yml` will
configure the Orion API in Gravitee.

#### The file `vars/context-management-stack/orion.yml`
```yaml
---
# file: 03_setup_k8s_platform/vars/context_management-stack/orion.yml

# Namespace where Service for MongoDB resides
mongodb_namespace: "{{ k8s_namespace }}"
mongodb_service: "orion-mongodb"

# Orion
image_tag: "2.4.2"
## Identity Management Stack

This chapter describes how to deploy and setup KeyCloak within a Kubernetes environment, using the [KeyCloak operator](https://www.keycloak.org/docs/latest/server_installation/index.html#_operator) for KeyCloak itself and the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator) for the PostgreSQL database.

The deployment is done via Ansible, using the playbook `deploy_idm_stack.yml`. This will install all required resources into the K8s namespace `idm-stack`.

```
cd 03_setup_k8s_platform/

ansible-playbook -i inventory deploy_idm_stack.yml
```

The playbook itself only imports variables and runs the following tasks, except `delete_keycloak_cr.yml`.

```
vars/idm-stack
├── common.yml
├── install_keycloak_operator.yml
├── install_openldap.yml
├── setup_keycloak.yml
└── setup_keycloak_db.yml

tasks/idm-stack
├── delete_keycloak_cr.yml
├── idm-config
│   ├── keycloak_0_deploy_secrets.yml
│   ├── keycloak_1_deploy_components.yml
│   ├── keycloak_2_general_config.yml
│   ├── keycloak_3_realm.yml
│   ├── keycloak_4_client_scopes.yml
│   ├── keycloak_5_clients.yml
│   ├── keycloak_6_scope_mappings.yml
│   ├── keycloak_7_groups.yml
│   └── keycloak_8_users.yml
├── install_keycloak_operator.yml
├── install_openldap.yml
├── setup_keycloak.yml
└── setup_keycloak_db.yml
```


**IMPORTANT**
Before you run the playbook, make sure that all mandatory
- environment variables,
- variables in the Ansible invetory,
are set as described further below.

You can further configure you KeyCloak deployment by editing the file files beneath `vars/idm-stack` to your liking, which will be described in more detail further below.
```
vars/idm-stack/
├── common.yml
├── install_keycloak_operator.yml
├── install_openldap.yml
├── setup_keycloak.yml
└── setup_keycloak_db.yml
```

You can use the following Ansible tags to execute certain tasks exclusively.

- `keycloak_db`: will only deploy a PostgreSQL database for KeyCloak.
- `keycloak_op`: will only deploy the KeyCloak operator.
- `keycloak_setup`: will only create KeyCloak's Custom Resources.
- `keycloak_ldap`: will only deploy OpenLDAP server and add an LDAP provider within KeyCloak, pointing to that OpenLDAP server.

If you need to delete KeyCloak's Custom Resources, you can run the Ansible playbook with the tag `keycloak_delete_cr`.

```
cd 03_setup_k8s_platform/

ansible-playbook -i inventory deploy_idm_stack.yml --tags "keycloak_delete_cr"
```

### Mandatory Environment Variables
Before you deploy KeyCloak via Ansible, you have to set at least the following environment variables.


```
export LDAP_ADMIN_USERNAME=<name of LDAP admin>
export LDAP_ADMIN_PASSWORD=<password of LDAP admin>
export LDAP_USERS=<list_of_LDAP_users, separated by ','>
export LDAP_PASSWORDS=<list of user passwords, separated by ','>

# Example
export LDAP_ADMIN_USERNAME=admin
export LDAP_ADMIN_PASSWORD=admin123
export LDAP_USERS=user01
export LDAP_PASSWORDS=password01
```

### Mandatory Inventory variables
Before you deploy KeyCloak via Ansible, you have to make sure that the following variables are set in the file `inventory`.

```yaml
# IDM
## IDM General Values
IDM_REALM='<realm name for the platform>'
IDM_ADMIN_K8S_SECRET_NAME='<k8s secret name for platform admin credentials>'
IDM_DB_ADMIN_SECRET_NAME='<k8s secret name for idm database credentials>'

## Base64 encoded username and password (initial)
IDM_REALM_MASTER_USERNAME='<base64 of chosen platform admin username>'
IDM_REALM_MASTER_PASSWORD='<base64 of chosen platform admin password>'

## Email Server values and credentials
EMAIL_SERVER='<email server used to send emails i.e. smtp.x.x>'
EMAIL_USER='<username to access email server>'
EMAIL_PASSWORD='<password to access email server>'
EMAIL_FROM='<email address used as "from">'
```

### KeyCloak Custom Resources
The required CRs for KeyCloak are created by executing the Ansible script `tasks/idm-stack/setup_keycloak.yml`, which then executes the scripts in `tasks/idm-stack/idm-config`.

```
tasks/idm-stack/idm-config
├── keycloak_0_deploy_secrets.yml
├── keycloak_1_deploy_components.yml
├── keycloak_2_general_config.yml
├── keycloak_3_realm.yml
├── keycloak_4_client_scopes.yml
├── keycloak_5_clients.yml
├── keycloak_6_scope_mappings.yml
├── keycloak_7_groups.yml
└── keycloak_8_users.yml
```

### OpenLDAP
The deployment of OpenLDAP server is based upon the [Bitnami Docker Image](https://github.com/bitnami/bitnami-docker-openldap) with version 2.4.58. If you want to use another version, you have to edit the value of `image_tag` in `vars/idm-stack/install_openldap.yml`.

Also, if you want to increase the size of the Persistent Volume from `100Mi` to a greater value or change the storage class, you can edit those settings also within that file.

The configuration of OpenLDAP itself can be done, using the environment variables, describe [here](https://github.com/bitnami/bitnami-docker-openldap#configuration), with the exception of `LDAP_CUSTOM_LDIF_DIR` and `LDAP_CUSTOM_SCHEMA_FILE`.

The file `vars/idm-stack/install_openldap.yml` is describe in more detail below.

### Configuration Files
As mentioned above, you can further configure the KeyCloak deployment by editing the files beneath `vars/idm-stack`.

#### common.yml
Here you can configure the name of the PostgreSQL database cluster and it's user.
```yaml
---
# file: 03_setup_k8s_platform/vars/idm-stack/common.yml

# KeyCloak database
kc_db_name: "keycloak"
kc_db_user: "keycloak"
```

#### setup_keycloak_db.yml
This file lets you setup values, used by the Zalando operator to deploy the PostgreSQL database clustter, like version of PostgreSQL and size of the Persistent Volume.

**NOTE**
> The default version of PostgreSQL is set to the value `10`; the same version, that would be deployed by the KeyCloak operator.
```yaml
---
# file: 03_setup_k8s_platform/vars/idm-stack/keycloak_db.yml

# Settings for Zalando operator for PostgreSQL
cluster_name: "{{ common.kc_db_name }}"
cluster_team: "{{ common.kc_db_user }}"
version: "10"
volume_size: "1Gi"
```

#### install_keycloak_operator.yml
This file lets you

- setup the URL of the KeyCloak operator's Git repository.
- the Git repository's branch, you want to use.
- the directory, where to checkout that branch.
```yaml
---
# file: 03_setup_k8s_platform/vars/idm-stack/install_keycloak_operator.yml

# Settings for KeyCloak operator
git_repo_url: "git@github.com:keycloak/keycloak-operator.git"
git_repo_dest: "/tmp/kc_op"
git_repo_branch: "master"
```

#### setup_keycloak.yml
This file is used to setup parameters for Keycloak's Custom Resouces.

```yaml
# IDM
## General
log_level: "INFO" # ALL, DEBUG, ERROR, FATAL, INFO, OFF, TRACE and WARN
realm_master_username: "{{ IDM_REALM_MASTER_USERNAME }}"
realm_master_password: "{{ IDM_REALM_MASTER_PASSWORD }}"

## Deployment
k8s_name: "fiware-keycloak"
ingress_secert_name: "keycloak-cert"
ingress_tls_host: "idm.{{ DOMAIN }}"
ingress_rules_host: "idm.{{ DOMAIN }}"

## IDM Scopes
IDM_SCOPE_TENANT_NAMES: "tenant-names"
IDM_SCOPE_TENANT_VALUES: "tenants"
IDM_SCOPE_API_READ: "api:read"
IDM_SCOPE_API_WRITE: "api:write"
IDM_SCOPE_API_DELETE: "api:delete"

## IDM Clients
IDM_CLIENT_API_ACCESS: "api-access"
IDM_CLIENT_GRAFANA: "grafana"
IDM_CLIENT_GRAVITEE: "gravitee"
IDM_CLIENT_PGADMIN: "pgadmin"

## IDM Users
PLATFORM_ADMIN_FIRST_NAME: "Admin"
PLATFORM_ADMIN_SURNAME: "Admin"
PLATFORM_ADMIN_EMAIL: "admin-open-data@{{ DOMAIN }}"
```

#### install_openldap.yml
This file lets you configure the PVC for OpenLDAP and sets default values for a parameter, if its value is not set via an environment variable.

```yaml
---
# file: 03_setup_k8s_platform/vars/idm-stack/install_openldap.yml

# PVC settings
pv_storageClass: microk8s-hostpath
pv_accessMode: ReadWriteOnce
pv_size: 100Mi

# Deployment settings
image_tag: "2.4.58"
ldap_admin_username: "{{ lookup('env', 'LDAP_ADMIN_USERNAME') }}"
ldap_admin_password: "{{ lookup('env', 'LDAP_ADMIN_PASSWORD') }}"
ldap_users: "{{ lookup('env', 'LDAP_USERS') }}"
ldap_passwords: "{{ lookup('env', 'LDAP_PASSWORDS') }}"
ldap_root: "{{ lookup('env', 'LDAP_ROOT') | default('dc=example,dc=org', true) }}"
ldap_user_dc: "{{ lookup('env', 'LDAP_USER_DC') | default('users', true) }}"
ldap_group: "{{ lookup('env', 'LDAP_GROUP') | default('readers', true) }}"
ldap_extra_schemas: "{{ lookup('env', 'LDAP_EXTRA_SCHEMAS') | default('cosine,inetorgperson,nis', true) }}"
ldap_skip_default_tree: "{{ lookup('env', 'LDAP_SKIP_DEFAULT_TREE') | default('no', true) }}"
ldap_ulimit_nofiles: "{{ lookup('env', 'LDAP_ULIMIT_NOFILES') | default('1024', true) }}"
```
