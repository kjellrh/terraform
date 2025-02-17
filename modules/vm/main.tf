terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Konfigurer Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Importerer variabler automatisk fra variables.tf og terraform.tfvars

resource "azurerm_resource_group" "resource_group_1" {
  name     = var.ressurs_gruppe_navn
  location = var.lokasjon
}

resource "azurerm_virtual_network" "vnet_1" {
  name                = var.vnet_navn
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_resource_group.resource_group_1.location
  address_space       = var.ip_range
}

resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.resource_group_1.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_network_security_group" "nsg_1" {
  name                = "nsg-1"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_resource_group.resource_group_1.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.nsg_1.id
}


resource "azurerm_public_ip" "public_ip_1" {
  name                = "public-ip-1"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_resource_group.resource_group_1.location
  allocation_method   = "Dynamic"
}


resource "azurerm_network_interface" "nic_1" {
  name                = "nic-1"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_resource_group.resource_group_1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_1.id
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linux-vm"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_resource_group.resource_group_1.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Sofus2017!" 
  disable_password_authentication = false 

  network_interface_ids = [azurerm_network_interface.nic_1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

# Output for å vise offentlig IP etter opprettelse
output "vm_public_ip" {
  value = azurerm_public_ip.public_ip_1.ip_address
}
