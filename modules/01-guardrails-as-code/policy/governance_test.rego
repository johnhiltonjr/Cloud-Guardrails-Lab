package main

import rego.v1

test_correct_scope_passes if {
	test_plan := {
		"resource_changes": [{
			"address": "azurerm_management_group_policy_assignment.baseline",
			"change": {
				"after": {
					"management_group_id": approved_scope,
				},
			},
		}],
	}

	results := deny with input as test_plan

	count(results) == 0
}

test_wrong_scope_denied if {
	test_plan := {
		"resource_changes": [{
			"address": "azurerm_management_group_policy_assignment.baseline",
			"change": {
				"after": {
					"management_group_id": "/providers/Microsoft.Management/managementGroups/wrong-group",
				},
			},
		}],
	}

	results := deny with input as test_plan

	"The baseline assignment must target mg-hp-guardrails-lab." in results
}

test_missing_assignment_denied if {
	results := deny with input as {"resource_changes": []}

	"The baseline assignment must exist in the planned configuration." in results
}

test_deleted_assignment_denied if {
	test_plan := {
		"resource_changes": [{
			"address": "azurerm_management_group_policy_assignment.baseline",
			"change": {
				"actions": ["delete"],
				"after": null,
			},
		}],
	}

	results := deny with input as test_plan

	"The baseline assignment must exist in the planned configuration." in results
}
