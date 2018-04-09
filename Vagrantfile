Vagrant.configure("2") do |config|

    config.vm.box = 'bento/centos-7.4'
    config.vm.provision "shell",  :path => "provision.sh"

    config.vm.define :devbox do |dev|
        dev.vm.hostname = "devtest"
        dev.vm.boot_timeout = 3000

        dev.vm.provider "virtualbox" do |v|
            v.name = "devtest.vbox"
            v.memory = 8192
            v.cpus = 8
            v.customize ["modifyvm", :id, "--cableconnected1", "on"]
        end
    end
end
