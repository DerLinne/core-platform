# Urban Data Platform CI CD Configuration

The deployment of the project is done via the GitLab CI/CD feature to provide ready-to-use environments on a blank machine.<br>
For complete and more in-depth documentation of outlined steps please refer to the [Complete Installation](INSTALL.md) or [Platform Installation](FULL_INSTALL.md).

## General

The CI/CD is used to cover 4 environments. Namely: dev1, dev2, staging and production. Additionally the [.gitlab-ci.yml File](../../.gitlab-ci.yml) can be used as a reference to get an idea, how certain tasks (used ssh-keys, retrieving the kubeconfig) are performed.

## Stages

The CI is build with 6 stages

* `verify` - After each commit the source code is verified to assure, certain rules and conventions are met, in order to keep the code-quality high.
* `dev1` - Collection of all jobs to deploy k8s, the platform, and certain components.
* `dev2` - Collection of all jobs to deploy k8s, the platform, and certain components.
* `staging` - Collection of all jobs to deploy k8s, the platform, and certain components.
* `prod` - Collection of all jobs to deploy k8s, the platform, and certain components.
* `test` - An artifact and currently unused, but for future development reserved for end-to-end testing jobs.

### Jobs

#### Verify

The verify stage uses the `ansible-lint` tool to verify multiple coding guidelines to improve readability, maintainability, consistsency and more.<br>
All other stages are set to be depended on this stage. So the verify stage and its checks have to complete with a success, otherwise deployments/changes to the platform are not allowed.

#### Deployment

Since the jobs of dev1, dev2, staging and prod only differ in the used CI Varialbes, the description is the same for all 4 environtments.

Environment Deployments

* `deploy_{ENVIRONMENT}_k8s`<br>
Runs the 3 playbooks, used to install k8s on the remote system.
* `deploy_{ENVIRONMENT}_platform`<br>
Runs the full_install playbook, used to install all platform componentens on the remote system.
* `deploy_{ENVIRONMENT}_{COMPONENT}`<br>
Runs the the specific playbook, used to install the {COMPONENT} on the remote system.

Envrionment Methods

* `.ssh_config_{ENVIRONMENT}`<br>
This method is used by all deployment jobs and its purpose is to setup the runner with everything needed to connect to the remote machine - accessing the SSH keys and creating the SSH config
* `.prepare_deploy_{ENVIRONMENT}`<br>
This method is used by tasks after k8s has been installed to the remote system to prepare environment specific requirements, needed to run the ansible scripts - accessing the inventory, install specifc python packages and retrieving the kubeconfig.

Additionally a method is available, which is used by all deployment jobs, over all environments.

* `.pre_deploy`<br>
This method makes general preparations to the runner: Updating the system, adding apt repos for kubectl and helm, installing required python packages and installing required system packages.

## Variables

A set of CI Variables are in place for each environment, describing the customizable portions for the remote system.

* `{ENVIRONMENT}_INVENTORY_FULL`: The inventory for the system, based on the [inventory.default](../../03_setup_k8s_platform/inventory.default) file
* `{ENVIRONMENT}_KEY_PRIVATE`: The private portion of an SSH key, which shall be used when interacting with the remote system.
* `{ENVIRONMENT}_KEY_PUBLIC`: The public portion of an SSH key, which shall be used when interacting with the remote system.
* `{ENVIRONMENT}_TARGET_HOST`: The reachable IP address of the target system.

Additionally the hostname is held in a CI Variable, which is used by ansible:

* `TARGET_HOSTNAME`: If installing to a remote system, set to match the hostname in the CI Variable `{ENVIRONMENT}_INVENTORY_FULL`.
