#!/bin/bash
# check if everything is setup properly
#
IP_ADDR=`hostname -I`
INTERF=`ip a | grep -B 2 $IP_ADDR | awk 'NR==1{print $2}'`
PCI_SLOT=`lspci -nn | grep -i nvidia | awk '{print $1}'`


echo "confirm the IPs and the adapter are correct"
echo "and the template looks correct"
echo ""
echo "${INTERF} ${IP_ADDR}"
echo ""
echo ""

virsh net-dumpxml default
sleep 2
echo ""

echo "confirm the GPU and the modules are addressed correctly"
echo ""
echo "it should be ***"
lspci -nn | grep $PCI_SLOT | awk '{print $8}'
echo "***"
echo ""
sleep 1
echo "verify the attached drivers are vfio-pci"
lspci -k -s $PCI_SLOT
echo ""
sleep 2
echo "file check"
echo ""
echo "/etc/initramfs-tools/modules file"
cat /etc/initramfs-tools/modules | grep vfio
echo ""
echo ""
echo "/etc/modules file"
cat /etc/modules | grep vfio
echo ""
echo ""
exit 0
