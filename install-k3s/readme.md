Install a K3S Kubernetes cluster
================================

Key points:

- Single master: only sandbox/dev/test use, not produciton ready


Steps:

1. Create the VMs (2CPU / 4G RAM at least)
2. Create admin ssh key enable root login with that on all nodes
3. Fill out ansible inventory
4. Run shell scripts in order
5. Enjoy your new k3s cluster :D