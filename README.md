# llc_remote
create pods and passthrough gpu - Kontron nodes

--
llc_deploy_pod.sh will install virt tools and prepare the physical node to be managed by MaaS and create a bridged adapter
The pci attach will scan and add the available GPU in the node, designed for a single GPU on a host. 
