# Module 1 — Guardrails as Code and the CI Gate

**Weeks 1–2**

**Proves:** you can establish organization-wide guardrails and stop insecure infrastructure before it deploys. Closes scenario findings F-1, F-3 and F-4 going forward.

## Design

- One custom **initiative** (policy set) built from Microsoft built-in definitions, assigned at a lab **management group** — not a subscription — so every subscription under it inherits it.
- One initiative parameter, `effect`, defaulting to `Audit`. Moving to `Deny` is a one-line, reviewed change — progressive enforcement, in code, so production isn't broken on day one.
- A **two-stage CI gate**: static scan with no cloud credentials on every pull request, then a Terraform plan evaluated by OPA/Conftest.

## Guardrails (from the [scenario control catalog](../../docs/scenario.md#control-catalog))

| Control | Built-in policy (search by display name) | Starting effect |
|---|---|---|
| C-01 | Require a tag on resource groups (`Owner`) | Audit |
| C-02 | Storage accounts should disable public network access | Audit → Deny in week 2 |
| C-03 | Allowed locations | Audit |
| C-04 | Azure Key Vault should disable public network access | Audit |
| C-05 | Secure transfer to storage accounts should be enabled | Audit |

Find each definition ID with:

```bash
az policy definition list --query "[?displayName=='Allowed locations'].{name:name, effect:policyRule.then.effect}" -o table
```

Confirm each definition supports an `effect` parameter with `Audit` and `Deny` before wiring it to the initiative parameter. Some built-ins use a fixed effect or different allowed values.

## Week 1 tasks — Azure Policy in Terraform

- [ ] Draw the **current-state diagram** (`docs/architecture/current-state.md`): three subscriptions, the QuoteFast AWS account, the pipeline with its secret, each finding marked where it lives.
- [ ] Draw the **target-state diagram** (`docs/architecture/target-state.md`): management groups, where the initiative is assigned, the CI gate, OIDC to Azure and AWS.
- [ ] Write **ADR-001: assignment scope and enforcement** using the [ADR template](../../docs/templates/adr-template.md): management group vs. subscription, Audit first vs. Deny immediately.
- [ ] Create `terraform/` with `versions.tf`, `providers.tf`, `backend.tf` (remote state in a storage account you create first, with public access off), `variables.tf`, `main.tf`, `outputs.tf`.
- [ ] Create a lab management group (for example `mg-hp-guardrails-lab`) and move one sandbox subscription under it.
- [ ] `azurerm_policy_set_definition` at management-group scope, referencing the five built-ins, with an initiative-level `effect` parameter passed to each.
- [ ] `azurerm_management_group_policy_assignment` with a clear `non_compliance_message` per guardrail.
- [ ] Seed violations in a sandbox resource group: a storage account with public network access enabled, a Key Vault with public access, an untagged resource group.
- [ ] Trigger and capture compliance:

  ```bash
  az policy state trigger-scan --resource-group <rg>
  az policy state summarize --management-group mg-hp-guardrails-lab
  ```

**Done when:** the initiative is assigned at the management group in Audit and compliance shows each seeded violation as NonCompliant.

## Week 2 tasks — the CI gate

- [ ] Write Rego rules in `policy/` for C-02 and C-05 against the Terraform plan JSON, with unit tests that pass under `conftest verify`.
- [ ] Wire [`.github/workflows/guardrails.yml`](../../.github/workflows/guardrails.yml): Checkov static scan, then plan + Conftest.
- [ ] Open PR #1 with an insecure storage account in Terraform. **It must fail**, with the failing rule named in the log.
- [ ] Open PR #2 with the compliant version. It must pass.
- [ ] Flip C-02 to `Deny` through a reviewed PR, then show that a portal or CLI attempt to create a public storage account returns `RequestDisallowedByPolicy`.

**Done when:** both PR runs and the Deny test are linked in `evidence/`.

## Design decision to document (an interview question)

Running `terraform plan` needs Azure read access, but PR jobs should not hold a deployment identity (see the Module 3 threat model, TM-04). Choose and record one approach:

1. **Separate plan identity:** a Reader-only federated identity bound to the `pull_request` subject, distinct from the deployer.
2. **Static-only on PRs:** Checkov on HCL in PRs; plan + Conftest only in the protected `lab` environment before apply.

Record it as **ADR-002** in `docs/decisions/ADR-002-plan-identity.md` using the [ADR template](../../docs/templates/adr-template.md).

## Evidence to commit (`evidence/`)

- Compliance summary in Audit (seeded violations visible)
- Failing and passing PR run links
- `RequestDisallowedByPolicy` output after the Deny flip
- Conftest output for the insecure plan

## At 200 subscriptions

Answer in this README when done: Harbor & Pine buys two more companies and grows to 200 subscriptions. Where is this initiative assigned in the management-group hierarchy, how do you roll Deny out by cohort, and who approves exemptions?

## Teardown

`terraform destroy` for test resources. Keep the initiative and assignment if Module 2 follows immediately; Module 2 reuses them.
