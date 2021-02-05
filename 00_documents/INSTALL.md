# Installation

This document describes how to:

+ create the Docker image for the [Ansible Control Node](#acn) (ACN) that is used to setup a Kubernetes cluster and deploy the Urban Data Platform into that cluster.
+ install the [WebGIS prototype](#webgis)

## Prerequisites
- [git](https://git-scm.com)
- [docker](https://www.docker.com/)
- a ([locale](http://localhost:5000/v2/_catalog)) Docker-Registry
- [Packer](https://packer.io)
- a [good](https://neovim.io/), [command line usable](https://www.vim.org/) Editor
- a SSH key pair for the ACN user _acn_.
- a SSH key pair to access this Git repository, since it is set to _private_.


## [Installation of ACN](id:acn)
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

## [WebGIS protoype](id:webgis)
This section describes how to install the following components:

+ [PostGIS](#postgis)

### Prerequisites
You need to create a kubeconfig-file within the ACN, that allows you to access the K8s API server with kubectl.

**NOTE**
> If you use microk8s simply run `microk8s config > config_for_acn` and paste the content of this file into `~/.kube/config` within the ACN. In the future a kubeconfig-file will be created for you.

To verify you can connect to your K8s API server, simply run the following command.
```
kubectl cluster-info
```

### [PostGIS](id:postgis)
To install PostGIS as part of the WebGIS prototype, simply run the Ansible playbook `deploy_webgis_postgis_playbook.yml` from within the ACN.

```
ansible-playbook -i inventory deploy_webgis_postgis_playbook.yml
```

After a view minutes the deployment should be finished and you can then connect to the PostGIS server as user `postgres` with the password `postgres123`.

If you want to change the user and password, you have to export the environment variables `POSTGRES_USER` and `POSTGRES_PASSWORD`, before running the Ansible playbook.

```
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
    -o jsonpath="{.data.postgres_password}" | base64 -d)
```

To connect to your database from outside the cluster execute the following commands:
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
