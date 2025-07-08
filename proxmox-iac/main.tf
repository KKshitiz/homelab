resource "proxmox_vm_qemu" "dev_vm" {
  name        = "dev-node-1"
  target_node = "proxmox"
  clone       = "ubuntu-2404-cloudinit-template"
onboot = false
 bios = "seabios"
  desc = "Dev Node 1 to test terraform"
	automatic_reboot = false
	agent = 1


  cpu {
	cores = 2
  }
  memory      = 2048

  ipconfig0 = "ip=192.168.29.0/24,gw=192.168.29.1"
  ciuser    = "ubuntu"
  cipassword = "ubuntu"

#   sshkeys = file("~/.ssh/id_rsa.pub")
}
