Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "pxe-server" do |server|
    server.vm.hostname = "pxe-server"

    # Host-only PXE network
    server.vm.network "private_network", ip: "192.168.56.10"

    server.vm.provider "virtualbox" do |vb|
      vb.name   = "pxe-server"
      vb.memory = 2048
      vb.cpus   = 2
      vb.gui    = false
    end

    server.vm.provision "shell", inline: <<-'SHELL'
      #!/bin/bash
      set -euxo pipefail
      export DEBIAN_FRONTEND=noninteractive

      apt-get update -y
      apt-get install -y \
        dnsmasq \
        nfs-kernel-server \
        pxelinux \
        syslinux-common \
        wget \
        curl

      # -------------------------------------------------
      # Detect the host-only interface automatically
      # -------------------------------------------------

      PXE_IFACE=$(ip -o -4 addr show | awk '/192\.168\.56/ {print $2}')
      echo "Detected PXE interface: ${PXE_IFACE}"

      # -------------------------------------------------
      # Prepare TFTP structure
      # -------------------------------------------------

      mkdir -p /srv/tftp/pxelinux.cfg
      mkdir -p /srv/nfs/rootfs

      cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
      cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /srv/tftp/

      # Debian installer kernel
      cd /srv/tftp
      wget -q https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux -O vmlinuz
      wget -q https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz -O initrd.img

      # PXE boot menu
      cat > /srv/tftp/pxelinux.cfg/default <<EOF
DEFAULT install
LABEL install
  KERNEL vmlinuz
  APPEND initrd=initrd.img ip=dhcp
EOF

      # -------------------------------------------------
      # Configure dnsmasq cleanly
      # -------------------------------------------------

      systemctl stop dnsmasq || true

      cat > /etc/dnsmasq.conf <<EOF
port=0
interface=${PXE_IFACE}
dhcp-range=192.168.56.100,192.168.56.200,12h
enable-tftp
tftp-root=/srv/tftp
dhcp-boot=pxelinux.0
log-dhcp
EOF

      systemctl enable dnsmasq
      systemctl restart dnsmasq

      # -------------------------------------------------
      # Configure NFS export
      # -------------------------------------------------

      echo "/srv/nfs/rootfs *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
      exportfs -ra
      systemctl enable nfs-kernel-server
      systemctl restart nfs-kernel-server

    SHELL
  end
end
