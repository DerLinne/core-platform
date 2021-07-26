# Installation

This document describes how to:

+ create the Docker image for the [Ansible Control Node](#installation-of-acn) (ACN) that is used to setup a Kubernetes cluster and deploy the Urban Data Platform into that cluster.
+ install [MicroK8s](#microk8s) on a Linux server, running Debian or Ubuntu .
+ deploy the [WebGIS prototype](#webgis-prototype) into MicroK8s.
+ deploy [CKAN](#ckan) into MicroK8s.
+ deploy [FROST](#frost) into MicroK8s.
+ deploy [DataFlow Stack](#dataflow-stack) into MicroK8s.
+ deploy [Context Management Stack](#context-management-stack) into MicroK8s.

## Prerequisites
- [git](https://git-scm.com)
- [docker](https://www.docker.com/)
- a ([locale](http://localhost:5000/v2/_catalog)) Docker-Registry
- [Packer](https://packer.io)
- a [good](https://neovim.io/), [command line usable](https://www.vim.org/) Editor.
- a SSH key pair for the ACN user _acn_.
- a SSH key pair to access this Git repository, since it is set to _private_.
- IP address of the Linux server you want to install [MicroK8s](https://microk8s.io).
- Credentials to access the Linux server.
- An email address for [cert-manager](https://cert-manager.io)


## Installation of ACN
```
# clone this repository
git clone git@gitlab.com:berlintxl/futr-hub/platform/data-platform-k8s.git
cd data-platform-k8s/01_setup_acn

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

All required files are located in the folder `~/data-platform-k8s/02_setup_k8s`.

### Prerequisites
You need to make a copy of the file
`~/data-platform-k8s/02_setup_k8s/inventory.default`
and set proper values for:

- k8s-master ansible_host
- ansible_password
- cert_manager_le_mail

before you run the Ansible playbook.

```
cd ~/data-platform-k8s/02_setup_k8s

cp inventory.default inventory

# edit the values for the above mentioned variables.
vim inventory
```

### Installation
Please, execute the following steps to install MicroK8s.

```
# run the Ansible playbooks
cd ~/data-platform-k8s/02_setup_k8s

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
+ [MasterPortal](#masterportal)
+ [QGIS Server](#qgis-server)

### Prerequisites
- Your DNS server is setup properly to create [Let's Encrypt](https://letsencrypt.org/) certificats for the Linux server, where you deployed your Kubernetes cluster onto.

- You have created an [access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) to have read-/write-access to the GitLab container registry.

- You need to have a kubeconfig-file within the ACN, that allows you to access the K8s API server with kubectl.


**NOTE**
> If you installed MicroK8s from within the ACN, you will already have a kubeconfig-file in the directory `~/.kube/` with the name `k8s-master_config`.

You need to make a copy of the file
`~/data-platform-k8s/03_setup_k8s/inventory.default`
and set proper values for:

- GITLAB_REGISTRY_ACCESS_USER_EMAIL
- GITLAB_REGISTRY_ACCESS_USER
- GITLAB_REGISTRY_ACCESS_TOKEN

before you run the Ansible playbook.

```
cd ~/data-platform-k8s/03_setup_k8s_platform
cp inventory.default inventory

# edit the values for the above mentioned variables.
vim inventory
```

Make sure that ChartMuseum is running.
```
ps aux | grep 'helm servecm' | grep -v grep
```

If not, run the Ansible playbook `start_cm_playbook.yml`.
```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory start_cm_playbook.yml
```



To verify you can connect to your K8s API server and all necessary Pods, simply run the following commands.
```
export KUBECONFIG=$HOME/.kube/k8s-master_config
kubectl cluster-info

kubectl get pods --namespace kube-system
```

### PostGIS
To install [PostGIS](https://postgis.net/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_postgis_playbook.yml` from within the ACN.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_postgis_playbook.yml
```

After a view minutes the deployment should be finished and you can then connect to the PostGIS server as user `postgres` with the password `postgres123`.

If you want to change the user and password, you have to export the environment variables `POSTGRES_USER` and `POSTGRES_PASSWORD`, before running the Ansible playbook.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

export POSTGRES_USER=foo
export POSTGRES_PASSWORD=bar
ansible-playbook -i inventory deploy_webgis_postgis_playbook.yml
```

**NOTE**
> To further customize the deployment of PostGIS, you simply need to edit the file `data-platform-k8s/03_setup_k8s_platform/vars/webgis_postgis.yml`.

If you use the default values, then PostGIS can be accessed via port 5432 on the following DNS name from within your cluster:

`geodata-postgis-webgis-postgis.geodata.svc.cluster.local`

To get the PostGIS user run:
```
export POSTGRES_USER=$(
    kubectl get secret --namespace geodata \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_user}" | base64 -d
)
```

To get the password for this user run:
```
export POSTGRES_PASSWORD=$(
    kubectl get secret --namespace geodata \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_password}" | base64 -d
)
```

To connect to your database from outside the cluster, using `psql` execute the following commands:
```
kubectl port-forward --namespace geodata \
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
To install [pgAdmin](https://www.pgadmin.org/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_pgadmin_playbook.yml` from within the ACN.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_pgadmin_playbook.yml
```

After a view minutes the deployment should be finished.
**NOTE**
> To further customize the deployment of pgAdmin, you simply need to edit the file `data-platform-k8s/03_setup_k8s_platform/vars/webgis_pgadmin.yml`.

To connect to the web-interface, please execute the following commands.
```
export POD_NAME=$(
    kubectl get pods --namespace geodata \
    -l "app.kubernetes.io/name=pgadmin4,app.kubernetes.io/instance=geodata-pgadmin" \
    -o jsonpath="{.items[0].metadata.name}"
)

kubectl port-forward --namespace geodata $POD_NAME 8080:80
```

Now you can access pgAdmin's web-interface with [this](http://127.0.0.1:8080) URL.

To login, user either the default values

- Login: max@mustermann.de
- Password: pgadmin123

or the values of the environment variables

- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`

if you have set them.

A server defintion for the PostGIS database is already provided, using the default values of the PostGIS installation.

**NOTE**
If you changed one of those values, you have to either edit the file `vars/webgis_pgadmin.yml` and/or set the following envirionment variables, before you run the Ansible playbook.

| ENVIRONMENT VARIABLE | DEFAULT VALUE                                 |
| :--------------------| :---------------------------------------------|
|`POSTGIS_USER`        | postgres                                      |
|`POSTGIS_DB`          | postgres                                      |
|`POSTGIS_HOST`        | geodata-postgis-webgis-postgis.geodata |

At the moment you have to enter the password for the PostGIS user manually, if you want to connect to the PostGIS database.

The default password for the default PostGIS user `postgres` is `postgres123`.


### MasterPortal
To install [MasterPortal](https://bitbucket.org/geowerkstatt-hamburg/masterportal/src/dev/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_masterportal_playbook.yml` from within the ACN. Before doing this, please install the Masterportal specific OAuth2 Proxy

To activate the authentication for masterportal set the following variables in the `inventory`:

```
# Master Portal Settings
MP_IDM_CLIENT='<your_keycloak_client>'
MP_IDM_CLIENT_SECRET='<your_keycloak_client_secret>'
MP_IDM_ENDP_USER_INFO='<your_user_info_url>'
# -- server specific cookie for the secret; create a new one with `openssl rand -base64 32 | head -c 32 | base64`
MP_OAUTH_COOKIE_SECRET='<see_generation_hint_above'
```

Install OAuth2 Proxy for masterportal
```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_oauth2_masterportal_proxy.yml
```

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_masterportal_playbook.yml
```

After a view minutes the deployment should be finished.

To access the MasterPortal you will have to execute the following command:
```
kubectl --namespace geodata port-forward \
    svc/geodata-masterportal-webgis-masterportal 12345:80
```
and open the URL [http://127.0.0.1:12345/webgis-masterportal/](http://127.0.0.1:12345/webgis-masterportal/) in your Web browser.

---
**IMPORTANT**
Since there is no official Docker image for MasterPort you will have to create your own and deploy it into the local K8s registry of MicroK8s!

How to create and deploy such an image will be described below!

---

#### How to build the MasterPortal Docker image

---
**IMPORTANT**
AS OF NOW YOU CAN NOT BUILD THE DOCKER IMAGE FROM WITHIN THE ACN CONTAINER!
PLEASE, BUILD THE IMAGE ON THE HOST YOU ARE RUNNING THE ACN CONTAINER ON.
YOU MAY NEED TO CLONE THIS REPO ON THAT COMPUTER.

---

To build the Docker image, please execute the following commands:

```
cd ~/data-platform-k8s/03_setup_k8s_platform/files/webgis-masterportal/

docker build -t webgis-masterportal:local .
```
**NOTE**
> It is mandatory, that you tag the image with `local`!

Next, you will need to save this image, so we can import it.
```
docker save webgis-masterportal:local > /tmp/webgis-masterportal.tar
```


#### How to deploy the Docker image into the MicroK8s registry
First, you need to transmit the file `/tmp/webgis-masterportal.tar` to your MicroK8s server and then log onto that server.
```
scp /tmp/webgis-masterportal.tar acn@<your_microk8s_server>:
ssh acn@<your_microk8s_server>
```
**NOTE**
> If you did not deploy a MicroK8s server through the ACN, you need to change your login-name of course.

Next, import the saved Docker image into the registry of MicroK8s, by executing the following commands on your MicroK8s server:
```
sudo microk8s ctr images import webgis-masterportal.tar
sudo microk8s ctr images list | grep webgis

# You should see the image webgis-masterportal listed
```


### QGIS Server

If you want to reach your QGIS Server from the Internet via HTTPS, you have to

- make sure, that the Nginx Ingress Controler and the CertManager are setup for your K8s cluster.
- add an entry `DOMAIN=<your domain>` to the file `inventory`.
- make sure that `ingress_enabled` in `vars/webgis_qgisserver.yml` is set to `true`.

If you want to change the host name from `mapserver` to something else, please edit

- `nginx_server_name`
- `ingress_host`

accordingly and make sure your DNS server can resolve this host name.

To allow access to the data of QGIS Server, [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) is enabled in the Nginx ConfigMap `qgis-nginx.conf`. You can set the value of the HTTP header `Access-Control-Allow-Origin` for request methods `POST`, `GET` and `OPTIONS`, using the parameter `nginx_cors_origin`. The default is, that every host of your domain `DOMAIN` can use those access methods.

To install [QGIS Server](https://docs.qgis.org/3.16/en/docs/server_manual/index.html) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_qgisserver_playbook.yml` from within the ACN.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_qgisserver_playbook.yml
```

After a view minutes the deployment should be finished.

The deployment creates two new ConfigMaps

- project.qgs
- qgis-nginx.conf

and the Secret _geodata-qgisserver-webgis-qgisserver_.
The later one contains the values for the file `pg_service.conf` that is mounted into the QGIS Server pod. An according database and its user will be created within the PostGIS Pod.

The file `pg_service.conf` has the following content.
```ini
[qwc_geodb]
host=geodata-postgis-webgis-postgis
port=5432
dbname=qwc_demo
user=qgis_server
password=qgis_server123
sslmode=disable
```

The ConfigMap `project.qgs` contains the content of your QGIS project file, that you host in a [GitLab repository](https://gitlab.com/berlintxl/futr-hub/platform/qgis-server-customizing/-/blob/master/project.qgs).

You have to define the GitLab project, where your file _project.qgs_ resides, in the file
 `03_setup_k8s_platform/vars/webgis_qgisserver.yml`.

```yaml
---
# file: 03_setup_k8s_platform/vars/webgis_qgisserver.yml

HELM_CHART_NAME: webgis-qgisserver
HELM_RELEASE_NAME: geodata-qgisserver

# Name of the GitLab project where we store our QGIS project file
QGIS_CUSTOM_GITLAB_PROJECT: "the/path/to/your/project"
```

The URL of the GitLab API server is defined in the file
`03_setup_k8s_platform/vars/default.yml`.

```yaml
---
# file: 03_setuup_k8s_platform/vars/default.yml
…
# GitLab-API-URL
GITLAB_API_URL: "https://gitlab.com/api/v4"

```

**IMPORTANT**
If your QGIS project file is hosted in a private GitLab repository, you need to create a read_api token and insert the token in your inventory file with the key `GITLAB_API_ACCESS_TOKEN`.

```ini
[localhost]
127.0.0.1   ansible_connection=local

[localhost:vars]
ansible_python_interpreter="{{ ansible_playbook_python }}"
GITLAB_REGISTRY_ACCESS_USER_EMAIL="<Your_GitLab_User_Email>"
GITLAB_REGISTRY_ACCESS_USER="<Your_GitLab_User>"
GITLAB_REGISTRY_ACCESS_TOKEN="<Your_GitLab_Registry_Token>"

GITLAB_API_ACCESS_TOKEN="<Your_GitLab_Read_API_Token>"
```


To update, you can either

+ simply edit the ConfigMap and restart the deployment of the QGIS Server `geodata-qgisserver-webgis-qgisserver-server`.
```
kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata edit cm project.qgs
kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata rollout restart deployment geodata-qgisserver-webgis-qgisserver-server
```
+ run the Ansible playbook `update_qgis_project.yml`.
```
cd ~/data-platform-k8s/03_setup_k8s_platform
ansible-playbook -i inventory update_qgis_project_playbook.yml
```

After a few seconds a new Pod, using the new QGIS project file, will be ready.

To verify the installation you will have to execute the following command:
```
kubectl --namespace geodata port-forward \
    svc/geodata-qgisserver-webgis-qgisserver-http 30080:80
```
and open the URL
[http://127.0.0.1:30080/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities](http://127.0.0.1:30080/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities) in your Web browser.


If you have deployed QGIS Server, so it can be reached via HTTPS, you have to open the URL

https://mapserver.{{ YOUR DOMAIN }}/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities

in your Web browser.

---
**IMPORTANT**
Since there is no official Docker image for QGIS Server you will have to create your own and deploy it into the local K8s registry of MicroK8s!

How to create and deploy such an image will be described below!

AS OF NOW YOU CAN NOT BUILD THE DOCKER IMAGE FROM WITHIN THE ACN CONTAINER!
PLEASE, BUILD THE IMAGE ON THE HOST YOU ARE RUNNING THE ACN CONTAINER ON.
YOU MAY NEED TO CLONE THIS REPO ON THAT COMPUTER.

---

#### How to build the QGIS Server Docker image

To build the Docker image, please execute the following commands:

```
cd ~/data-platform-k8s/03_setup_k8s_platform/files/webgis-qgisserver/

docker build -t webgis-qgisserver:local .
```
**NOTE**
> It is mandatory, that you tag the image with `local`!

Next, you will need to save this image, so we can import it.
```
docker save webgis-qgisserver:local > /tmp/webgis-qgisserver.tar
```


#### How to deploy the Docker image into the MicroK8s registry
First, you need to transmit the file `/tmp/webgis-qgisserver.tar` to your MicroK8s server and then log onto that server.
```
scp /tmp/webgis-qgisserver.tar acn@<your_microk8s_server>:
ssh acn@<your_microk8s_server>
```
**NOTE**
> If you did not deploy a MicroK8s server through the ACN, you need to change your login-name of course.

Next, import the saved Docker image into the registry of MicroK8s, by executing the following commands on your MicroK8s server:
```
sudo microk8s ctr images import webgis-qgisserver.tar
sudo microk8s ctr images list | grep webgis

# You should see the image webgis-qgisserver listed
```

## CKAN

[CKAN](https://ckan.org) is a data management system and in this chapter we will describe how to deploy it into MicroK8s.

The deployment is done via Ansible, using the Helm chart [keitaro-charts/ckan](https://github.com/keitaroinc/ckan-helm) from [Keitaro](https://keitaro.com/).

To deploy CKAN, simply run the Ansible playbook `deploy_ckan_playbook.yml` from within the ACN. This will deploy CKAN in the K8s namespace _ckan_.

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
smtp_password: "{{ CKAN_SMTP_PASSWORD }}"
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
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_ckan_playbook.yml
```

After a view minutes the deployment should be finished.

Now you have to generate an API Token for the sysadmin user using the CKAN UI and replace the secret with the new value at runtime.

```
kubectl -n ckan create secret generic ckansysadminapitoken --from-literal=sysadminApiToken={insert_generated_api_token_here} --dry-run -o yaml | kubectl apply -f -
```

**NOTE**
>If you want to re-deploy/update your CKAN deployment, please use your API Token as value for the key `ckan_sysadminApiToken` in the file `vars/ckan_ckan.yml`.

### FROST

[FROST Server](https://fraunhoferiosb.github.io/FROST-Server/) is a server implementation of the OGC SensorThings API, and in this chapter we will describe how to deploy it into MicroK8s.

The deployment is done via Ansible, using the Helm chart [frost-server](https://github.com/FraunhoferIOSB/FROST-Server/tree/master/helm/frost-server).

To deploy FROST Server, simply run the Ansible playbook `deploy_frost_playbook.yml` from within the ACN. This will deploy FROST Server in the K8s namespace _frost-server_.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_frost_playbook.yml
```

After a view minutes the deployment should be finished.

You can than reach FROST Server with this URL: http://frost.utr-k8s.urban-data.cloud:30888/FROST-Server/

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

## Timescale Settings

TIMESCALE_PASSWORD='<your_desired_timescaledb_password>'
```

For minio the creation of each values is described in the comment above the needed values.

The IDM Settings have to be taken from the corresponding IDM to use.

The TimescaleDB Password can be free defined.

To set these values, execute the following:

```bash
cd ~/data-platform-k8s/03_setup_k8s_platform
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

- [01_show_last_tweet](https://nr-show-last-tweet.utr-k8s.urban-data.cloud)
- [05_luftdaten_info](https://nr-luftdaten-info.utr-k8s.urban-data.cloud)
- [06_sensebox](https://nr-sensebox.utr-k8s.urban-data.cloud)
- [07_switch_lights](https://nr-switch-lights.utr-k8s.urban-data.cloud)
- [08_indicate_energy](https://nr-indicate-energy.utr-k8s.urban-data.cloud)
- [09_paxcounter](https://nr-paxcounter.utr-k8s.urban-data.cloud)

For further details, please take a look at [this](https://gitlab.com/berlintxl/futr-hub/platform/data-platform/-/tree/master/05_usecases) GitLab repository.

The deployment is done via Ansible, using this [Helm chart](https://gitlab.com/berlintxl/futr-hub/platform/data-platform-k8s/-/tree/master/03_setup_k8s_platform/files/helmcharts/dataflow-nodered), that is derived from the (now deprecated) Helm chart [stable/node-red](https://github.com/helm/charts/tree/master/stable/node-red) .

To deploy NodeRed, simply run the Ansible playbook `deploy_frost_playbook.yml` from within the ACN. This will deploy all NodeRed applications in the K8s namespace _dataflow-stack_.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_dataflow_stack.yml
```

After a view minutes the deployment should be finished.

If you want to deploy a certain NodeRed application (use case), you can use tags.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

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
timescale_namespace: "{{ default.K8S_NAMESPACE_DATA_MANAGEMENT_OPERATOR | lower }}"
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
```
