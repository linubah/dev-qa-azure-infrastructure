output "id" {
  description = "AKS cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "API server FQDN. Private FQDN when the cluster is private."
  value       = var.private_cluster_enabled ? azurerm_kubernetes_cluster.this.private_fqdn : azurerm_kubernetes_cluster.this.fqdn
}

output "node_resource_group" {
  description = "Auto-generated resource group holding cluster node resources."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "identity_principal_id" {
  description = "Control plane system-assigned identity principal ID."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  description = "Kubelet identity object ID - grant this AcrPull on your registry."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kube_config_raw" {
  description = "Raw kubeconfig. Empty when local accounts are disabled."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
