#!/bin/sh -eux

# Remove some packages to get a minimal install
echo "==> Removing all linux kernels except the currrent one"
dpkg --list | awk '{ print $2 }' |
    grep -e 'linux-\(headers\|image\)-.*[0-9]\($\|-generic\)' |
    grep -v "$(uname -r | sed 's/-generic//')" |
    xargs apt-get -y purge

echo "==> Removing linux source"
dpkg --list | awk '{ print $2 }' | grep linux-source | xargs apt-get -y purge

echo "==> Removing development packages"
dpkg --list | awk '{ print $2 }' | grep -- '-dev$' | xargs apt-get -y purge

echo "==> Removing documentation"
dpkg --list | awk '{ print $2 }' | grep -- '-doc$' | xargs apt-get -y purge

echo "==> Removing development tools"
apt-get -y purge build-essential

echo "==> Removing default system Ruby"
apt-get -y purge ruby ri

echo "==> Removing X11 libraries"
apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6

echo "==> Removing obsolete networking components"
apt-get -y purge ppp pppconfig pppoeconf

echo "==> Removing other oddities"
apt-get -y purge popularity-contest installation-report landscape-common wireless-tools wpasupplicant

# Exlude the files we don't need w/o uninstalling linux-firmware
echo "==> Setup dpkg excludes for linux-firmware"
cat <<_EOF_ | cat >>/etc/dpkg/dpkg.cfg.d/excludes
#PACKER-BEGIN
path-exclude=/lib/firmware/*
path-exclude=/usr/share/doc/linux-firmware/*
#PACKER-END
_EOF_

# Delete the massive firmware packages
rm -rf /lib/firmware/*
rm -rf /usr/share/doc/linux-firmware/*

# Clean up the apt cache
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean

echo "==> Removing man pages"
rm -rf /usr/share/man/*

echo "==> Removing any docs"
rm -rf /usr/share/doc/*
echo "==> Removing caches"
find /var/cache -type f -exec rm -rf {} \;
# delete any logs that have built up during the install
find /var/log/ -name '*.log' -exec rm -f {} \;

# Blank netplan machine-id (DUID) so machines get unique ID generated on boot.
truncate -s 0 /etc/machine-id
