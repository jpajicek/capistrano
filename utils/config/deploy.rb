## Capistrano UTILS
## Author: pavel.jedlicka@akqa.com

load 'deploy'
require 'rubygems'
set :hosts, (ENV['HOSTS'])
set :env, (ENV['ENV'] || ENV['ENV'] = "production")
set :domain, (ENV['DOMAIN'] || ENV['DOMAIN'] = "emea.akqa.local")
set :puppetmaster, (ENV['PUPPETMASTER'] || ENV['PUPPETMASTER'] = "puppet.akqa.net") 
set :whitelist,  (ENV['WHITELIST'] || ENV['WHITELIST'] = "10.2.20.3")

set(:user, Capistrano::CLI.ui.ask("Remote username: ") )
set(:password, Capistrano::CLI.password_prompt("Password for user #{user}: ") )

if hosts.nil?
set(:servername, Capistrano::CLI.ui.ask("Remote server ipaddress: ") )
role :app, "#{servername}"
end

set :use_sudo, true
set :default_shell, "bash"
      
# NRPE 
set :install_script, "nrpe/scripts/install.sh"
set :nrpe_config, "nrpe/config/nrpe.cfg"
set :nrpe_plugins, "nrpe/plugins"

case env
when 'production'
  #
when 'tech'
  #
when 'dev'
  #
else
  raise("Invalid environment '#{env}', must be 'production', 'tech', or 'development'")
end

default_run_options[:pty] = true
load File.join(File.dirname(__FILE__), 'bootstrap.rb')
load File.join(File.dirname(__FILE__), 'shared.rb')


namespace :bootstrap do

  desc "Setup puppet agent on remote server"
  task :default do
     config.create
     deploy
  end

  task :deploy do

    # We tar up the puppet directory from the current directory -- the puppet directory within the source code repository
    system("tar -czf 'puppet.tar.gz' puppet/")
    upload("puppet.tar.gz","/tmp",:via => :scp)
    # Untar the puppet directory
    run("tar -xzf /tmp/puppet.tar.gz -C /tmp")
  
    # Bootstrap Puppet!
    try_sudo("bash /tmp/puppet/bootstrap.sh")
    try_sudo("puppet agent --no-daemonize --onetime --verbose")
  end

end


namespace :puppet do

  desc "Setup puppet agent on remote server"
  task :bootstrap do
     config.create
     deploy
  end

  task :deploy do

    # We tar up the puppet directory from the current directory -- the puppet directory within the source code repository
    system("tar -czf 'puppet.tar.gz' puppet/")
    upload("puppet.tar.gz","/tmp",:via => :scp)
    # Untar the puppet directory
    run("tar -xzf /tmp/puppet.tar.gz -C /tmp")

    # Bootstrap Puppet!
    try_sudo("bash /tmp/puppet/bootstrap.sh")
    try_sudo("puppet agent --no-daemonize --onetime --verbose")
  end
 
  desc "Do puppet run on remote server"
  task :agent do
    # Run puppet agent
    try_sudo("puppet agent --no-daemonize --onetime --verbose")
  end

end 

namespace :nrpe do

  desc "Setup puppet agent on remote server"
  task :setup do
     install
     configure
     restart
  end

  desc "Install NRPE agent"
  task :install do
    upload("#{install_script}","/tmp",:via => :scp)
    try_sudo("bash /tmp/install.sh")
  end

  desc "Configure NRPE"
  task :configure do    
    upload("#{nrpe_config}","/tmp",:via => :scp)
    upload("#{nrpe_plugins}","/tmp",:via => :scp, :recursive => true)
    try_sudo("mv -f /tmp/nrpe.cfg /etc/nagios/nrpe.cfg && sudo mv -f /tmp/plugins/* /usr/lib/nagios/plugins/")
  end

  desc "Restart NRPE"
  task :restart do
    if remote_file_exists?('/etc/init.d/nagios-nrpe-server')
      try_sudo("/etc/init.d/nagios-nrpe-server restart")
    else
      try_sudo("/etc/init.d/nrpe restart")
    end
  end

end

namespace :nscp do
 
  desc "Install NSclient++"

  task :setup do    
     set(:domain, Capistrano::CLI.ui.ask("NT DOMAIN: "))
     connection_test
     upload
     install
     configure
     restart
  end

  task :connection_test do
    puts "Testing connection to #{servername}"
    run_local("smbclient -d 0 //#{servername}/c$ -U #{user}%#{password} -W #{domain} -c 'exit'")
  end

  task :upload do
    puts "Uploading files to #{servername}"
    system("smbclient -d 0 //#{servername}/c$ -U #{user}%#{password} -W #{domain} -c 'recurse ; prompt ; mput nscp'")
  end

  task :install do
    puts "Installing NSclient++ on #{servername}"
    system("/usr/bin/winexe --reinstall -U #{domain}/#{user}%#{password} -d 0 //#{servername} 'cmd /c c:\\nscp\\install\\NSCP-0.4.1.101-x64.msi'")
  end

  task :configure do
    puts "Configuring NSclient++ on #{servername}"
    system("/usr/bin/winexe --reinstall -U #{domain}/#{user}%#{password} -d 0 //#{servername} 'cmd /c copy /Y \"\\nscp\\config\\nsclient.ini\" \"\\Program Files\\NSClient++\\\"'")
    system("/usr/bin/winexe --reinstall -U #{domain}/#{user}%#{password} -d 0 //#{servername} 'cmd /c copy /Y \"\\nscp\\plugins\\*\" \"\\Program Files\\NSClient++\\scripts\\\"'")
  end

  task :restart do
    puts "Restarting NSclient++ on #{servername}"
    system("/usr/bin/winexe --reinstall -U #{domain}/#{user}%#{password} -d 0 //#{servername} 'cmd /c net stop nscp && net start nscp'")
  end

end


namespace :maintenance do

  desc "Put on maintenance page"
  
  task :start do    
    try_sudo("/sbin/iptables -t nat -A PREROUTING -p tcp --dport 443 ! -s #{whitelist} -j REDIRECT --to-port 8888")   
    try_sudo("/sbin/iptables -t nat -A PREROUTING -p tcp --dport 7999 ! -s #{whitelist} -j REDIRECT --to-port 8888")
    try_sudo("/etc/init.d/apache2 restart")
  end

  task :stop do
    try_sudo("/sbin/iptables -F -t nat")
    try_sudo("/etc/init.d/apache2 restart")
  end

end

