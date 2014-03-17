#!/bin/bash
# install.sh - Install nrpe on linux boxes

CODENAME=$(lsb_release -c | cut -f2)
DISTRO=$(lsb_release -i | cut -f2)

# Debian distros
if [ $DISTRO == "Ubuntu" ]; then
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -o Dpkg::Options::="--force-confold" --force-yes -q -y nagios-nrpe-server nagios-nrpe-plugin
exit $?
fi

# CentOS distros
if [ $DISTRO == "CentOS" ]; then
echo "This OS is not supported yet"
exit 1
fi
