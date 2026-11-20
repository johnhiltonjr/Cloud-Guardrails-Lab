# Compliance Record — Before and After

**Scope:** <management group / subscriptions / AWS account>
**Before measured:** YYYY-MM-DD · **After measured:** YYYY-MM-DD
**Source:** <Azure Policy compliance, Defender for Cloud, AWS Config, CLI command used>

<!-- Real numbers only. If a measure couldn't be taken, say so in the row; never estimate. -->

## Results

| Control | Requirement | Non-compliant before | Non-compliant after | Remediation pattern | Evidence |
|---|---|---:|---:|---|---|
| C-01 | Owner tag on resource groups | | | Policy remediation task (Modify) | <link> |
| C-02 | Storage: no public network access | | | IaC source fix + Deny | <link> |
| C-03 | Approved regions only | | | | <link> |
| C-04 | Key Vault: no public network access | | | Time-bound exemption (1 resource) | <link> |
| C-05 | Storage: secure transfer | | | | <link> |
| **Total** | | | | | |

**Overall initiative compliance:** <before %> → <after %>
**Defender for Cloud secure score (optional):** <before> → <after>

## Why each pattern

<!-- One paragraph. Why did each control get the remediation pattern it did? e.g. "C-02 was fixed in Terraform, not by a remediation task, because the storage account is IaC-managed and a portal fix would drift." -->

## Open items

| Item | Owner | Due | Exception reference |
|---|---|---|---|
| | | | |
