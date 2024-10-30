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