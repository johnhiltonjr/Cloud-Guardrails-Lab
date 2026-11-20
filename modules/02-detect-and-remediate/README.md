# Module 2 — Detect and Remediate Misconfigurations

**Week 3**

**Proves:** you can find misconfigurations in an existing estate, fix them with the right pattern, and show the result as a number. Architect roles ask about remediation, not just prevention.

## Design

Close the scenario's existing findings using four remediation patterns, one example each:

| Pattern | Lab example | Why this pattern |
|---|---|---|
| IaC source fix | Change the Terraform for the public storage account; re-apply | Resource is managed by IaC; fixing it in the portal would drift |
| Policy remediation task | A `Modify` policy that inherits the `Owner` tag from the resource group; run a remediation task | Safe, idempotent, non-breaking fix at scale |
| Deny for new resources | C-02 at Deny (from Module 1) | Stops recurrence while existing resources are fixed |
| Time-bound exemption | Exempt one resource from C-04 with `expires_on` and a documented reason | A justified exception, not a silent workaround |

## Tasks

- [ ] Record the **before** state: initiative compliance percentage, NonCompliant resource count by guardrail, and Defender for Cloud secure score (foundational CSPM is free).
- [ ] Add the `Modify` tag-inheritance policy to the initiative; give the assignment a system-assigned managed identity with only the role the policy definition requires (check its `roleDefinitionIds`).
- [ ] Create and run a remediation task:

  ```bash
  az policy remediation create --name rem-c01-owner-tag-<yyyymmdd> \
    --management-group mg-hp-guardrails-lab \
    --policy-assignment <assignment-id> \
    --definition-reference-id <reference-id-in-initiative>
  ```

- [ ] Fix the storage account at the source (Terraform), not in the portal.
- [ ] Create one exemption in Terraform (`azurerm_resource_policy_exemption`) with category `Waiver`, a description, and `expires_on` about 30 days out.
- [ ] Record the **after** state with the same measures.

- [ ] Write `compliance-record.md` from the [compliance record template](../../docs/templates/compliance-record-template.md).
- [ ] Write the five-line exception rule in `docs/standards/exception-rule.md`.

**Done when:** `compliance-record.md` has real before and after numbers for every control.

## Evidence to commit (`evidence/`)

- Before and after compliance summaries (exported JSON or screenshots)
- Remediation task result
- Exemption definition showing expiry
- A one-paragraph explanation of why each misconfiguration got the pattern it did

## At 200 subscriptions

Who owns remediation, the platform team or workload teams? How do you prevent remediation tasks from breaking production? How do exemptions expire without someone remembering? Write a five-line exception rule for Harbor & Pine: who requests, who approves, maximum duration, compensating controls, and what happens at expiry.

## Teardown

Destroy seeded resources. Remove the exemption. Keep the initiative if you want it for the demo.
