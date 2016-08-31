#!/bin/bash
# install.sh - Install nrpe on linux boxes

#apt-get install lsb-release


CODENAME=$(lsb_release -c | cut -f2)
DISTRO=$(head -1 /etc/issue | awk '{ print $1 }')
ARCH=$(uname -i)

# Debian distros
if [ $DISTRO == "Ubuntu" ]; then
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -o Dpkg::Options::="--force-confold" --force-yes -q -y nagios-nrpe-server nagios-nrpe-plugin
## Plugin dependecies
apt-get install -o Dpkg::Options::="--force-confold" --force-yes -q -y sysstat ksh
exit $?
fi

# CentOS distros
if [ $DISTRO == "CentOS" ]; then

cd  /tmp
yum -y install wget

function install_nrpe() {
  yum -y install nagios-plugins-nrpe nagios-nrpe nrpe
}

  if grep -q 5. /etc/issue; then
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el5.rf.$ARCH.rpm
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm -i rpmforge-release-0.5.3-1.el5.rf.$ARCH.rpm
    install_nrpe
  elif grep -q 6. /etc/issue; then
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.$ARCH.rpm
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm -i rpmforge-release-0.5.3-1.el6.rf.$ARCH.rpm
    install_nrpe
  else
    exit 1
  fi
fi
