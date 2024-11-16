Install and configure a Linux host to run containers from systemd
=================================================================

Target system OS: RHEL and derivatives (Rocky / Alma / Oracle Linux and maybe CentOS Stream)

Steps:

1. Install your VM with a minimal install
    1. if vm cloned from template, re-generate ssh server key (delete keys, on Debian run dpkg-reconfigure openssh-server)
    1. enable sshd
    1. Create 'admin' user
    1. Create dedicated admin ssh key for cluster access (eg remoteadmin_rootlogin_key)
    1. Add this key to the 'admin' account
    1. Ensure 'admin' can sudo without a password (echo 'admin        ALL=(ALL)       NOPASSWD: ALL' >/etc/sudoers.d/admin_nopasswd)
    1. enable and activate time sync
    1. use `hostnamectl hostname <unique.host.name>` to set hostname
    1. if DHCP then reserve a static address
    1. register hostname to dns

1. Fill out ansible inventory
1. If default python is old, set the path to some recent (3.10+) python in your custom.env
1. Run shell scripts in order (first parameter to script is envfile, eg custom.env )
1. Enjoy your new container host :D

Official docs:

TODO

Source: 

TODO
