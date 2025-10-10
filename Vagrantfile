Vagrant.configure("2") do |config|
  
  ##############################
  # PXE Server - Debian Bookworm XFCE
  ##############################
  config.vm.define "pxe-server" do |server|
    server.vm.box = "debian/bookworm64"  # stable Debian 12
    server.vm.hostname = "pxe-server"
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.provider "libvirt" do |lv|
      lv.memory = 2048
      lv.cpus = 2
    end

    server.vm.provision "shell", inline: <<-SHELL
      # Create admin user
      sudo useradd -m -s /bin/bash blackpianocat
      echo "blackpianocat:seb4ever" | sudo chpasswd
      sudo usermod -aG sudo blackpianocat

      # Update system and install XFCE + display manager
      sudo apt update
      sudo apt install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
        isc-dhcp-server tftpd-hpa syslinux pxelinux

      # Ensure lightdm starts at boot
      sudo systemctl enable lightdm

      # Enable PXE services
      sudo systemctl enable tftpd-hpa isc-dhcp-server
      sudo systemctl start tftpd-hpa isc-dhcp-server

      echo "PXE server ready with XFCE and admin user blackpianocat"
    SHELL
  end

  ##############################
  # PXE Clients - Alpine lightweight DE
  ##############################
  (1..3).each do |i|
    config.vm.define "pxe-client#{i}" do |client|
      client.vm.box = "generic/alpine314"  # Alpine lightweight
      client.vm.hostname = "pxe-client#{i}"
      client.vm.network "private_network", ip: "192.168.56.#{20+i}"
      client.vm.provider "libvirt" do |lv|
        lv.memory = 512
        lv.cpus = 1
      end

      client.vm.provision "shell", inline: <<-SHELL
        # Create admin user
        sudo adduser -D -g '' blackpianocat
        echo "blackpianocat:seb4ever" | sudo chpasswd

        # Install minimal X server + lightweight DE (Xfce-lite)
        sudo apk update
        sudo apk add xorg-server xfce4-terminal xfce4-session \
          xfce4-panel xfwm4 lightdm lightdm-gtk-greeter dbus

        # Enable LightDM at boot
        sudo rc-update add dbus
        sudo rc-update add lightdm

        echo "Alpine client #{i} ready with lightweight DE and user blackpianocat"
      SHELL
    end
  end

end

