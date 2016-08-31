## Capistrano UTILS
## Author: pavel.jedlicka@akqa.com

namespace :config do 

  task :create do

# Bootstrap script
config = <<SCRIPT
#!/bin/bash
# postinstall.sh
HNAME_REAL=$(hostname)
HNAME=$(echo $HNAME_REAL | tr "[A-Z]" "[a-z]")
DNAME="#{domain}"
PUPPETMASTER="#{puppetmaster}"
ENVIRONMENT="#{env}"

if which lsb_release >/dev/null; then
CODENAME=$(lsb_release -c | cut -f2)
DISTRO=$(lsb_release -i | cut -f2)
else
DISTRO=$(cat /etc/issue | head -n1 | cut -d " " -f1)
fi

# Debian distros
if [ $DISTRO == "Ubuntu" ]; then
echo "deb http://apt.puppetlabs.com $CODENAME main dependencies" > /etc/apt/sources.list.d/puppetlabs.list
echo "deb http://apt.akqa.net $CODENAME main" > /etc/apt/sources.list.d/akqa.list
cd /tmp
wget http://apt.puppetlabs.com/pubkey.gpg
gpg --import pubkey.gpg
gpg -a --export 4BD6EC30 | apt-key add -
mkdir /etc/puppet
echo -e "\n++ writing confs ++"
echo "
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
# Setting templatedir is deprecated
# templatedir=\$confdir/templates
server=$PUPPETMASTER
ca_server=$PUPPETMASTER
certname=$HNAME.$DNAME
configtimeout = 600
pluginsync = true
environment = $ENVIRONMENT

[agent]
report = true " > /etc/puppet/puppet.conf
echo "
# Start puppet on boot?
START=no
# Startup options
DAEMON_OPTS=\"\" " > /etc/default/puppet
apt-get update
apt-get install -o Dpkg::Options::="--force-confold" --force-yes -y puppet=3.6.2-1puppetlabs1 puppet-common=3.6.2-1puppetlabs1
exit $?
fi
# CentOS distros
if [ $DISTRO == "CentOS" ]; then
## Check Issue version, add puppet repository
if grep -q 5. /etc/issue; then
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm
EL=el5
fi
if grep -q 6. /etc/issue; then
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
EL=el6
fi
if grep -q 7. /etc/issue; then
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
EL=el7
fi
yum -y install puppet-3.6.2-1.$EL
echo "
127.0.0.1	 $HNAME.$DNAME $DNAME localhost
" > /etc/hosts
mkdir /etc/puppet
echo -e "\n++ writing confs ++"
echo "
[main]
# The Puppet log directory.
# The default value is '$vardir/log'.
logdir = /var/log/puppet
# Where Puppet PID files are kept.
# The default value is '$vardir/run'.
rundir = /var/run/puppet
# Where SSL certificates are kept.
# The default value is '$confdir/ssl'.
ssldir = $vardir/ssl
server = $PUPPETMASTER
ca_server = $PUPPETMASTER
certname = $HNAME.$DNAME
pluginsync = true
configtimeout = 600
environment = $ENVIRONMENT
[agent]
# The file in which puppetd stores a list of the classes
# associated with the retrieved configuratiion.  Can be loaded in
# the separate ``puppet`` executable using the ``--loadclasses``
# option.
# The default value is '$confdir/classes.txt'.
classfile = $vardir/classes.txt
# Where puppetd caches the local configuration.  An
# extension indicating the cache format is added automatically.
# The default value is '$confdir/localconfig'.
localconfig = $vardir/localconfig " > /etc/puppet/puppet.conf
exit $?
fi	
SCRIPT

system("echo '#{config}' > puppet/bootstrap.sh")
system("chmod +x puppet/bootstrap.sh")

  end 

end
