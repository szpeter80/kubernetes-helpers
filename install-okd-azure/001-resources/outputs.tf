output "ssh_access_to__vm_okd_services" {
  value = "ssh -o ServerAliveInterval=3 -i /tmp/okd-demokey adminuser@${module.m001-network.o_vm-okd-services-pip0.ip_address}"
}

output "rdp_access_to__vm_okd_services" {
  value = "mstsc /v:${module.m001-network.o_vm-okd-services-pip0.ip_address} /f"
}

output "web_access_to__openshift_console" {
  value =  "https://console-openshift-console.apps.${var.x_okd_cluster_name}.zzz" 
}

output "o_vm-okd-services--public_ip" {
  value = module.m001-network.o_vm-okd-services-pip0.ip_address
}

 