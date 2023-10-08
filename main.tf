# Create Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "KS-AKS-RG"
  location = var.location
}

# Create Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "KS-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [ azurerm_resource_group.rg ]
}

# Create Azure Subnets
resource "azurerm_subnet" "private" {
  count                = 2
  name                 = "private-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index + 1}.0/24"]

  depends_on = [ azurerm_resource_group.rg, azurerm_virtual_network.vnet ]
}

resource "azurerm_subnet" "public" {
  count                = 2
  name                 = "public-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index + 3}.0/24"]

  depends_on = [ azurerm_resource_group.rg, azurerm_virtual_network.vnet ]
}

# Create Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.AKSCluster
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.private[0].id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
  }

  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin     = "kubenet"  # whenever we use the kubenet plugin, there won't be any Public IP addresses associated with it
    service_cidr       = "10.2.0.0/16"
    dns_service_ip     = "10.2.0.10"
    
    # Uncomment the line below if you're using Azure CNI
    # network_policy = "azure"
  }

  tags = {
    Environment = "Dev"  
  }

  depends_on = [ azurerm_resource_group.rg, azurerm_virtual_network.vnet, azurerm_subnet.private ]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-cluster-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow necessary AKS traffic
resource "azurerm_network_security_rule" "aks_default_rules" {
  count                        = length(var.aks_nsg_rules)
  name                         = var.aks_nsg_rules[count.index].name
  priority                     = var.aks_nsg_rules[count.index].priority
  direction                    = var.aks_nsg_rules[count.index].direction
  access                       = var.aks_nsg_rules[count.index].access
  protocol                     = var.aks_nsg_rules[count.index].protocol
  source_port_range            = var.aks_nsg_rules[count.index].source_port_range
  destination_port_range       = var.aks_nsg_rules[count.index].destination_port_range
  source_address_prefix        = var.aks_nsg_rules[count.index].source_address_prefix
  destination_address_prefix   = var.aks_nsg_rules[count.index].destination_address_prefix
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.aks_nsg.name

  depends_on = [
    azurerm_network_security_group.aks_nsg
  ]
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.private[0].id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id

  depends_on = [
    azurerm_network_security_group.aks_nsg,
    azurerm_subnet.private
  ]
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}