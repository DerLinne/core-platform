This document describes how to:

+ Prepare the configuration with the [Preconfiguration](#pre-setup-steps)
+ install [MicroK8s](#install-microk8s) on a Linux server, running Debian or Ubuntu .
+ Deploy the full platform installation
+ 
## Prerequisites
- [git](https://git-scm.com)
- a SSH key pair to use.
- IP address of the Linux server you want to install [MicroK8s](https://microk8s.io).
- Credentials to access the Linux server.
- An email address for [cert-manager](https://cert-manager.io)

## Pre-Setup Steps

In Order to be able to run the complete installation, one central Ansible Inventory File has to be prepared. 

Additionally some Environment Variables have to be set.

### Configure Inventory File

First create a copy based on the template-

```
# Copy template
cp inventory.default inventory

# Edit and set right parameters
vim inventory
```

The File `inventory` containes the following parameters to set:

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
kubeconfig_file=<name_for_local_kubeconfig_file>
working_user=<name_for_localhost_user>
working_group=<name_for_localhost_group>

# (Sub-)Domain for the Installation
DOMAIN="<domainname>"

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

After setting all parameters accordingly, save the file.

To furthermore configure individual components, please take a look at the files, residing in the folder `03_setup_k8s_platform/vars`.

## Install MicroK8s

Run the following command from Repo Root Folder to preconfigure the VM.

```
ansible-playbook -i inventory -l k8s-master -u root 02_setup_k8s/setup_k8s_playbook_01.yml
```

Next start the installation of MicroK8s with the next two commands:

```
ansible-playbook -i inventory -l k8s-master -u acn --private-key ~/.ssh/id_rsa_cloud_urban-data_dev_admin 02_setup_k8s/setup_k8s_playbook_02.yml

ansible-playbook -i inventory -l localhost -u acn --private-key ~/.ssh/id_rsa_cloud_urban-data_dev_admin 02_setup_k8s/setup_k8s_playbook_03.yml

```

Now you have a running Installation of MicroK8s and a kubeconfig file in you .kube folder of your home directory.

## Install Platform Components

Run the following command from Repo Root Folder to preconfigure the VM.

```
ansible-playbook -i inventory -l localhost  03_setup_k8s_platform/full_install.yml
```

Now the Base Platform is up and running.

