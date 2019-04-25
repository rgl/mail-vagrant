config_mail_ip_address      = "192.168.33.254"

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu-18.04-amd64"

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 256
    vb.cpus = 2
  end

  config.vm.define "mail" do |config|
    config.vm.hostname = "mail.example.com"
    config.vm.network "private_network", ip: config_mail_ip_address
    config.vm.provision "shell", path: "provision-dnsmasq.sh"
    config.vm.provision "shell", path: "provision-postfix.sh"
    config.vm.provision "shell", path: "provision-dovecot.sh"
    config.vm.provision "shell", path: "provision.sh"
  end
end
