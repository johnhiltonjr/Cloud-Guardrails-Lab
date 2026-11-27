package main

import rego.v1

approved_scope := "/providers/Microsoft.Management/managementGroups/mg-hp-guardrails-lab"

deny contains msg if {
	some resource in input.resource_changes

	resource.address == "azurerm_management_group_policy_assignment.baseline"

	resource.change.after.management_group_id != approved_scope

	msg := "The baseline assignment must target mg-hp-guardrails-lab."
}

baseline_assignment_present if {
	some resource in input.resource_changes
	resource.address == "azurerm_management_group_policy_assignment.baseline"
	is_object(resource.change.after)
}

deny contains msg if {
	not baseline_assignment_present
	msg := "The baseline assignment must exist in the planned configuration."
}
