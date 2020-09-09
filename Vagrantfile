Vagrant.configure("2") do |config|

  config.vm.define "clusterController" do |controller|
    controller.vm.hostname = "cluster.controller"
    controller.vm.box = "ubuntu/trusty64"
    controller.vm.disk :disk, size: "75GB", primary: true
    controller.vm.network "private_network", ip: "192.168.0.100"
    controller.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end

    controller.vm.provision "shell", path: ""
  end

  N = 3

  (0..N).each do |i|
    config.vm.define "clusterNode#{i}" do |node|
      node.vm.hostname = "cluster.node.#{i}"
      node.vm.box = "ubuntu/trusty64"
      node.vm.disk :disk, size: "75GB", primary: true
      node.vm.disk :disk, size: "75GB", name: "kubevol"
      node.vm.network "private_network", ip: "192.168.0.#{10+i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 
      end
    end
  end
end
