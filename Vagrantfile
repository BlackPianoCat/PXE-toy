Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "pxe-server" do |server|
    server.vm.hostname = "pxe-server"

    # Fixed private network for PXE lab
    server.vm.network "private_network", ip: "192.168.56.10"

    server.vm.provider "virtualbox" do |vb|
      vb.name = "PXE-Server"
      vb.memory = 4024
      vb.cpus = 4
      vb.gui = false
    end

    # Provision PXE server
    server.vm.provision "shell", inline: <<-SHELL
      # Update system
      apt-get update -y
      apt-get install -y dnsmasq pxelinux syslinux-common

      # Create PXE directory
      mkdir -p /srv/tftp
      cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/

      # Configure dnsmasq for PXE
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

