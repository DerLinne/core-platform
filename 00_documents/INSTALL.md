# Installation

This document describes how to:

+ create the Docker image for the [Ansible Control Node](#installation-of-acn) (ACN) that is used to setup a Kubernetes cluster and deploy the Urban Data Platform into that cluster.
+ install [MicroK8s](#microk8s) on a Linux server, running Debian or Ubuntu .
+ install the [WebGIS prototype](#webgis-prototype).

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

ansible-playbook -i inventory playbook.yml

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

### Prerequisites
Make sure that ChartMuseum is running.
```
ps aux | grep 'helm servecm' | grep -v grep
```

If not, run the Ansible playbook `start_cm_playbook.yml`.
```
cd ~/data-platform-k8s/03_setup_k8s_platform

ansible-playbook -i inventory start_cm_playbook.yml
```

You need to have a kubeconfig-file within the ACN, that allows you to access the K8s API server with kubectl.
If you installed MicroK8s from within the ACN, you will already have a kubeconfig-file in the directory `~/.kube/`.

**NOTE**
> If you use a local installation of microk8s, simply run

`microk8s config > config_for_acn`

and paste the content of this file into `~/.kube/config` within the ACN. Right now you have to create the directory `~/.kube` yourself.

**IMPORTANT!**
MAKE SURE THE kubeconfig FILE HAS THE PERMISSIONS SET TO `0600`!
***

To verify you can connect to your K8s API server and all necessary Pods, simply run the following commands.
```
export KUBECONFIG=$HOME/.kube/<name_of_your_kubeconfig>
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



