terraform {
  backend "azurerm" {
    resource_group_name = "stgacnt"
    storage_account_name = "stgacnt011"
    container_name = "container1"
    key = "terraform.container1"
    access_key = "YaBSyEZkLWa/IVKl0Td7rrRuXeFgKcIhuF8nxNtiSox3Otyq6zrKovFh+896VF45jL96c/hmoL+T+AStry8Asg=="
    
  }
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "3.51.0"
    }
  }
}
provider "azurerm" {
    features {
      
    }
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}
resource "azurerm_resource_group" "azrglabel011" {
    name = "azrg79"
    location = "East US"
    tags = {
      "name" = "azure resource group"
    }
  
}

resource "azurerm_virtual_network" "azvnetlabel01" {
    name = "azrgvnet01"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location
    address_space = [ "10.60.0.0/16" ]
  
}
resource "azurerm_subnet" "azwebsubnetlabel1" {
    name = "websubnet01"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    virtual_network_name = azurerm_virtual_network.azvnetlabel01.name
    address_prefixes = [ "10.60.1.0/24" ]
  
}

resource "azurerm_public_ip" "azwebpublicip01" {
  count = var.vm_count
  name = "${var.vm_name_pfx}-${count.index}-web"
  resource_group_name = azurerm_resource_group.azrglabel011.name
  location = azurerm_resource_group.azrglabel011.location
  allocation_method = "Static"

  depends_on = [
    azurerm_subnet.azwebsubnetlabel1
  ]

  tags = {
    "name" = "webpublicip"
  }

}
resource "azurerm_network_interface" "azwebniclabel01" {
    count = var.vm_count
    name = "${var.vm_name_pfx}-${count.index}-nic"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location

    ip_configuration {
      name = "webnicipconfig"
      subnet_id = azurerm_subnet.azwebsubnetlabel1.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.azwebpublicip01[count.index].id
    }

    depends_on = [
      azurerm_public_ip.azwebpublicip01
    ]
    tags = {
      "name" = "webservernic"
    }
  
}
resource "azurerm_linux_virtual_machine" "azwebvmlabel07" {
    count = var.vm_count
    name = "${var.vm_name_pfx}-${count.index}-web"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location
    size = "Standard_F2"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    disable_password_authentication = false
    network_interface_ids = [ azurerm_network_interface.azwebniclabel01[count.index].id, ]

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"

    }

    source_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "16.04-LTS"
      version = "Latest"
      
    }

    depends_on = [
      azurerm_network_interface.azwebniclabel01
    ]
    tags = {
      "name" = "weblinuxvm"
    }

}
resource "null_resource" "azurermnullweb1" {
  count = var.vm_count
  
  triggers = {
    vm_id = azurerm_linux_virtual_machine.azwebvmlabel07[count.index].id

  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install nginx -y",
    
    ]
    connection {
      type        = "ssh"
      user        = "adminuser"
      password    = "Password1234!"
      host        = azurerm_public_ip.azwebpublicip01[count.index].ip_address
      
    }
  }
    

}
resource "azurerm_network_security_group" "webnsg01" {
  name                = "webnsg01"
  location            = azurerm_resource_group.azrglabel011.location
  resource_group_name = azurerm_resource_group.azrglabel011.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    
  }
}
resource "azurerm_subnet" "azappsubnetlabel1" {
    name = "appsubnet01"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    virtual_network_name = azurerm_virtual_network.azvnetlabel01.name
    address_prefixes = [ "10.60.2.0/24" ]
}

resource "azurerm_public_ip" "azapppublicip01" {
  count = var.vm_count
  name = "${var.vm_name_pfx}-${count.index}-app"
  resource_group_name = azurerm_resource_group.azrglabel011.name
  location = azurerm_resource_group.azrglabel011.location
  allocation_method = "Static"

  depends_on = [
    azurerm_subnet.azappsubnetlabel1
  ]

  tags = {
    "name" = "apppublicip"
  }

}
resource "azurerm_network_interface" "azappniclabel01" {
    count = var.vm_count 
    name = "${var.vm_name_pfx}-${count.index}-nic1"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location

    ip_configuration {
      name = "appnicipconfig"
      subnet_id = azurerm_subnet.azappsubnetlabel1.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.azapppublicip01[count.index].id
    }

    depends_on = [
      azurerm_public_ip.azapppublicip01
    ]
    tags = {
      "name" = "appservernic"
    }
  
}
resource "azurerm_linux_virtual_machine" "azappvmlabel07" {
    count = var.vm_count
    name = "${var.vm_name_pfx}-${count.index}-app"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location
    size = "Standard_F2"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    disable_password_authentication = false
    network_interface_ids = [ azurerm_network_interface.azappniclabel01[count.index].id, ]

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"

    }

    source_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "16.04-LTS"
      version = "Latest"
      
    }

    depends_on = [
      azurerm_network_interface.azappniclabel01
    ]
    tags = {
      "name" = "applinuxvm"
    }

}
resource "null_resource" "azurermnullapp1" {
  count = var.vm_count

  triggers = {
    vm_id = azurerm_linux_virtual_machine.azappvmlabel07[count.index].id

  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install openjdk-8-jdk -y"
    
    ]
    connection {
      type        = "ssh"
      user        = "adminuser"
      password    = "Password1234!"
      host        = azurerm_public_ip.azapppublicip01[count.index].ip_address
      
    }
  }  
  
}
resource "azurerm_network_security_group" "appnsg02" {
  name                = "appnsg02"
  location            = azurerm_resource_group.azrglabel011.location
  resource_group_name = azurerm_resource_group.azrglabel011.name

  security_rule {
    name                       = "test123"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    
  }
}
resource "azurerm_subnet" "azdbsubnetlabel1" {
    name = "dbsubnet01"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    virtual_network_name = azurerm_virtual_network.azvnetlabel01.name
    address_prefixes = [ "10.60.3.0/24" ]
  
}

resource "azurerm_public_ip" "azdbpublicip01" {
  count = var.vm_count
  name = "${var.vm_name_pfx}-${count.index}-db"
  resource_group_name = azurerm_resource_group.azrglabel011.name
  location = azurerm_resource_group.azrglabel011.location
  allocation_method = "Static"

  depends_on = [
    azurerm_subnet.azdbsubnetlabel1
  ]

  tags = {
    "name" = "dbpublicip"
  }

}
resource "azurerm_network_interface" "azdbniclabel01" {
    count = var.vm_count
    name = "${var.vm_name_pfx}-${count.index}-nic2"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location

    ip_configuration {
      name = "dbnicipconfig"
      subnet_id = azurerm_subnet.azdbsubnetlabel1.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.azdbpublicip01[count.index].id
    }

    depends_on = [
      azurerm_public_ip.azdbpublicip01
    ]
    tags = {
      "name" = "dbservernic"
    }
   
  
}
resource "azurerm_network_interface_security_group_association" "nisg01" { 
  count = var.vm_count
  network_interface_id = azurerm_network_interface.azdbniclabel01[count.index].id
  network_security_group_id = azurerm_network_security_group.dbnsg.id
  
}
resource "azurerm_linux_virtual_machine" "azdbvmlabel07" {
    count = var.vm_count
    name = "${var.vm_name_pfx}-${count.index}-db"
    resource_group_name = azurerm_resource_group.azrglabel011.name
    location = azurerm_resource_group.azrglabel011.location
    size = "Standard_F2"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    disable_password_authentication = false
    network_interface_ids = [ azurerm_network_interface.azdbniclabel01[count.index].id, ]

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"

    }

    source_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "18.04-LTS"
      version = "Latest"
      
    }

    depends_on = [
      azurerm_network_interface.azdbniclabel01
    ]
    tags = {
      "name" = "dblinuxvm"
    }

}

resource "null_resource" "azurerm_null_db1" {
  count = var.vm_count
  
  triggers = {
    vm_id = azurerm_linux_virtual_machine.azdbvmlabel07[count.index].id

  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install mysql-server -y"
      
    
    ]
    connection {
      type = "ssh"
      user = "adminuser"
      password = "Password1234!"
      host = azurerm_public_ip.azdbpublicip01[count.index].ip_address
      timeout = "2m"
     
    }

  }
    

}
resource "azurerm_network_security_group" "dbnsg" {
  name = "dbnsg1"
  resource_group_name = azurerm_resource_group.azrglabel011.name
  location = azurerm_resource_group.azrglabel011.location

  security_rule {
    name                       = "test123"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    
  
  } 
  
  
}


