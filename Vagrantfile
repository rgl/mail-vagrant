# to make sure the nodes are created in the defined order, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

config_mail_fqdn              = "mail.example.com"
config_mail_ip_address        = "192.168.33.254"
config_satellite_ip_address   = "192.168.33.253"
config_nullmailer_ip_address  = "192.168.33.252"

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu-18.04-amd64"
 
  config.vm.provider 'libvirt' do |lv, config|
    lv.memory = 256
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 256
    vb.cpus = 2
  end

  config.vm.define "mail" do |config|
    config.vm.hostname = config_mail_fqdn
    config.vm.network "private_network", ip: config_mail_ip_address
    config.vm.provision "shell", path: "provision-certificate.sh", args: [config_mail_fqdn]
    config.vm.provision "shell", path: "provision-dnsmasq.sh", args: [config_satellite_ip_address, config_nullmailer_ip_address]
    config.vm.provision "shell", path: "provision-postfix.sh"
    config.vm.provision "shell", path: "provision-dovecot.sh"
    config.vm.provision "shell", path: "provision.sh"
  end

  config.vm.define "satellite" do |config|
    config.vm.hostname = "satellite.example.com"
    config.vm.network "private_network", ip: config_satellite_ip_address
    config.vm.provision "shell", path: "provision-satellite.sh", args: [config_mail_fqdn, config_mail_ip_address]
  end

  config.vm.define "nullmailer" do |config|
    config.vm.hostname = "nullmailer.example.com"
    config.vm.network "private_network", ip: config_nullmailer_ip_address
    config.vm.provision "shell", path: "provision-nullmailer.sh", args: [config_mail_fqdn, config_mail_ip_address]
  end
end
