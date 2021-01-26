

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

Cloning Git repository <YOUR_FUTR_HUB_GIT_REPO>
with branch <YOUR_FUTR_HUB_GIT_REPO_BRANCH>
into <YOUR_FUTR_HUB_GIT_REPO>.

-------------------------------------------------------------------------------
ATTENTION!
IF ENVIRONMENT VARIABLES

- FUTR_HUB_GIT_REPO
- FUTR_HUB_GIT_BRANCH
- FUTR_HUB_GIT_CLONE_DIR

ARE NOT SET YOU HAVE TO SET THEM BEFORE YOU CONTINUE!
-------------------------------------------------------------------------------
To continue the installation, please execute the following commands.

  ansible-playbook -i inventory prepare.yml
  ansible-playbook -i inventory main.yml

If you use a SSH-Key to access the Git repository, please
- set FUTR_HUB_GIT_SSHKEY accordingly
- execute the following commands beforehand.

  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/"${FUTR_HUB_GIT_SSHKEY}"

Good luck!
###############################################################################
```
