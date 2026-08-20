resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]

  service_endpoints = each.value.service_endpoints

  private_endpoint_network_policies = "Enabled"

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "nsg-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

resource "azurerm_network_security_rule" "deny_vnet_inbound" {
  for_each = var.subnets

  name                        = "deny-vnet-inbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.key].name

  priority                   = 4000
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "custom" {
  for_each = {
    for pair in flatten([
      for subnet, rules in var.nsg_rules : [
        for rule in rules : {
          key    = "${subnet}-${rule.name}"
          subnet = subnet
          rule   = rule
        }
      ]
    ]) : pair.key => pair
  }

  name                        = each.value.rule.name
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name

  priority                   = each.value.rule.priority
  direction                  = each.value.rule.direction
  access                     = each.value.rule.access
  protocol                   = each.value.rule.protocol
  source_port_range          = each.value.rule.source_port_range
  destination_port_range     = each.value.rule.destination_port_range
  source_address_prefix      = each.value.rule.source_address_prefix
  destination_address_prefix = each.value.rule.destination_address_prefix
}
