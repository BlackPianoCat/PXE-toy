Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  # ----------------------------
  # PXE Server only
  # ----------------------------
  config.vm.define "pxe-server" do |server|
    server.vm.hostname = "pxe-server"

    # Private network with static IP to match Ansible hosts
    server.vm.network "private_network", ip: "192.168.56.10"

    server.vm.provider "virtualbox" do |vb|
      vb.name = "pxe-server"
      vb.memory = 2048
      vb.cpus = 2
      vb.gui = false
    end

    # Ensure Vagrant injects SSH key for Ansible
    server.ssh.insert_key = true

    # Provision minimal setup
    server.vm.provision "shell", inline: <<-SHELL
      #!/bin/bash
      set -euxo pipefail

      # Wait for network
      until ping -c1 8.8.8.8 &>/dev/null; do sleep 2; done

      # Install base packages
      DEBIAN_FRONTEND=noninteractive apt-get update -y
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        sudo vim curl wget net-tools iproute2 ntpdate rsync debootstrap \
        systemd-timesyncd dnsmasq nfs-kernel-server pxelinux syslinux-common tftp unzip

      # Sync time (non-blocking)
      ntpdate -u pool.ntp.org || true

      # Hostname and hosts file
      echo "pxe-server" > /etc/hostname
      cat > /etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   pxe-server
EOF

      systemctl enable systemd-timesyncd
      systemctl restart systemd-timesyncd || true
    SHELL
  end
end

