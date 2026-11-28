# Module 1 Evidence

## Pre-deployment configuration baseline

The five `20261122T173201964084Z-*.json` files contain resource
configuration snapshots captured on November 22, 2026.

Scope: production and nonproduction seed resources. The Platform
subscription is not included.

The file labeled `owner-tag` maps to control C-01.

Expected configuration findings:
- C-01: One resource group missing the Owner tag.
- C-02: Two storage accounts with public-network access enabled.
- C-03: One storage account outside southcentralus.
- C-04: One Key Vault with public-network access enabled.
- C-05: One storage account with secure transfer disabled.

These snapshots are not Azure Policy evaluation results and do not
demonstrate enforcement or remediation.

## Post-deployment evidence

Pending:
- Successful GitHub Actions deployment.
- Management-group assignment and subscription inheritance.
- Azure Policy evaluation results for C-01 through C-05.