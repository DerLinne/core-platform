# Installation

This document describes how to:

+ create the Docker image for the [Ansible Control Node](#installation-of-acn) (ACN) that is used to setup a Kubernetes cluster and deploy the Urban Data Platform into that cluster.
+ install [MicroK8s](#microk8s) on a Linux server, running Debian or Ubuntu .
+ deploy the [WebGIS prototype](#webgis-prototype) into MicroK8s.
+ deploy [CKAN](#ckan) into MicroK8s.

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

`geodata-postgis-webgis-postgis.smart-city-txl.svc.cluster.local`

To get the PostGIS user run:
```
export POSTGRES_USER=$(
    kubectl get secret --namespace smart-city-txl \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_user}" | base64 -d
)
```

To get the password for this user run:
```
export POSTGRES_PASSWORD=$(
    kubectl get secret --namespace smart-city-txl \
    geodata-postgis-webgis-postgis \
    -o jsonpath="{.data.postgres_password}" | base64 -d
)
```

To connect to your database from outside the cluster, using `psql` execute the following commands:
```
kubectl port-forward --namespace smart-city-txl \
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
    kubectl get pods --namespace smart-city-txl \
    -l "app.kubernetes.io/name=pgadmin4,app.kubernetes.io/instance=geodata-pgadmin" \
    -o jsonpath="{.items[0].metadata.name}"
)

kubectl port-forward --namespace smart-city-txl $POD_NAME 8080:80
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
|`POSTGIS_HOST`        | geodata-postgis-webgis-postgis.smart-city-txl |

At the moment you have to enter the password for the PostGIS user manually, if you want to connect to the PostGIS database.

The default password for the default PostGIS user `postgres` is `postgres123`.


### MasterPortal
To install [MasterPortal](https://bitbucket.org/geowerkstatt-hamburg/masterportal/src/dev/) as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_masterportal_playbook.yml` from within the ACN.

```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory deploy_webgis_masterportal_playbook.yml
```

After a view minutes the deployment should be finished.

To access the MasterPortal you will have to execute the following command:
```
kubectl --namespace smart-city-txl port-forward \
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

The ConfigMap `project.qgs` contains the content of your QGIS project file. To update, simply edit the ConfigMap and delete the Pod `geodata-qgisserver-webgis-qgisserver-server-xxxxxxxxxx-yyyyy`. After a few seconds a new Pod with the new QGIS project files will ready.

---
**IMPORTANT**
As of now, there is a problem with the QGIS project file, that gets created as a ConfigMap. To work around that you have to follow the steps, mentioned in the section [QGIS project file – Workaround](#workaround).

---

To verify the installation you will have to execute the following command:
```
kubectl --namespace smart-city-txl port-forward \
    svc/geodata-qgisserver-webgis-qgisserver-http 30080:80
```
and open the URL [http://127.0.0.1:30080/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities](http://127.0.0.1:30080/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities) in your Web browser.

---
#### Workaround
- Get a copy of the QGIS project within the ACN (There is a demo file under `03_setup_k8s_platform/files/webgis-qgisserver/qgis-sample.qgs`).
- Run `kubectl create configmap tmp-project.qgs --from-file=./path/to/your/project.qgs`
- Run `kubectl describe configmap tmp-project.qgs` and copy everything under the single-dash-line '----' until the closing tag `</qgis>`
- Edit the config-map _project.qgs_, created by the Helm chart.
  - Run `kubectl -n <Your_Namespace> edit configmap project.qgs`
- Delete everything between the lines `project.qgs |` and `kind: ConfigMap`.
- Paste everything you copied before between the lines `project.qgs |` and `kind: ConfigMap` and save.
- Delete the currently running Pod with the name _geodata-qgisserver-webgis-qgisserver-server-xxxxxxxxxx-yyyyy_

```
$ kubectl describe configmap tmp-project.qgs

Name:         tmp-project.qgs
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
project.qgs:
----
<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.0.0-Girona" projectname="">
  <title></title>
...
  </properties>
  <visibility-presets/>
  <transformContext/>
  <Annotations/>
  <Layouts/>
</qgis>
```
**NOTE**
> Copy all below the `----` and paste it into the ConfigMap `project.qgs`.


---
**IMPORTANT**
Since there is no official Docker image for QGIS Server you will have to create your own and deploy it into the local K8s registry of MicroK8s!

How to create and deploy such an image will be described below!

---

#### How to build the QGIS Server Docker image

---
**IMPORTANT**
AS OF NOW YOU CAN NOT BUILD THE DOCKER IMAGE FROM WITHIN THE ACN CONTAINER!
PLEASE, BUILD THE IMAGE ON THE HOST YOU ARE RUNNING THE ACN CONTAINER ON.
YOU MAY NEED TO CLONE THIS REPO ON THAT COMPUTER.

---

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

The FQHN of the key `ckan_siteUrl` should match the FQHN of `ingress_host`!

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
image_tag: "2.9.1"
image_pullPolicy: IfNotPresent

pvc_enabled: true
pvc_size: "1Gi"

DBDeploymentName: "postgres"
RedisName: "redis"
SolrName: "solr"
DatapusherName: "datapusher"
DBHost: "postgres"
MasterDBName: "postgres"
MasterDBUser: "postgres"
MasterDBPass: "postgres123"

CkanDBName: "ckan_default"
CkanDBUser: "ckan_default"
CkanDBPass: "ckan_default123"
DatastoreDBName: "datastore_default"
DatastoreRWDBUser: "datastorerw"
DatastoreRWDBPass: datastorerw123
DatastoreRODBUser: datastorero
DatastoreRODBPass: datastorero123

ckan_sysadminName: "ckan_admin"
ckan_sysadminPassword: "ckan_admin123"
ckan_sysadminApiToken: "replace_this_with_generated_api_token_for_sysadmin"
ckan_sysadminEmail: "postmaster@domain.com"
ckan_siteTitle: "Site Title here"
ckan_siteId: "site-id-here"
ckan_siteUrl: "https://ckan.utr-k8s.urban-data.cloud/"
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
smtp_user: "smtpUser"
smtp_password: "smtpPassword"
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

ingress_enabled: true
ingress_class: "public"
ingress_host: "ckan.utr-k8s.urban-data.cloud"
tls_acme: true
tls_secretName: "ckan.utr-k8s.urban-data.cloud-tls"

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
