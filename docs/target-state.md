# Harbor & Pine Insurance — Azure Target State

## Week 1 governance target

The Week 1 deliverable is a deployed Audit baseline with compliance
evidence. Audit does not remediate the seeded resources. The resource
target and finding-closure table below describe subsequent remediation.

```mermaid
flowchart TB
    subgraph github["GitHub Actions"]
        pr["Pull request"]
        checks["Credential-free checks and Rego tests"]
        plan["Trusted main run: Terraform plan and Conftest"]
        approval["Protected lab environment approval"]
        apply["Apply the same checked saved plan"]

        pr --> checks
        checks --> merge["Reviewed merge and push to main"]
merge --> plan
        plan --> approval
        approval --> apply
    end

    plan -->|"OIDC"| reader["hp-guardrails-plan"]
    apply -->|"OIDC"| deployer["hp-guardrails-deploy"]

    reader -->|"Read configuration"| mg
    reader -->|"State access and locking"| state["Terraform state container"]
    deployer -->|"State access"| state
    deployer -->|"Manage policies"| baseline["hp-baseline assignment of hp-security-baseline"]

    subgraph azure["Azure lab hierarchy — verify subscription placement"]
        mg["mg-hp-guardrails-lab"]
        prod["sub-hp-lab-prod-01"]
        nonprod["sub-hp-lab-nonprod-01"]
        platform["sub-hp-lab-platform-01"]

        mg --> prod
        mg --> nonprod
        mg --> platform
    end

    baseline -->|"Assigned at"| mg
    platform -->|"Hosts"| state
```

The diagram summarizes the intended flow. PR checks run without Azure
credentials. Azure-connected planning runs after a trusted push to main;
deployment uses the protected lab environment and a separate identity.

The initiative contains one custom C-01 definition and four built-ins.
Each control has an independent effect parameter. All five begin in Audit;
C-02 progresses to Deny in Week 2 after validation and approval.

The planning identity has Reader access to the lab management group,
with separate backend permissions for state access and locking.
The deployment identity has policy-management permissions at lab scope
and separate backend access.

### Future AWS integration

QuoteFast's AWS account remains outside the Azure Policy assignment.
AWS OIDC trust and AWS-native guardrails are planned for the AWS module;
Azure Policy does not enforce controls in that account.

## Subsequent resource remediation target


**Week 1 Audit baseline and subsequent remediation target — deployment pending**

The target covers the production and non-production subscriptions evaluated in the November 22 baseline. South Central US (`southcentralus`) is the only approved Azure region for this scope. Each resource group has an `Owner` tag. All four target storage accounts require HTTPS and disable public network access. The Key Vault also disables public network access.

[Current-state diagram](current-state.md) · [Findings register](findings-register.md) · [Control catalog](scenario.md)

```mermaid
flowchart TB
    subgraph sub_prod["sub-hp-lab-prod-01"]
        subgraph rg_prod["rg-hp-grd-prod-scus-01 · Owner tag present"]
            storage_prod["Storage · sthpgrdprod018edeb9"]
            storage_ref["Storage · sthpgrdref018edeb9"]
        end
    end

    subgraph sub_nonprod["sub-hp-lab-nonprod-01"]
        subgraph rg_seed["rg-hp-grd-seed-scus-01 · Owner tag present"]
            storage_seed_01["Storage · sthpgrdseed018edeb9"]
            storage_seed_02["Storage · South Central US replacement for sthpgrdseed028edeb9"]
            vault_seed["Key Vault · kv-hp-grd-seed-01-8edeb9"]
        end
    end
```

The boxes show Azure scope. Every resource shown is intended to run in South Central US. The replacement storage account name will be chosen during implementation.

## Finding closure

| Finding | Control | Target change | Closure evidence |
| --- | --- | --- | --- |
| F-01 | C-05 | Require HTTPS on `sthpgrdseed018edeb9`. | Retest clients and capture `enableHttpsTrafficOnly = true`. |
| F-02 | C-01 | Tag `rg-hp-grd-seed-scus-01` with its accountable owner. | Capture the nonprod group with the `Owner` tag present. |
| F-03 | C-02 | Disable public network access on `sthpgrdprod018edeb9`. | Validate production workload access over the approved private path and capture `publicNetworkAccess = Disabled`. |
| F-04 | C-02 | Disable public network access on `sthpgrdseed018edeb9`. | Validate dependent access and capture `publicNetworkAccess = Disabled`. |
| F-05 | C-04 | Disable public network access on `kv-hp-grd-seed-01-8edeb9`. | Validate dependent workload access over the approved private path and capture `publicNetworkAccess = Disabled`. |
| F-06 | C-03 | Replace the East US storage deployment with a South Central US account. | Verify any required data and clients after cutover. Recapture inventory after retiring the East US deployment and confirm all five in-scope resources are in `southcentralus`. |

## Rollout and verification

Prepare private connectivity and DNS for workloads that need access before disabling public endpoints. Test the changes in nonprod first, then verify production dependencies and application access during the production rollout. Retain the original baseline and capture new evidence after remediation.

For the five-resource target shown above, the expected post-remediation results are C-01 **2/2**, C-02 **4/4**, C-03 **5/5**, C-04 **1/1**, and C-05 **4/4**. These are planned outcomes pending the post-remediation check.
