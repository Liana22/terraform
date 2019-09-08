 resource "azurerm_subnet" "subnet" {
  name  = "default"
  address_prefix = "10.0.0.0/16"
   resource_group_name = "${var.resource_group}"
   virtual_network_name = "${var.vnet_name}"/*"${azurerm_virtual_network.vnet.name}"*/
   network_security_group_id = "${module.network-security-group.network_security_group_id}"
 }

provider "azurerm" {
  version = "~> 1.0.1"
}

module "network-security-group" {
    source                     = "Azure/network-security-group/azurerm"
    resource_group_name        = "nsg-resource-group"
    location                   = "westeurope"
    security_group_name        = "nsg"
    
      # predefined_rules           = [
      #   {
      #     name                   = "SSH"
      #     priority               = "500"
      #     source_address_prefix  = ["10.0.3.0/24"]
      #     source_port_range       = "80"
      #   }
      # ]
    # custom_rules               = [
    #    {
    #      name                   = "myhttp"
    #      priority               = "200"
    #      direction              = "Inbound"
    #      access                 = "Allow"
    #      protocol               = "tcp"
    #      destination_port_range = "8080"
    #      description            = "description-myhttp"
    #    }
    #  ]
}

module "virtual_network" {    
  source = "./modules/virtual_network"
}

module "loadbalancer" {
    source = "Azure/loadbalancer/azurerm"
    type    =   "public"
    "lb_port" {
        HTTP = ["80", "Tcp", "80"]
    }
    frontend_name   =   "${var.resource_group}-frontend"
    prefix        =   "terraform-test"
    resource_group_name = "${var.resource_group_name}"
    location            = "${var.location}"
    public_ip_address_allocation    =   "static"
}

module "VirtualMachine" {
    source = "./modules/virtual_machines"
    nsg_id = "${module.network-security-group.network_security_group_id}"
    subnet_id = "${azurerm_subnet.subnet.id}"
    resource_group = "${var.resource_group}"
    location            = "${var.location}"
    nb_instances         =   3
    update_domain_count     =   3
    fault_domain_count      =   3
    availability_set_name   =   "TerraformAS"
    host_names      =   ["host0", "host1", "host2"]
    private_ip_addresses      =   ["10.0.1.0", "10.0.2.0", "10.0.3.0"]
    backend_address_pools_ids         = ["${module.loadbalancer.azurerm_lb_backend_address_pool_id}"]
    
    ssh_key = "${var.ssh_key}"
    # "${file("var.ssh_key")}"
    #  "${file("~/ssh/idrsa.pub")}"
    # ".Roksoliana/ssh/idrsa.pub"
        
}