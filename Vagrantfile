# -*- mode: ruby -*-
# vi: set ft=ruby :
#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \  
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /  
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/   
#                                                                         
# Author : Fred Moser <moser.frederic@gmail.com>
# Date : 30 december 2014
# 
# Script to configure virtual box VM using Vagrant.
# Provisioning is done with provision.sh
#

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"
  # name and basic config of the VM
  config.vm.provider "virtualbox" do |v|
   # v.memory = 4096
    v.memory = 2048
    v.cpus = 2
    v.name = "accessmodServer"
  end
  # provision : shell script
  config.vm.provision "shell", path: "provision.sh"
  # Create a forwarded port mapping which allows access to a specific port
  #config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3838, host: 8080
  # Create a private network, which allows host-only access to the machine
  config.vm.network "private_network", ip: "192.168.38.38"
  config.vm.hostname = "accessmod"
  # set sync folder config.vm.sync_folder "host", "guest"
  # config.vm.synced_folder "/Users/fxi/Public/share/maps", "/sharedFile"
  # config.vm.synced_folder "/Users/fxi/accessMod5Link/github/accessmodServer.git", "/sharedConfig"

  # http://serverfault.com/questions/495914/vagrant-slow-internet-connection-in-guest
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--nictype1", "virtio"]
    v.customize ["modifyvm", :id, "--nictype2", "virtio"]
    v.customize ["modifyvm", :id, "--nictype3", "virtio"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    v.customize ["modifyvm", :id, "--chipset", "ich9"]
    end

end


