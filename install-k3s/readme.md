Install a K3S Kubernetes cluster
================================

Key points:

- Single master: only sandbox/dev/test use, not produciton ready


Steps:

1. Create dedicated admin ssh key for cluster access (remoteadmin_rootlogin_key)
1. Create the VMs (min: 2CPU / 4G RAM / 40G disk)
    1. if vm cloned from template, re-generate ssh server key (delete keys, on Debian run dpkg-reconfigure openssh-server)
    1. enable sshd and ssh root login with the admin key on all nodes
    1. enable and activate time sync
    1. use `hostnamectl hostname <unique.host.name>` to set hostname
    1. if DHCP then reserve a static address
    1. register hostname to dns
1. Fill out ansible inventory
1. If default python is old, set the path to some recent (3.10+) python in your custom.env
1. Run shell scripts in order (first parameter to script is envfile, eg custom.env )
1. Enjoy your new k3s cluster :D

Official docs:

- <https://docs.k3s.io/>
- <https://github.com/k3s-io/k3s/releases>

Longhorn best practices:

In order to work, label your storage nodes with "node.longhorn.io/create-default-disk=true" and mount a disk in fstab on the node permamently udner /srv/lognhorn.  
Pods consuming Longhorn PVs must run on nodes which are also Longhorn nodes.  
In other words: if you restrict Longhorn nodes to a few of the cluster nodes, Pods with Longhorn PVCs needs to be scheduled on those nodes, otherwise the mount will fail.

Source: <https://medium.com/@petolofsson/best-practices-for-longhorn-067d4ccb5fdd>

  - Use dedicated disk(s), not the root volume (/var/lib/longhorn by default)
  - If possible use dedicated storage nodes. The cluster can collapse if flapping storage nodes and affected user workloads starts to generate a flood of API requests.
  - Set default replica count: "2". It provides resiliency while saves disk space and network bandwith.
  - Set "best-effort" as the default data locality -> tries to place one copy of data next to the control engine. This means better IOPS and lower / stable io latency.
