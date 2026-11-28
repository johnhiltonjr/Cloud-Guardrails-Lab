# Read the existing lab management group.
data "azurerm_management_group" "lab" {
  name = var.management_group_name
}

# Microsoft built-in policy IDs.
locals {

  # C-02: Storage accounts should disable public network access.
  storage_public_network_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"

  # C-03: Allowed locations.
  allowed_locations_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  # C-04: Azure Key Vault should disable public network access.
  key_vault_public_network_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/405c5871-3e91-4644-8a63-58e19d68ff5b"

  # C-05: Require secure transfer for storage accounts.
  require_secure_transfer_for_storage_accounts_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
}

# C-01: Resource Groups require an Owner tag.
resource "azurerm_policy_definition" "owner_tag" {
  name                = "hp-resource-group-owner-tag"
  display_name        = "Harbor and Pine resource groups require an Owner tag"
  description         = "Checks whether resource groups contain the required Owner tag."
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = data.azurerm_management_group.lab.id

  parameters = jsonencode({
    tagName = {
      type         = "String"
      defaultValue = "Owner"
    }

    effect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
      ]
    }

    then = {
      effect = "[parameters('effect')]"
    }
  })
}

# Security Baseline Initiative
resource "azurerm_management_group_policy_set_definition" "baseline" {
  name                = "hp-security-baseline"
  display_name        = "Harbor and Pine Security Baseline"
  description         = "Module 1 security guardrails for the Azure lab."
  policy_type         = "Custom"
  management_group_id = data.azurerm_management_group.lab.id

  parameters = jsonencode({

    storagePublicNetworkEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"

      metadata = {
        displayName = "Storage public network access effect"
        description = "Enforcement effect for control C-02."
      }
    }

    secureTransferEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"

      metadata = {
        displayName = "Secure transfer effect"
        description = "Enforcement effect for control C-05."
      }
    }
    keyVaultPublicNetworkEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"

      metadata = {
        displayName = "Key Vault Public Network Access Effect"
        description = "Enforcement effect for control C-04."
      }
    }
    ownerTagEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"

      metadata = {
        displayName = "Owner Tag Effect"
        description = "Enforcement effect for control C-01."
      }
    }

    allowedLocationsEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
      metadata = {
        displayName = "Allowed Locations Effect"
        description = "Enforcement effect for control C-03."
      }

    }
  })

  # C-01 Resource Groups require Owner tag.
  policy_definition_reference {
    reference_id         = "C-01"
    policy_definition_id = azurerm_policy_definition.owner_tag.id

    parameter_values = jsonencode({
      tagName = {
        value = "Owner"
      }

      effect = {
        value = "[parameters('ownerTagEffect')]"
      }
    })
  }

  # C-02 Storage Public Network Access
  policy_definition_reference {
    reference_id         = "C-02"
    policy_definition_id = local.storage_public_network_policy_id

    parameter_values = jsonencode({
      effect = {
        value = "[parameters('storagePublicNetworkEffect')]"
      }
    })
  }

  # C-03 Allowed Locations
  policy_definition_reference {
    reference_id         = "C-03"
    policy_definition_id = local.allowed_locations_policy_id

    parameter_values = jsonencode({
      listOfAllowedLocations = {
        value = ["southcentralus"]
      }

      effect = {
        value = "[parameters('allowedLocationsEffect')]"
      }
    })
  }

  # C-04 Key Vault Public Network Access
  policy_definition_reference {
    reference_id         = "C-04"
    policy_definition_id = local.key_vault_public_network_policy_id

    parameter_values = jsonencode({
      effect = {
        value = "[parameters('keyVaultPublicNetworkEffect')]"
      }
    })
  }

  # C-05 Require Secure Transfer
  policy_definition_reference {
    reference_id         = "C-05"
    policy_definition_id = local.require_secure_transfer_for_storage_accounts_id

    parameter_values = jsonencode({
      effect = {
        value = "[parameters('secureTransferEffect')]"
      }
    })
  }
}

# Assign Initiative
resource "azurerm_management_group_policy_assignment" "baseline" {
  name                 = "hp-baseline"
  display_name         = "Harbor and Pine Security Baseline"
  management_group_id  = data.azurerm_management_group.lab.id
  policy_definition_id = azurerm_management_group_policy_set_definition.baseline.id

  parameters = jsonencode({
    storagePublicNetworkEffect = {
      value = var.storage_public_network_effect
    }

    secureTransferEffect = {
      value = "Audit"
    }
    keyVaultPublicNetworkEffect = {
      value = "Audit"
    }
    ownerTagEffect = {
      value = "Audit"
    }
    allowedLocationsEffect = {
      value = "Audit"
    }
  })

  non_compliance_message {
    content                        = "C-01: Resource groups must have an Owner tag."
    policy_definition_reference_id = "C-01"
  }

  non_compliance_message {
    content                        = "C-02: Storage accounts must disable public network access."
    policy_definition_reference_id = "C-02"
  }

  non_compliance_message {
    content                        = "C-03: Resources must be deployed only in southcentralus."
    policy_definition_reference_id = "C-03"
  }

  non_compliance_message {
    content                        = "C-04: Key Vaults must disable public network access."
    policy_definition_reference_id = "C-04"
  }

  non_compliance_message {
    content                        = "C-05: Secure transfer for storage accounts must be enabled."
    policy_definition_reference_id = "C-05"
  }
}