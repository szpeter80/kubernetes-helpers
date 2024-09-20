# Install OKD without any platform integration


This helps you create an OKD cluster on your infra (VM or bare metal)

1. Plan your deployment (number of nodes, node size)
1. Provision your infra (DNS, DHCP, Load Balancer)
1. Create a copy of the clusters/sample directory
1. Update your install-config yaml
1. Start the helper from the install directory with '../../../okd-install-helper.sh'
1. Boot the bootstrap, wait until bootstrap finishes
1. Boot your control nodes, wait until Nodes report 'Ready' status
1. Boot your worker nodes
1. Cluster install should be ready under 20-40 minutes

TODO:
-----

- generate completion files
- generate env for cluster