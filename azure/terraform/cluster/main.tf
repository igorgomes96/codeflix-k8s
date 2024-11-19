locals {
  resource_group_name = "aks-fullcycle-rg"
  location            = "East US"
  vnet_address_space  = ["10.240.0.0/12"]
  appgw_subnet_cidr   = "10.255.0.0/24"
  aks_name            = "aks-fullcycle"
  appgw_name          = "gateway"
  node_vm_size        = "Standard_B2s"
  node_count          = 4
}

resource "azurerm_resource_group" "aks_rg" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.254.0.0/16"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-${local.aks_name}"

  default_node_pool {
    name           = "default"
    node_count     = local.node_count
    vm_size        = local.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  sku_tier = "Free"

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  ingress_application_gateway {
    gateway_name = local.appgw_name
    subnet_cidr  = local.appgw_subnet_cidr
  }
}

resource "azurerm_role_assignment" "appgtw_ingress_role_assignment" {
  scope                = azurerm_virtual_network.aks_vnet.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}