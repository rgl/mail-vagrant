# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu-16.04-amd64"

  config.vm.hostname = "mail.example.com"

  config.vm.network "private_network", ip: "192.168.33.254"

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = "1024"
  end

  config.vm.provision "shell", path: "provision-powerdns.sh"
  config.vm.provision "shell", path: "provision-postfix.sh"
  config.vm.provision "shell", path: "provision-dovecot.sh"
  config.vm.provision "shell", path: "provision.sh"
end
