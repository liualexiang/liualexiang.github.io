# 第一种注释方法
// 第二种注释方法
/*
第三种注释方法
第一种和第二种只针对单行，第三种可以多行注释
*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
// 当前使用az login的credential，所以要看az login登录的是哪个账号
//  environment = "china"
//  subscription_id = "c0fce330-1b6b-4b1e-8b20-ba66b557f0fc"
}

data "azurerm_ssh_public_key" "pub_key" {
    name = "alex"
    resource_group_name = "xiangliu_csa"
}

/*
output "azurerm_ssh_public_key" {
    value = data.azurerm_ssh_public_key.pub_key.public_key
}
*/


resource "azurerm_resource_group" "example_rg" {
  name     = "example-rgname"
  location = "East US 2"
}


resource "azurerm_virtual_network" "testVnet" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example_rg.name
  location            = azurerm_resource_group.example_rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet01" {
    name = "subnet01"
    resource_group_name = azurerm_resource_group.example_rg.name
    virtual_network_name = azurerm_virtual_network.testVnet.name
    address_prefixes = ["10.0.1.0/24"]

}

resource "azurerm_network_security_group" "testnsg" {
    name = "testnsg"
    location = azurerm_resource_group.example_rg.location
    resource_group_name = azurerm_resource_group.example_rg.name

    security_rule {
      name = "testrule_tcp_22"
      priority = 110
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "*"
      source_address_prefix = "*"
      destination_address_prefix = "*"
    }

    tags = {
      createdBy = "tf"
    }
}

resource "azurerm_public_ip" "pubip" {
  count = 2
  name                = "pubip${count.index}"
  resource_group_name = azurerm_resource_group.example_rg.name
  location            = azurerm_resource_group.example_rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}


resource "azurerm_network_interface" "eni01" {

    count = 2
    name = "eni${count.index}"
    resource_group_name = azurerm_resource_group.example_rg.name
    location = azurerm_resource_group.example_rg.location
    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.subnet01.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.pubip[count.index].id
    }

}


resource "azurerm_network_interface_security_group_association" "example" {
  count = 2
  network_interface_id = azurerm_network_interface.eni01[count.index].id
  network_security_group_id = azurerm_network_security_group.testnsg.id
}




resource "azurerm_linux_virtual_machine" "tfvm01" {
    count = 2
    name ="tfvm${count.index}"
    resource_group_name =azurerm_resource_group.example_rg.name
    location = azurerm_resource_group.example_rg.location
    size = "Standard_B2s"
    admin_username = "alex"
    network_interface_ids = [azurerm_network_interface.eni01[count.index].id]

    admin_ssh_key {
        username = "alex"
        public_key = data.azurerm_ssh_public_key.pub_key.public_key
    }

    source_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }
    os_disk {
        caching ="ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    custom_data = base64encode(file("bootstrap_init.sh"))


}

output "azurerm_linux_virtual_machine" {
    value=azurerm_linux_virtual_machine.tfvm01.*.id
}


// https://docs.rackspace.com/blog/create-a-vm-in-azure-by-using-terraform-with-for-loops/