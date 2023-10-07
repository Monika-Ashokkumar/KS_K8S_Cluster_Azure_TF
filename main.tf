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
}

# Create Azure Subnets
resource "azurerm_subnet" "private" {
  count                = 2
  name                 = "private-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index + 1}.0/24"]
}

resource "azurerm_subnet" "public" {
  count                = 2
  name                 = "public-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index + 3}.0/24"]
}

# Create Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.AKSCluster
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.private[0].id
  }

  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin     = "kubenet"  # Use "azure" if you're using Azure CNI
    service_cidr       = "10.2.0.0/16"
    dns_service_ip     = "10.2.0.10"
    
    # Uncomment the line below if you're using Azure CNI
    # network_policy = "azure"
  }

  tags = {
    Environment = "Production"  # Just an example, modify tags as per your requirements
  }
}
