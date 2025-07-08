#!/bin/bash

wget https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img

apt update -y && apt install libguestfs-tools -y

virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.img --install qemu-guest-agent

# Create VM
qm create 9000 --name "ubuntu-2404-cloudinit-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 ubuntu-24.04-minimal-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Create template from VM
qm template 9000