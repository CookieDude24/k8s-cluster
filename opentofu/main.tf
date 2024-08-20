terraform {
  required_providers {
    proxmox = {
      source = "registry.terraform.io/Telmate/proxmox"
      #latest version as of Nov 30 2022
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  # References our vars.tf file to plug in the api_url
  pm_api_url = var.api_url
  # References our secrets.tfvars file to plug in our token_id
  pm_api_token_id = var.token_id
  # References our secrets.tfvars to plug in our token_secret
  pm_api_token_secret = var.token_secret
  # Default to `true` unless you have TLS working within your pve setup
  pm_tls_insecure = true
}

# Creates a proxmox_vm_qemu entity named blog_demo_test
resource "proxmox_vm_qemu" "k3s-node" {
  count = var.node_count

  name = "k3s-${count.index}"
  target_node = "${var.proxmox_host}${count.index + 1}"
  vmid = count.index + 300

  # References our vars.tf file to plug in our template name
  clone = var.template_name
  # Creates a full clone, rather than linked clone
  # https://pve.proxmox.com/wiki/VM_Templates_and_Clones
  full_clone  = "true"

  # VM Settings. `agent = 1` enables qemu-guest-agent
  agent = 1
  os_type = "cloud-init"
  cores = 4
  sockets = 1
  cpu = "host"
  memory = 6144
  scsihw = "virtio-scsi-pci"
  bios = "ovmf"
  onboot = true
  machine = "q35"
  qemu_os = "l26"
  searchdomain = "home.007337.xyz"

  ciuser = "ansible"
  cloudinit_cdrom_storage = var.storage
  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgq7HJ804vAIZASgucY+3sImXqgwCOo4/126vTnrf2+WFtjx3MOosIDfIJDFKkChN7BlUxfj47JAXeoToTAam9pDcGpiO4e4Sd3gu7SPYKsA9AfGmZGSHDm4DTwVws/qwUyBg41UWX8bAIqRt5+6vkMXA9sdpLwh7pCBMv3m73mGEx7rYriYcmJzbw+52NMKv7il7hnrksLSVcJEz2PS0rstKHLRD8xRZuK25Ox0ZTTj4D8+Oon8EA6uYQmN3adK0I2BJMisvuJxRfIhvW4tEMfz7z+Pqls8peluCdOtoZSVkKTS5zvNLyMnn8SAxkRCMUF/pb6xkF1Q5yX+IWvwD4LSv7gm+uGL6iM72cVBZ5ZgqHtZBZ82alfymIFG+Cg+mVmgaG2ggymTa8geJPrnzviHdmQDxLvf04ifDf54xBa61+/EVC69SN4Z4/iNXbU6NsloJOBDePuWcLKC/wtmUtpWbgIDD+iMOdGJhxw0Lh6zxbk/ZDJuBrGUcIWgGWRtc= root@ansibleSemaphore
EOF
  ipconfig0 = "ip=192.168.1.13${count.index}/24,gw=192.168.1.1,"
  nameserver = "192.168.1.100"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = 32
          storage = var.storage # Name of storage local to the host you are spinning the VM up on
          emulatessd = true
        }
      }
      scsi1 {
        disk {
          size       = 128
          storage = var.storage # Name of storage local to the host you are spinning the VM up on
          emulatessd = true
        }
      }
    }
  }

  network {
    model = "virtio"
    bridge = var.nic_name
    firewall = false
  }

  network {
    model = "virtio"
    bridge = var.nic_name
  }
}
resource "proxmox_vm_qemu" "fileserver" {
  name = "fileserver"
  target_node = "${var.proxmox_host}1"
  vmid = 200

  # References our vars.tf file to plug in our template name
  clone = var.template_name
  # Creates a full clone, rather than linked clone
  # https://pve.proxmox.com/wiki/VM_Templates_and_Clones
  full_clone  = "true"

  # VM Settings. `agent = 1` enables qemu-guest-agent
  agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4000
  scsihw = "virtio-scsi-pci"
  bios = "ovmf"
  onboot = true
  machine = "q35"
  qemu_os = "l26"
  searchdomain = "home.007337.xyz"

  ciuser = "ansible"
  cloudinit_cdrom_storage = var.fileserver-storage
  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgq7HJ804vAIZASgucY+3sImXqgwCOo4/126vTnrf2+WFtjx3MOosIDfIJDFKkChN7BlUxfj47JAXeoToTAam9pDcGpiO4e4Sd3gu7SPYKsA9AfGmZGSHDm4DTwVws/qwUyBg41UWX8bAIqRt5+6vkMXA9sdpLwh7pCBMv3m73mGEx7rYriYcmJzbw+52NMKv7il7hnrksLSVcJEz2PS0rstKHLRD8xRZuK25Ox0ZTTj4D8+Oon8EA6uYQmN3adK0I2BJMisvuJxRfIhvW4tEMfz7z+Pqls8peluCdOtoZSVkKTS5zvNLyMnn8SAxkRCMUF/pb6xkF1Q5yX+IWvwD4LSv7gm+uGL6iM72cVBZ5ZgqHtZBZ82alfymIFG+Cg+mVmgaG2ggymTa8geJPrnzviHdmQDxLvf04ifDf54xBa61+/EVC69SN4Z4/iNXbU6NsloJOBDePuWcLKC/wtmUtpWbgIDD+iMOdGJhxw0Lh6zxbk/ZDJuBrGUcIWgGWRtc= root@ansibleSemaphore
EOF
  ipconfig0 = "ip=192.168.1.89/24,gw=192.168.1.1,"
  nameserver = "192.168.1.100"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = 32
          storage = var.fileserver-storage # Name of storage local to the host you are spinning the VM up on
          emulatessd = true
        }
      }
      scsi1 {
        disk {
          size       = 1024
          storage = var.fileserver-storage # Name of storage local to the host you are spinning the VM up on
          emulatessd = true
        }
      }
    }
  }

  network {
    model = "virtio"
    bridge = var.nic_name
    firewall = false
  }
}