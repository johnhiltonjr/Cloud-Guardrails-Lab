# Harbor & Pine brownfield seed

The seed script creates an intentionally non-compliant Azure lab estate. It uses Azure CLI to simulate resources created manually outside Terraform. Module 1 uses the estate to establish an Azure Policy compliance baseline. Module 2 discovers, imports, and remediates the resources.

## What it creates

| Resource | Lab subscription | Control | Configuration |
|---|---|---|---|
| `rg-hp-grd-seed-scus-01` | NonProd | C-01 | Resource group without an `Owner` tag |
| `sthpgrdseed01<sfx>` | NonProd | C-02, C-05 | Public network access enabled and HTTPS-only disabled |
| `sthpgrdseed02<sfx>` | NonProd | C-03 | Storage account in West Europe with public network access disabled and HTTPS-only enabled |
| `kv-hp-grd-seed-01-<sfx>` | NonProd | C-04 | Key Vault with public network access enabled |
| `rg-hp-grd-prod-scus-01` | Prod | — | Resource group with the required tags |
| `sthpgrdprod01<sfx>` | Prod | C-02 | Public network access enabled to model a legacy application dependency for the Module 2 exemption exercise |
| `sthpgrdref01<sfx>` | Prod | — | Compliant storage reference with public network access disabled and HTTPS-only enabled |

The script verifies the Platform subscription and reserves it for Terraform state. By default, it derives a stable six-character suffix from the lab tenant and the NonProd and Prod subscription IDs. Use the same IDs on each run. If you supply `-Suffix` when creating the estate, reuse it for `Status` and `Down`.

## Requirements

- PowerShell 7 (`pwsh`) and Azure CLI (`az`) installed in the same environment.
- Three distinct, enabled Azure subscriptions in your lab tenant.
- Contributor or equivalent permissions on the NonProd and Prod lab subscriptions, plus access to the Platform subscription for verification.
- `Seed-HarborPine.ps1` in this directory.

## Run from Bash

From `modules/01-guardrails-as-code/seed`, verify both commands are available:

```bash
command -v pwsh
command -v az
```

Replace all four placeholders with your lab IDs and sign in:

```bash
lab_args=(
  -TenantId 'YOUR-LAB-TENANT-ID'
  -PlatformSubscriptionId 'YOUR-PLATFORM-SUBSCRIPTION-ID'
  -NonProdSubscriptionId 'YOUR-NONPROD-SUBSCRIPTION-ID'
  -ProdSubscriptionId 'YOUR-PROD-SUBSCRIPTION-ID'
)

az login --tenant "${lab_args[1]}"
```

Preview the resources and target subscriptions, then create and inventory the estate:

```bash
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Up "${lab_args[@]}" -WhatIf
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Up "${lab_args[@]}"
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Status "${lab_args[@]}"
```

If you open a new terminal, define `lab_args` again before running the script.

## Policy assignment order

1. Run `Up` before assigning or enabling Deny controls at the seed scopes.
2. Assign the initiative with the applicable controls in audit mode, trigger a compliance scan, and capture the Module 1 baseline.
3. Verify C-01, C-03, C-04, and C-05 each have one expected finding, and C-02 has two. Use the compliant storage account as the reference.
4. Move to Deny when the lab calls for enforcement testing. A `RequestDisallowedByPolicy` response during reseeding means an assigned Deny policy blocked the request. If a later exercise requires reseeding under Deny, use a time-limited exemption scoped to the affected lab resources or seed group.

## Lab boundaries and cost

The script checks that each target subscription belongs to the specified lab tenant. Use dedicated lab subscriptions and keep the seeded resources empty. Some resources deliberately allow public network access. Every storage account disables anonymous blob access and Shared Key authorization.

The estate uses Standard_LRS StorageV2 accounts in the Cool tier and a Standard Key Vault. Costs should be low while the resources are empty and idle. Storage, transactions, vault operations, or separately enabled services can incur charges. The `Expiry` tag defaults to 14 days and is a cleanup reminder.

## Teardown

When the lab is complete, preview the deletion and then run it:

```bash
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Down "${lab_args[@]}" -WhatIf
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Down "${lab_args[@]}"
pwsh -NoProfile -File ./Seed-HarborPine.ps1 Status "${lab_args[@]}"
```

`Down` prompts before deleting each seed resource group. It checks the seed tags and refuses to proceed if either group contains resources outside the expected inventory. The Key Vault enters its seven-day soft-delete retention period. After teardown, `Status` should show both resource groups as absent.