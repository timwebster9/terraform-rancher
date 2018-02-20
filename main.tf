resource "azurerm_resource_group" "test" {
  name     = "buildit-2fa-sales"
  location = "UK South"
}

resource "azurerm_network_security_group" "test" {
  name                = "buildit-2fa-sales-nsg"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "buildit-2fa-sales-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "UK South"
  resource_group_name = "${azurerm_resource_group.test.name}"
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_public_ip" "test" {
    name                         = "buildit-2fa-sales-pubip"
    location                     = "UK South"
    resource_group_name          = "${azurerm_resource_group.test.name}"
    public_ip_address_allocation = "dynamic"
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_subnet" "test" {
  name                 = "buildit-2fa-sales-subnet"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "buildit-2fa-sales-ni"
  location            = "UK South"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "buildit-2fa-sales-ipconfig"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_managed_disk" "small_ssd" {
  name                 = "datadisk_existing"
  location             = "UK South"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "127"
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_managed_disk" "medium_ssd" {
  name                 = "datadisk_existing"
  location             = "UK South"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "511"
  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_virtual_machine" "rancher_server" {
  name                  = "buildit-2fa-sales-vm"
  location              = "UK South"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.small_ssd.name}"
    managed_disk_id = "${azurerm_managed_disk.small_ssd.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.small_ssd.disk_size_gb}"
  }

  os_profile {
    computer_name  = "buildit-01"
    admin_username = "buildit"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/buildit/.ssh/authorized_keys"
        key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMvYVQ2eKoU5o2/zLMYil/KZ3IoTOu2U5K8/c04Punj5yie5nrZ+xecXFsnP5yCY2sBFsOSi4tvJ6q/lXSlz994nt+0zJ4mN0P6eUSKnKZQZJBucdPIvkPdIqb+sCfvqcUnqT9p7pX1HYji+YVUoRni875UFPSRkyuowyra9M7oUx5Eq1sniW1Y6/ZlbJjil7GbmNiTTc94UXRvA+vJb2ZfrXu4MBNlEmEjEjYhANLzJHFgpVELonbfzeSCBPaN3XG3rYdvzMwW2vaIsInrrK/XQDvO1uJMflOx06uVN491Em7oV3cZw6MeHVzDwxcX7unsV97lefUeljt+KpcpBJ/ timw@phobos"
    }
    ssh_keys {
      path = "/home/buildit/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpVUs5xhxLIjLeXQ+9ME/rTz/KRNweVD/tggAqKPSgjpopu2QTSl6HhMLendfQZkewz6Lh6x51qd3iqKalJs9+bLh9+T4GXbI0kAKP9lFRHlKhW1skWiVG/I5OLuLSlyLJarvvBvUxOxA3GGwx91OImCdoWCBRgFkm2lGL8x1v45iVgoG12z2++Cr4Vh1BErf4i2xYXWsZkdnJ02obgZHEsiM2gHxJnpw8UfCr4g7yTZwgz/4HYly8UGIrQlO0DlYUq7GM+DwOaXjPs67vY32Lt5D2sAsX1kAO96T9rKhaZcvzKGsy3s2/f+s2lvDDnhyOo2xcCuenhB9GXCPnebnF chris@crystal"
    }
  }

  tags {
    environment = "sales_test_rancher"
  }
}

resource "azurerm_virtual_machine" "test" {
  name = "buildit-2fa-sales-vm"
  location = "UK South"
  resource_group_name = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }

  storage_os_disk {
    name = "os"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name = "${azurerm_managed_disk.medium_ssd.name}"
    managed_disk_id = "${azurerm_managed_disk.medium_ssd.id}"
    create_option = "Attach"
    lun = 1
    disk_size_gb = "${azurerm_managed_disk.medium_ssd.disk_size_gb}"
  }

  os_profile {
    computer_name = "buildit-01"
    admin_username = "buildit"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/buildit/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMvYVQ2eKoU5o2/zLMYil/KZ3IoTOu2U5K8/c04Punj5yie5nrZ+xecXFsnP5yCY2sBFsOSi4tvJ6q/lXSlz994nt+0zJ4mN0P6eUSKnKZQZJBucdPIvkPdIqb+sCfvqcUnqT9p7pX1HYji+YVUoRni875UFPSRkyuowyra9M7oUx5Eq1sniW1Y6/ZlbJjil7GbmNiTTc94UXRvA+vJb2ZfrXu4MBNlEmEjEjYhANLzJHFgpVELonbfzeSCBPaN3XG3rYdvzMwW2vaIsInrrK/XQDvO1uJMflOx06uVN491Em7oV3cZw6MeHVzDwxcX7unsV97lefUeljt+KpcpBJ/ timw@phobos"
    }
    ssh_keys {
      path = "/home/buildit/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpVUs5xhxLIjLeXQ+9ME/rTz/KRNweVD/tggAqKPSgjpopu2QTSl6HhMLendfQZkewz6Lh6x51qd3iqKalJs9+bLh9+T4GXbI0kAKP9lFRHlKhW1skWiVG/I5OLuLSlyLJarvvBvUxOxA3GGwx91OImCdoWCBRgFkm2lGL8x1v45iVgoG12z2++Cr4Vh1BErf4i2xYXWsZkdnJ02obgZHEsiM2gHxJnpw8UfCr4g7yTZwgz/4HYly8UGIrQlO0DlYUq7GM+DwOaXjPs67vY32Lt5D2sAsX1kAO96T9rKhaZcvzKGsy3s2/f+s2lvDDnhyOo2xcCuenhB9GXCPnebnF chris@crystal"
    }
  }

  tags {
    environment = "sales_test_rancher"
  }
}
