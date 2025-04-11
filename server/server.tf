# Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-minecraft-server-5"
  location = "West US 3"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "minecraft-server-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "minecraft-server-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "minecraft-server-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Security Group Association
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Security Rule - SSH
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Security Rule - Minecraft Server
resource "azurerm_network_security_rule" "allow_minecraft" {
  name                        = "Allow-Minecraft"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25565"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Security Rule - Grafana
resource "azurerm_network_security_rule" "allow_grafana" {
  name                        = "Allow-Grafana"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Public IP Address
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "minecraft-server-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "minecraft-server-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "minecraft-server-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Minecraft Server Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "minecraft-server-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B4als_v2"
  admin_username      = "azureuser"
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Image Reference
  # This is the Ubuntu Server 18.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get upgrade -y > ~/apt.log 2>&1", # Update and upgrade the system
      "mkdir -p /home/azureuser/minecraft-server/ > ~/minecraft-server.log 2>&1", # Create Minecraft Server directory
      "mkdir -p /home/azureuser/server-backend/ | mkdir -p /home/azureuser/server-backend/linux/ > ~/server-backend.log 2>&1", # Create server backend directory
    ]
  }

  # Copy local files to the Virtual Machine
  # Install Docker Script
  provisioner "file" {
    source      = "install_docker.sh"
    destination = "/home/azureuser/server-backend/linux/install_docker.sh"
  }

  # Install Node Exporter Script
  provisioner "file" {
    source      = "install_node_exporter.sh"
    destination = "/home/azureuser/server-backend/linux/install_node_exporter.sh"
  }

  # Docker Compose file
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/azureuser/server-backend/linux/docker-compose.yml"
  }

  # Prometheus configuration file
  provisioner "file" {
    source      = "prometheus.yml"
    destination = "/home/azureuser/server-backend/linux/prometheus.yml"
  }

  # Remove Docker Script
  provisioner "file" {
    source      = "remove_docker.sh"
    destination = "/home/azureuser/server-backend/linux/remove_docker.sh"
  }

  # Reset Docker Compose Script
  provisioner "file" {
    source      = "reset_docker_compose.sh"
    destination = "/home/azureuser/server-backend/linux/reset_docker_compose.sh"
  }

  # Minecraft Server Script
  provisioner "file" {
    source      = "../download_backup.py"
    destination = "/home/azureuser/server-backend/download_backup.py"
  }

  # Requirements file for Python
  provisioner "file" {
    source      = "../requirements.txt"
    destination = "/home/azureuser/server-backend/requirements.txt"
  }

  # Credetentials file for Python
  provisioner "file" {
    source      = "../credentials.json"
    destination = "/home/azureuser/server-backend/credentials.json"
  }

  # Token Pickle file for Python
  provisioner "file" {
    source      = "../token.pickle"
    destination = "/home/azureuser/server-backend/token.pickle"
  }

  # Start Minecraft Server Script
  provisioner "file" {
    source      = "start.sh"
    destination = "/home/azureuser/server-backend/linux/start.sh"
  }

  # Minecraft Server Service File
  provisioner "file" {
    source      = "minecraft-server.service"
    destination = "/home/azureuser/server-backend/linux/minecraft-server.service"
  }

  # Execute the scripts on the VM
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/azureuser/server-backend/linux/install_docker.sh > ~/install_docker.log 2>&1",
      "sudo /home/azureuser/server-backend/linux/install_docker.sh > ~/install_docker.log 2>&1",
      "chmod +x /home/azureuser/server-backend/linux/install_node_exporter.sh > ~/install_node_exporter.log 2>&1",
      "sudo /home/azureuser/server-backend/linux/install_node_exporter.sh > ~/install_node_exporter.log 2>&1",
      "sudo docker compose -f /home/azureuser/server-backend/linux/docker-compose.yml up -d > ~/docker-compose.log 2>&1"
    ]
  }

  # SSH connection to the VM
  # This is used to execute the remote-exec provisioner
  connection {
    type     = "ssh"
    user     = "azureuser"
    password = var.admin_password
    host     = azurerm_public_ip.vm_public_ip.ip_address
  }
}

# Output the public IP address of the VM
output "public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}
