environment   = "dev"
location      = "westeurope"
location_code = "euw1"

storage_replication_type = "LRS"

storage_containers = {
  artifacts = {}
}

#
# AKS 
#
aks_enabled = false

aks_node_count = 1
aks_node_size  = "Standard_B2s"

aks_authorized_ip_ranges = null

aks_private_cluster        = false
aks_local_account_disabled = true
aks_network_policy         = "calico"
aks_upgrade_channel        = "patch"

aks_admin_group_object_ids = []
