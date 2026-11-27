output "management_group_id" {
  description = "Management group where the baseline is defined and assigned."
  value       = data.azurerm_management_group.lab.id
}

output "initiative_id" {
  description = "Resource ID of the security baseline initiative."
  value       = azurerm_management_group_policy_set_definition.baseline.id
}

output "assignment_id" {
  description = "Resource ID of the baseline assignment."
  value       = azurerm_management_group_policy_assignment.baseline.id
}

output "owner_tag_policy_id" {
  description = "Resource ID of the custom C-01 policy definition."
  value       = azurerm_policy_definition.owner_tag.id
}