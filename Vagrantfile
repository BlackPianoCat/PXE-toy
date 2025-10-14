Vagrant.configure("2") do |config|

  ##############################
  # PXE Server - Debian Bookworm
  ##############################
  config.vm.define "pxe-server" do |server|
    server.vm.box = "debian/bookworm64"  # Debian 12 stable
    server.vm.hostname = "pxe-server"

    # Private network for PXE clients
    server.vm.network "private_network", ip: "192.168.56.10"

    # Resource allocation
    server.vm.provider "libvirt" do |lv|
      lv.memory = 1024   # 1 GB RAM
      lv.cpus   = 1      # 1 CPU
    end

    # Minimal provisioning for PXE server
    server.vm.provision "shell", inline: <<-SHELL
      # 1️⃣ Create admin user
      sudo useradd -m -s /bin/bash blackpianocat
      echo "blackpianocat:seb4ever" | sudo chpasswd
      sudo usermod -aG sudo blackpianocat

      # 2️⃣ Update system and install minimal PXE packages
      sudo apt update
      sudo DEBIAN_FRONTEND=noninteractive apt install -y dnsmasq pxelinux syslinux-common nfs-kernel-server

      # 3️⃣ Create TFTP root directory
      sudo mkdir -p /var/lib/tftpboot
      sudo chown root:root /var/lib/tftpboot
      sudo chmod 755 /var/lib/tftpboot

      # 4️⃣ Copy PXE bootloader (syslinux)
      sudo cp /usr/lib/PXELINUX/pxelinux.0 /var/lib/tftpboot/
      sudo cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /var/lib/tftpboot/

      # 5️⃣ Enable and start dnsmasq
      sudo systemctl enable dnsmasq
      sudo systemctl restart dnsmasq

      echo "PXE server ready with minimal OS, TFTP, and user blackpianocat"
    SHELL
  end

  ##############################
  # PXE Clients - Alpine minimal
  ##############################
  (1..3).each do |i|
    config.vm.define "pxe-client#{i}" do |client|
      client.vm.box = "generic/alpine314"  # Minimal Alpine
      client.vm.hostname = "pxe-client#{i}"

      # Private network
      client.vm.network "private_network", ip: "192.168.56.#{20+i}"

      # Resource allocation
      client.vm.provider "libvirt" do |lv|
        lv.memory = 512   # 512 MB RAM
        lv.cpus   = 1
      end

      # Minimal provisioning: just SSH
      client.vm.provision "shell", inline: <<-SHELL
        # 1️⃣ Create admin user
        sudo adduser -D -g '' blackpianocat
        echo "blackpianocat:seb4ever" | sudo chpasswd

        # 2️⃣ Install SSH
        sudo apk update
        sudo apk add openssh

        # 3️⃣ Enable SSH service
        sudo rc-update add sshd
        sudo service sshd start

        echo "Alpine client #{i} ready with minimal OS and user blackpianocat"
      SHELL
    end
  end

end

