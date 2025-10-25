# Image cloud-init debian 12
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Install de l'agent qemu (proxmox) dans l'image
apt update
apt install -y libguestfs-tools
virt-customize -a debian-12-generic-amd64.qcow2 --install qemu-guest-agent
virt-customize -a debian-12-generic-amd64.qcow2 --run-command "systemctl enable qemu-guest-agent"

# Créer la VM template
qm create 110 \
  --name debian-12-k3s-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0

# Importer le disque
qm importdisk 110 debian-12-generic-amd64.qcow2 local-lvm

# Attacher le disque
qm set 110 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-110-disk-0

#  Ajouter cloud-init
qm set 110 --ide2 local-lvm:cloudinit

#  Définir le boot order
qm set 110 --boot order=scsi0

# Serial console
qm set 110 --serial0 socket --vga serial0

# Activer le QEMU guest agent
qm set 110 --agent enabled=1

# Ajouter les tags
qm set 110 --tags "template,debian-12"

# Convertir en template
qm template 110

# Vérifier
qm config 110