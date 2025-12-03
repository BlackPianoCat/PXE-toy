Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "pxe-server" do |server|
    server.vm.hostname = "pxe-server"

    # NAT for SSH, host-only for PXE
    server.vm.network "private_network", ip: "192.168.56.10"

    server.vm.provider "virtualbox" do |vb|
      vb.name = "PXE-Server"
      vb.memory = 4096
      vb.cpus = 4
      vb.gui = false
    end

    # Provision PXE server
    server.vm.provision "shell", inline: <<-SHELL
      #!/bin/bash
      set -e

      # Update system
      apt-get update -y
      apt-get install -y dnsmasq pxelinux syslinux-common unzip net-tools

      # Create TFTP root
      mkdir -p /srv/tftp
      cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/ || true

      # Detect PXE interface dynamically
      PXE_IFACE=$(ip -o -4 addr show | awk '/192\\.168\\.56\\./ {print $2; exit}')
      echo "Detected PXE interface: $PXE_IFACE"

      # Configure dnsmasq for PXE
      cat > /etc/dnsmasq.d/pxe.conf <<EOF
interface=$PXE_IFACE
bind-interfaces
dhcp-range=192.168.56.100,192.168.56.200,12h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=/srv/tftp
log-dhcp
EOF

      # Enable and restart dnsmasq
      systemctl enable dnsmasq
      systemctl restart dnsmasq

      # Setup PXELINUX config
      mkdir -p /srv/tftp/pxelinux.cfg
      cat > /srv/tftp/pxelinux.cfg/default <<EOF
DEFAULT local
PROMPT 0
TIMEOUT 50
MENU TITLE PXE Boot Menu

LABEL local
  MENU LABEL Boot Local
  LOCALBOOT 0

LABEL debianlive
  MENU LABEL Debian Live XFCE
  KERNEL debian-live/live/vmlinuz
  APPEND initrd=debian-live/live/initrd.img boot=live components fetch=tftp://192.168.56.10/debian-live/live/filesystem.squashfs
EOF

      # Create ISO directory for PXE boot
      mkdir -p /srv/iso
      echo "PXE server setup completed!"
    SHELL
  end
end

