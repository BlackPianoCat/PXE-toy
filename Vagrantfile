Vagrant.configure("2") do |config|
  
  ##############################
  # PXE Server - Debian Bookworm
  ##############################
  config.vm.define "pxe-server" do |server|
    server.vm.box = "debian/bookworm64"  # stable Debian 12
    server.vm.hostname = "pxe-server"
    
    # Private network for PXE clients
    server.vm.network "private_network", ip: "192.168.56.10"

    # Resource allocation
    server.vm.provider "libvirt" do |lv|
      lv.memory = 1024   # 1 GB RAM
      lv.cpus   = 1      # 1 CPU
    end

    # Provisioning PXE server
    server.vm.provision "shell", inline: <<-SHELL
      # 1️⃣ Create admin user
      sudo useradd -m -s /bin/bash blackpianocat
      echo "blackpianocat:seb4ever" | sudo chpasswd
      sudo usermod -aG sudo blackpianocat

      # 2️⃣ Update minimal system & install PXE packages only
      sudo apt update
      sudo DEBIAN_FRONTEND=noninteractive apt install -y isc-dhcp-server tftpd-hpa syslinux pxelinux

      # 3️⃣ Configure DHCP server to bind to the private network
      IFACE=$(ip -o -4 addr show | grep 192.168.56 | awk '{print $2}')
      echo "INTERFACESv4=\"$IFACE\"" | sudo tee /etc/default/isc-dhcp-server

      # 4️⃣ Create minimal DHCP config for PXE
      sudo tee /etc/dhcp/dhcpd.conf << EOF
default-lease-time 600;
max-lease-time 7200;
subnet 192.168.56.0 netmask 255.255.255.0 {
    range 192.168.56.100 192.168.56.200;
    option routers 192.168.56.10;
    option domain-name-servers 8.8.8.8;
    next-server 192.168.56.10;
    filename "pxelinux.0";
}
EOF

      # 5️⃣ Enable & start PXE services
      sudo systemctl enable isc-dhcp-server tftpd-hpa
      sudo systemctl restart isc-dhcp-server
      sudo systemctl restart tftpd-hpa

      echo "PXE server ready with minimal OS and user blackpianocat"
    SHELL
  end

  ##############################
  # PXE Clients - Alpine minimal
  ##############################
  (1..3).each do |i|
    config.vm.define "pxe-client#{i}" do |client|
      client.vm.box = "generic/alpine314"  # Alpine minimal
      client.vm.hostname = "pxe-client#{i}"
      
      # Private network
      client.vm.network "private_network", ip: "192.168.56.#{20+i}"

      # Resource allocation
      client.vm.provider "libvirt" do |lv|
        lv.memory = 512   # 512 MB RAM
        lv.cpus   = 1
      end

      # Provisioning Alpine client
      client.vm.provision "shell", inline: <<-SHELL
        # 1️⃣ Create admin user
        sudo adduser -D -g '' blackpianocat
        echo "blackpianocat:seb4ever" | sudo chpasswd

        # 2️⃣ Minimal setup: just SSH for now
        sudo apk update
        sudo apk add openssh

        # 3️⃣ Enable SSH service at boot
        sudo rc-update add sshd
        sudo service sshd start

        echo "Alpine client #{i} ready with minimal OS and user blackpianocat"
      SHELL
    end
  end

end

