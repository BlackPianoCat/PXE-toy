Vagrant.configure("2") do |config|

  config.vm.define "pxe-server" do |server|
    server.vm.box = "debian/bookworm64"
    server.vm.hostname = "pxe-server"

    # Private network for PXE lab
    server.vm.network "private_network", ip: "192.168.56.10"

    server.vm.provider "virtualbox" do |vb|
      vb.name   = "PXE-Server"
      vb.memory = 1024
      vb.cpus   = 1
      vb.gui    = false
    end

    server.vm.provision "shell", inline: <<-SHELL
      # Update and install PXE stack + sudo
      apt-get update -y
      apt-get install -y sudo dnsmasq pxelinux syslinux-common openssh-server

      # Add Ansible user
      useradd -m -s /bin/bash blackpianocat
      echo "blackpianocat:seby4ever" | chpasswd
      usermod -aG sudo blackpianocat

      # Enable password authentication for SSH
      sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
      systemctl restart ssh

      # PXE setup
      mkdir -p /srv/tftp
      cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/

      cat > /etc/dnsmasq.d/pxe.conf <<EOF
interface=enp0s8
dhcp-range=192.168.56.100,192.168.56.200,12h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=/srv/tftp
EOF

      systemctl enable dnsmasq
      systemctl restart dnsmasq
    SHELL
  end

end

