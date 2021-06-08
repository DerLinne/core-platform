

# How to use the ACN Docker image
To run the Docker image, please execute the following command

```
docker run -it --rm localhost:5000/futr-hub/ansible-control-node
```

and follow the instructions. You can find the instructions also in the file `welcome.txt`.

```
###############################################################################
# WELCOME to ANSIBLE-CONTROL-NODE for FUTR-HUB!                               #
###############################################################################

Cloning Git repository <FUTR_HUB_GIT_REPO>
with branch <FUTR_HUB_GIT_BRANCH>
into <FUTR_HUB_GIT_CLONE_DIR>.

-------------------------------------------------------------------------------
ATTENTION!
IF ENVIRONMENT VARIABLES

- FUTR_HUB_GIT_REPO
- FUTR_HUB_GIT_BRANCH
- FUTR_HUB_GIT_CLONE_DIR

ARE NOT SET YOU HAVE TO SET THEM BEFORE YOU CONTINUE!
-------------------------------------------------------------------------------
To continue the installation, please execute the following commands.

  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/"${FUTR_HUB_ACN_SSHKEY}"

  ansible-playbook -i inventory prepare.yml
  # -->
  # optional: set K8S_MASTER
  export K8S_MASTER="<IP_ADDRESS_OF_YOUR_MICROK8S_API_SERVER>"
  export DOMAIN_NAME="<YOUR_DOMAIN_NAME>"
  # <--
  ansible-playbook -i inventory main.yml

If you use a SSH-Key to access the Git repository, please
- set FUTR_HUB_GIT_SSHKEY accordingly
- execute the following command beforehand.

  ssh-add ~/.ssh/"${FUTR_HUB_GIT_SSHKEY}"

-------------------------------------------------------------------------------
NOTE!

If you want to install MicroK8s *AND* *ALL* FUTR-HUB components, you may run

  ansible-playbook -i inventory install.yml

after you have configured all necessary configuration files.

Please consult <FUTR_HUB_GIT_CLONE_DIR>/00_documents/INSTALL.md before you
continue with the setup of the K8s cluster and deployment of platform into K8s.
-------------------------------------------------------------------------------

Good luck!
###############################################################################

```

The Ansible playbook `prepare.yml` clones the FUTR-HUB Git repository into the ACN, while the playbook `main.yml` 

+ installs required software for the ACN, including Helm and KubeCtl.
+ fetches the KubeConfig file from your MicroK8s cluster, if it is available.
+ starts the local-running Helm server.

The Ansible playbook `install.yml`

+ installs and sets up MicroK8s on a remote server.
+ installs and sets up all components of FUTR-HUB within your MicroK8s cluster.

Since all data is ephemeral in the ACN container, you have to run at least the playbooks `prepare.yml` and `main.yml` , if you kill the container.


# How to fetch the KubeConfig from your MicroK8s cluster
If you have installed the MicroK8s cluster from within the ACN **and** DID NOT shutdown the ACN, you already have the KubeConfig file `k8s-master_config` in `$HOME/.kube`.

If you installed the MicroK8s cluster **and** DID shutdown the ACN, you have to

+ set the environment variable `K8S_MASTER` with the IP address of your MicroK8s API server, before you run the playbook `main.yml`.
```bash
export K8S_MASTER="<IP_ADDRESS_OF_YOUR_MICROK8S_API_SERVER>"
```
+ run the playbook `main.yml`
```bash
ansible-playbook -i inventory main.yml
```

or, if you would rather fetch the KubeConfig at a later time

+ set the environment variable `K8S_MASTER` with the IP address of your MicroK8s API server.
```bash
export K8S_MASTER="<IP_ADDRESS_OF_YOUR_MICROK8S_API_SERVER>"
```
+ run the playbook `fetch_kubeconfig.yml`
```bash
ansible-playbook -i inventory "${FUTR_HUB_GIT_CLONE_DIR}/01_setup_acn/ansible/fetch_kubeconfig.yml"
```
---
>**NOTE**
If the name of your KubeConfig **is not** `k8s-master_config` you must change the value of `kubeconfig_file` in the following locations:

+ `/home/acn/inventory`
+ `/home/acn/data-platform-k8s/01_setup_acn/ansible/inventory`

# How to verify access to your MicroK8s cluster

+ Perform the following steps, if you do not have already.
    * `export K8S_MASTER="<IP_ADDRESS_OF_YOUR_MICROK8S_API_SERVER>"`
    * `ansible-playbook -i inventory prepare.yml`
    * `ansible-playbook -i main.yml`
+ `kubectl --kubeconfig=$HOME/.kube/<name_of_your_kubeconfig_file> cluster-info`

You should see the following message.

```
Kubernetes control plane is running at https://${K8S_MASTER}:16443
CoreDNS is running at https://${K8S_MASTER}:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://${K8S_MASTER}/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```


# How to update the MasterPortal

>**NOTE**
The following steps are tailored towards the private Git repository https://gitlab.com/berlintxl/futr-hub/platform/masterportal_customizing , which uses a GitLab pipeline to build the Docker image! 


+ Clone the repository berlintxl/futr-hub/platform/masterportal_customizing.
+ Add/Edit the files you need to update.
+ Commit and push your changes.
+ Wait until the GitLab has build the new Docker image.
+ Run the Ansible playbook `${FUTR_HUB_GIT_CLONE_DIR}/03_setup_k8s_platform/update_masterportal_playbook.yml`.

Kubernetes will now perform a rollout and restart of the deployment of the MasterPortal with the new Docker image.

You can verify that the rollout and restart were successfull by running the following commands.
```
kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata describe deploy geodata-masterportal-webgis-masterportal

kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata get pods

kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata describe pod geodata-masterportal-webgis-masterportal-<Hash_value_of_deployment>-<Hash_value_of_pod>
```

or simply open the URL https://masterportal.utr-k8s.urban-data.cloud/webgis-masterportal/ .


# How to update the QGIS Server project file

>**NOTE**
The following steps are tailored towards the private Git repository https://gitlab.com/berlintxl/futr-hub/platform/qgis-server-customizing , which requires an access token for the Read API of GitLab, to access the file `project.qgs` when using the Ansible playbook! 

+ Create an [access token](https://gitlab.com/-/profile/personal_access_tokens) to access Gitlab's Read API.
+ Edit the file `${FUTR_HUB_GIT_CLONE_DIR}/03_setup_k8s_platform/inventory` and enter your credentials for `GITLAB_API_ACCESS_TOKEN`.
+ Clone the repository berlintxl/futr-hub/platform/qgis-server-customizing.
+ Edit/Update the file `project.qgs`.
+ Commit and push your changes.
+ Run the Ansible playbook `${FUTR_HUB_GIT_CLONE_DIR}/03_setup_k8s_platform/update_qgis_project_playbook.yml`

Kubernetes will now perform a rollout and restart of the deployment of the QGIS Server with the new version of the project file `project.qgs` 

You can verify that the rollout and restart were successfull by running the following commands.
```
kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata describe deploy geodata-qgisserver-webgis-qgisserver-server

kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata get pods

kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata describe pod geodata-qgisserver-webgis-qgisserver-server-<Hash_value_of_deployment>-<Hash_value_of_pod>

kubectl --kubeconfig=$HOME/.kube/k8s-master_config -n geodata describe cm project.qgs
```

or simply open the URL http://62.171.147.52:30080/qgis-server/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities .
