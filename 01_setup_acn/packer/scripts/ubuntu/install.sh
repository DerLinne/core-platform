#!/bin/sh -eux
export DEBIAN_FRONTEND=noninteractive

. /tmp/packer.env

# Install necessary dependencies
apt-get update
apt-get install -y ca-certificates
apt-get install -y software-properties-common
apt-get install -y sudo
apt-get install -y python3
apt-get install -y pipenv
apt-get install -y git

# Create group 'futr' and user 'acn' and setup sudo to allow no-password sudo for this user.
sudo groupadd -r futr
sudo useradd -m -s /bin/bash acn
sudo usermod -a -G futr acn
sudo cp /etc/sudoers /etc/sudoers.orig
echo "acn  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/acn

# Installing SSH key
sudo mkdir -p /home/acn/.ssh
sudo chmod 700 /home/acn/.ssh
# ACN-Key
sudo cp /tmp/"${FUTR_HUB_ACN_SSHKEY}" /home/acn/.ssh/
sudo chmod 600 /home/acn/.ssh/"${FUTR_HUB_ACN_SSHKEY}"
sudo cp /tmp/"${FUTR_HUB_ACN_SSHKEY}.pub" /home/acn/.ssh/
sudo chmod 644 /home/acn/.ssh/"${FUTR_HUB_ACN_SSHKEY}.pub"
# Git-Repo-Key
sudo cp /tmp/"${FUTR_HUB_GIT_SSHKEY}" /home/acn/.ssh/
sudo chmod 600 /home/acn/.ssh/"${FUTR_HUB_GIT_SSHKEY}"
sudo cp /tmp/"${FUTR_HUB_GIT_SSHKEY}.pub" /home/acn/.ssh/
sudo chmod 644 /home/acn/.ssh/"${FUTR_HUB_GIT_SSHKEY}.pub"
#
sudo chown -R acn /home/acn/.ssh
sudo usermod --shell /bin/bash acn

# Install the latest version of Ansible for user acn
sudo -H -i -u acn -- env bash <<EOF
whoami
echo ~acn

cd /home/acn
pip3 install --user ansible-base
EOF

# Install the required Ansible-Galaxy collections
sudo -H -i -u acn -- env bash <<EOF
whoami
echo ~acn

cd /home/acn
ansible-galaxy install -r /tmp/galaxy-requirements.yml
EOF
