# What are we building ?

A 3-node Kubernetes "Compact Cluster" lab, based on Fedora CoreOS and OKD, on MS Azure.

## How ?

Terraform create the networking and VMs in Azure, then scripts and Ansible
finish the installation.

## Prerequisites ?

- a linux box to start the process (WSL2 is fine)
  - installed Azure CLI
  - installed Terraform
- an Azure subscription and permissions to deploy there

## Costs ?

Azure resources are not free, but neither is hardware / power / cooling / real estate space.
You can sign up for a free credit for 30 days, and if you shut down (and deallocate !) the VMs,
you only pay for the storage of the disks.

Other cost saving option is to delete all your resources when you are not using them.

## References

- The idea:
["Guide:Installing an OKD 4.5 Cluster" by Craig Robinson](<https://itnext.io/guide-installing-an-okd-4-5-cluster-508a2631cbee>)

- Official FCOS docs:
[Provisioning Fedora CoreOS on Azure](<https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-azure/>)

- Official [OKD 4 Documentation](<https://docs.okd.io/latest/welcome/index.html>)
