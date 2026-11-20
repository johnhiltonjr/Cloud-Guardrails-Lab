terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hp-sa-lab-centralus-01"
    storage_account_name = "sthpgrdtfstate01"
    container_name       = "tfstate"
    key                  = "grd/m1-guardrails.tfstate"

    # Keyless authentication
    use_azuread_auth = true
    use_cli          = true
  }
}

