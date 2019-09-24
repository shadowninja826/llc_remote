#!/bin/bash

# sudo to run
# this script will update a node
# install and setup virsh
# Add a virsh pod update the PCI for passthough

# declare a variable for the IP of the host

# IP address of node
IP=`ip a | grep 172.27 | awk '{print $2}' | rev | cut -c 4- | rev`

# PCI Address of GPU
PCI_ADD=`lspci -nn | grep -i nvidia | awk '{print $10}' | cut -c -10 | rev | cut -c -9 | rev`

ETH=`ip a | grep -B 2 172.27 | awk 'NR==1{print $2}' | rev | cut -c 2- | rev`
ADAPTER_NUM=`ip a | grep -B 2 172.27 | awk 'NR==1{print $2}' | cut -c 4`


# IP = ip a | grep -B 2 172 | awk 'NR==3{print $2}' | rev | cut -c 4- | rev
# ETH = ip a | grep -B 2 172 | awk 'NR==1{print $2}' | rev | cut -c 2- | rev
sudo add-apt-repository ppa:maas/stable -y
sudo apt update
sudo apt upgrade -y
sudo apt install bridge-utils qemu-kvm libvirt-bin -y


# download and ssh key

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmJ9VGFBx+FE2hiq3Izi2k1juczwhP5WOHK7p9BL3CHezSSvKq4MsHfFMm0lL8E1G80p/b/579jZZfWeTR8vX0MhdL4eoFYpSn8QY+yrOhn9xYYC7NYFtNT4GFYrbO9HTheR3BVMThIW5Xtp7SzcY6ODUzJNjPtXZXF3ZQDSS3ipFlFaYcL0kXQFISm0uG9sC0Ke+3bSuTEzSue6/VJo5ga/VTNDGUmTXfA5ckfXxn4GRGY8bHLy5c4KpNoxJgqmmTtmNLcAIzUGYfqnAlHEe6OS/a7zO48A5LkRsj0EMZJ7Y3G1hjK2VIAnMftiM3A1eY5VNQyrFItimbO0buZUsD maas@LLCServer180" >> ~/.ssh/authorized_keys



# Next, edit cloud-init network interfaces file 50-cloud-init.cfg to setup virsh bridge.
# Depending on whether eth0 or eth1 is connected to management network, you may need to replace eth1 and br1 in remaining instructions.  Dell and Kontron servers are attached on eth1 while V4N servers are on eth0.

sudo cp /etc/network/interfaces.d/50-cloud-init.cfg ~/50-cloud-init.cfg.bak


sudo cat<<EOT > /etc/network/interfaces.d/50-cloud-init.cfg
# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
auto lo
iface lo inet loopback
    dns-nameservers 172.27.180.1 8.8.8.8
    dns-search maas

auto eth0
iface eth0 inet manual
    mtu 1500

auto br0
iface br0 inet static
    address ${IP}/23
    dns-nameservers 172.27.180.1 8.8.8.8
    gateway 172.27.181.254
    bridge_ports eth0
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0

auto eth1
iface eth1 inet manual
    mtu 1500

auto eth2
iface eth2 inet manual
    mtu 1500

auto eth3
iface eth3 inet manual
    mtu 1500
EOT
echo ""
echo ""
echo ""
echo "content of /etc/network/interfaces.d/50-cloud-init.cfg"
cat /etc/network/interfaces.d/50-cloud-init.cfg
echo ""
echo ""

# Do NOT ifup/ifdown the eth0 or br0 interface or you will lose connection to machine.  Instead, do a reboot.
# run 'lspci -nn | grep -i nvidia' to locate the pci address
# IE. 21:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:15f8] (rev a1)
# 10de:15f8 is the pci address for tesla p100
# Update this script with the correct address
# Then execute as root and reboot
#


sudo mv /etc/modules "~/etc_modules.$(date +%F-%H-%M).bak"
sudo cat <<EOT >> /etc/modules
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.
vfio
vfio_iommu_type1
vfio_pci ids=$PCI_ADD
vhost-net
EOT


mv /etc/initramfs-tools/modules "~/etc_init_modules.$(date +%F-%H-%M).bak"
sudo cat <<EOT >> /etc/initramfs-tools/modules
# List of modules that you want to include in your initramfs.
# They will be loaded at boot time in the order below.
#
# Syntax:  module_name [args ...]
#
# You must run update-initramfs(8) to effect this change.
#
# Examples:
#
# raid1
# sd_mod
vfio
vfio_iommu_type1
vfio_pci ids=$PCI_ADD
vhost-net
EOT

echo "content of /etc/modules"
cat /etc/modules
echo ""
echo ""
echo ""
echo "content of /etc/initramfs-tools/modules"
cat /etc/initramfs-tools/modules
echo ""
echo "content of nothing - end"
echo ""
echo ""
echo "updating initramfs "

sudo update-initramfs -u

echo "reboot to complete changes"
echo "run llc_net_define1.sh after node comes back online"
# creating the next script to run
cat <<EOTW > ~/llc_net_define1.sh
#!/bin/bash
sudo virsh net-list
sleep 2
sudo virsh net-destroy default
sleep 2
sudo virsh net-undefine default
sleep 2

sudo cat <<EOT > ~/net-default.xml
<network>
		<name>default</name>
		<forward mode="bridge" />
		<bridge name="br${ADAPTER_NUM}" />
</network>
EOT

virsh net-define ~/net-default.xml
virsh net-autostart default
virsh net-start default
sleep 2
virsh pool-define-as default dir - - - - "/var/lib/libvirt/images"
virsh pool-autostart default
virsh pool-start default

echo "Virsh address: qemu+ssh://ubuntu@$IP/system"

exit 0
EOTW

sudo chmod +x ~/llc_net_define1.sh
sudo chmod +x ~/llc_remote/llc_check_pod.sh
echo ""
echo ""
echo "reboot to complete changes"
echo "run llc_net_define1.sh after node comes back online"

exit 0

