#!/bin/bash
#
#find and attached pci to vm


PCI_ADD=`lspci | grep -i nvid | awk '{print $1}' | sed 's/\./_/g' | sed 's/\:/_/g'`

BUS=`virsh nodedev-dumpxml pci_0000_$PCI_ADD | grep bus= | awk '{print $3}'`

cat <<EOT >> ~/gpu-pci.xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' $BUS slot='0x00' function='0x0'/>
  </source>
  <alias name='hostdev0'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
</hostdev>
EOT

echo "run the following to attach the GPU" 
echo "***"
echo "virsh attach-device (VM Name) --file ~/gpu-pci.xml --config"
echo "***"
echo "shutdown and restart the VM - not reboot"
exit 0
