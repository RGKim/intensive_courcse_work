resource "azurerm_resource_group" "vmss" {
    name 	= "${var.resource_group_name}"
    location = "${var.location}"
    tags     = "${var.tags}"
}

resource "random_string" "fqdn" {
    length  = 6
    special = false
    upper   = false
    number  = false
}

resource "azurerm_virtual_network" "vmss" {
    name                = "vmss-vnet"
    address_space       = ["1.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vmss.name}"
    tags                = "${var.tags}"
}

resource "azurerm_subnet" "vmss1" {
    name                 = "vmss-subnetA"
    resource_group_name  = "${azurerm_resource_group.vmss.name}"
    virtual_network_name = "${azurerm_virtual_network.vmss.name}"
    address_prefix       = "1.0.1.0/24"
}

resource "azurerm_subnet" "vmss2" {
    name                 = "vmss-subnetB"
    resource_group_name  = "${azurerm_resource_group.vmss.name}"
    virtual_network_name = "${azurerm_virtual_network.vmss.name}"
    address_prefix       = "1.0.2.0/24"
}

resource "azurerm_network_interface" "group1_ni"{
   name                = "group1-network-interface"
   location            = "${var.location}"
   resource_group_name = "${azurerm_resource_group.vmss.name}"

   ip_configuration {
       name                          = "group1-network-config"
       subnet_id                     = "${azurerm_subnet.vmss1.id}"
       private_ip_address_allocation = "Dynamic"
   }
}

resource "azurerm_network_interface" "group1_ni2"{
   name                = "group1-network-interface2"
   location            = "${var.location}"
   resource_group_name = "${azurerm_resource_group.vmss.name}"

   ip_configuration {
       name                          = "group1-network-config"
       subnet_id                     = "${azurerm_subnet.vmss2.id}"
       private_ip_address_allocation = "Dynamic"
   }
}
resource "azurerm_public_ip" "vmss" {
    name                = "vmss-public-ip"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vmss.name}"
    allocation_method   = "Static"
    domain_name_label   = "${random_string.fqdn.result}"
    tags                = "${var.tags}"
}

resource "azurerm_lb" "vmss" {
    name                = "vmss-lb"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vmss.name}"

    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = "${azurerm_public_ip.vmss.id}"
    }
    tags = "${var.tags}"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
	resource_group_name            = "${azurerm_resource_group.vmss.name}"
	name                           = "ssh"
	loadbalancer_id                = "${azurerm_lb.vmss.id}"
	protocol                       = "Tcp"
	frontend_port_start            = 50000
	frontend_port_end              = 50119
	backend_port                   = 22
	frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
	resource_group_name = "${azurerm_resource_group.vmss.name}"
	loadbalancer_id     = "${azurerm_lb.vmss.id}"
	name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
    resource_group_name = "${azurerm_resource_group.vmss.name}"
    loadbalancer_id     = "${azurerm_lb.vmss.id}"
    name                = "ssh-running-probe"
    port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "lbnatrule" {
    resource_group_name            = "${azurerm_resource_group.vmss.name}"
    loadbalancer_id                = "${azurerm_lb.vmss.id}"
    name                           = "http"
    protocol                       = "Tcp"
    frontend_port                  = "${var.application_port}"
    backend_port                   = "${var.application_port}"
    backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
    probe_id                       = "${azurerm_lb_probe.vmss.id}"
}

data "azurerm_resource_group" "image" {
    name     = "group1-final"
}

data "azurerm_image" "image" {
    name                = "group1-VM-image-20190801145605"
    resource_group_name = "${data.azurerm_resource_group.image.name}"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
    name                = "vmscaleset"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vmss.name}"
    upgrade_policy_mode = "Manual"
    sku {
        name     = "Standard_DS1_v2"
        tier     = "Standard"
        capacity = 5
    }

    storage_profile_image_reference {
        id = "${data.azurerm_image.image.id}"
    }

    storage_profile_os_disk {
        name              = ""
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_profile_data_disk {
        lun           = 0
        caching       = "ReadWrite"
        create_option = "Empty"
        disk_size_gb  = 10
    }

    os_profile {
        computer_name_prefix = "vmlab"
        admin_username       = "${var.admin_user}"
        admin_password       = "${var.admin_password}"
        custom_data          = "${file("web.conf")}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
    
    network_profile {
        name    = "terraformnetworkprofile"
        primary = true
        ip_configuration {
            name                                   = "IPConfiguration"
            subnet_id                              = "${azurerm_subnet.vmss1.id}"
            load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
            load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lbnatpool.id}"]
            primary                                = true
        }
    }
    tags = "${var.tags}"
}

resource "azurerm_managed_disk" "source" {
    name                 = "group1_db_snaption"
    location             = "${var.location}"
    resource_group_name  = "${azurerm_resource_group.vmss.name}"
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "30"
}

resource "azurerm_managed_disk" "copy" {
    name                 = "group1-db-copy"
    location             = "${var.location}"
    resource_group_name  = "${azurerm_resource_group.vmss.name}"
    storage_account_type = "Standard_LRS"
    create_option        = "Copy"
    source_resource_id   = "/subscriptions/e0fae348-f6c2-45f5-87b7-c41c22782d8f/resourceGroups/group1-final/providers/Microsoft.Compute/snapshots/group1-db-snapshot0801"
    disk_size_gb         = "30"
}

## Workstation machine
resource "azurerm_virtual_machine" "group1-db" {
    name                  = "group1-db"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.vmss.name}"
    vm_size               = "Standard_D2s_v3"
    network_interface_ids = ["${azurerm_network_interface.group1_ni2.id}"]
    
    storage_os_disk {
        name            = "group1_db_snaption"
        os_type         = "Linux"
        managed_disk_id = "${azurerm_managed_disk.source.id}"
        create_option   = "Attach"
    }
}

resource "azurerm_public_ip" "jumpbox" {
 name                = "jumpbox-public-ip"
 location            = "${var.location}"
 resource_group_name = "${azurerm_resource_group.vmss.name}"
 allocation_method   = "Static"
 domain_name_label   = "${random_string.fqdn.result}-ssh"
 tags                = "${var.tags}"
}

resource "azurerm_network_interface" "jumpbox" {
 name                = "jumpbox-nic"
 location            = "${var.location}"
 resource_group_name = "${azurerm_resource_group.vmss.name}"

 ip_configuration {
   name                          = "IPConfiguration"
   subnet_id                     = "${azurerm_subnet.vmss1.id}"
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
 }

 tags = "${var.tags}"
}

resource "azurerm_virtual_machine" "jumpbox" {
 name                  = "jumpbox"
 location              = "${var.location}"
 resource_group_name   = "${azurerm_resource_group.vmss.name}"
 network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
 vm_size               = "Standard_DS1_v2"

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_os_disk {
   name              = "jumpbox-osdisk"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 os_profile {
   computer_name  = "jumpbox"
   admin_username = "${var.admin_user}"
   admin_password = "${var.admin_password}"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 tags = "${var.tags}"
}

