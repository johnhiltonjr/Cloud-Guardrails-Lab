# Naming Convention
 
One naming scheme for every resource, identity, file and branch in this repo. Names should tell a reviewer **what it is, whose it is, and why it exists** without opening it.
 
Based on the Microsoft Cloud Adoption Framework abbreviations, adapted for a two-cloud lab.
 
## Building blocks
 
| Token | Meaning | Values |
|---|---|---|
| `<type>` | Resource type abbreviation | See the tables below |
| `<org>` | Organization | `hp` (Harbor & Pine) |
| `<wl>` | Workload | `grd` (guardrails) |
| `<env>` | Environment | `lab` |
| `<region>` | Azure region short code | `scus` (South Central US, default), `cus` (Central US), `eus2` (East US 2) |
| `<nn>` | Instance | `01`, `02`, … |
| `<purpose>` | Why it exists, when the lab needs to tell resources apart | `seed` (seeded violation), `ref` (compliant reference), `tfstate` |
 
**Default pattern:** `<type>-<org>-<wl>-<env>-<region>-<nn>` → `rg-hp-grd-lab-scus-01`
 
Lowercase everywhere. Hyphens as separators, except where a service forbids them.
 
## Azure
 
| Resource | Pattern | Example | Constraints to know |
|---|---|---|---|
| Management group | `mg-<org>-<name>` | `mg-hp-guardrails-lab` | Name is the ID; can't be renamed later |
| Resource group | `rg-<org>-<wl>-<env>-<region>-<nn>` | `rg-hp-grd-lab-scus-01` | |
| Resource group (seeded violations) | `rg-<org>-<wl>-<purpose>-<region>-<nn>` | `rg-hp-grd-seed-scus-01` | Keeps bad resources in one place for teardown |
| Storage account | `st<org><wl><purpose><nn>` | `sthpgrdseed01`, `sthpgrdref01`, `sthpgrdtfstate01` | 3–24 chars, lowercase letters and numbers only, globally unique |
| Key Vault | `kv-<org>-<wl>-<purpose>-<nn>` | `kv-hp-grd-seed-01` | 3–24 chars, globally unique, soft-delete keeps the name reserved after deletion |
| State container | `tfstate` | `tfstate` | |
| Log Analytics workspace (if used) | `log-<org>-<wl>-<env>-<region>-<nn>` | `log-hp-grd-lab-scus-01` | |
 
### Azure Policy
 
| Object | Pattern | Example | Constraints to know |
|---|---|---|---|
| Initiative (policy set) | `init-<org>-<name>` | `init-hp-security-baseline` | Display name: "Harbor & Pine Security Baseline" |
| Custom definition (only if a built-in won't do) | `pol-<org>-<control>-<short>` | `pol-hp-c01-owner-tag` | |
| Assignment | `asg-<org>-<name>` | `asg-hp-baseline` | **24 characters max at management-group scope** |
| Policy reference ID inside the initiative | `<control>-<short>` | `c02-storage-public-access` | Used to target remediation tasks |
| Exemption | `ex-<control>-<resource-short>-<yyyymm>` | `ex-c04-kvseed01-202612` | The date shows when it was granted; `expires_on` holds the expiry |
| Remediation task | `rem-<control>-<short>-<yyyymmdd>` | `rem-c01-owner-tag-20261209` | |
 
### Entra ID (workload identities)
 
| Object | Pattern | Example |
|---|---|---|
| App registration (CI plan identity) | `app-<org>-<wl>-gh-plan` | `app-hp-grd-gh-plan` |
| App registration (CI deploy identity) | `app-<org>-<wl>-gh-deploy` | `app-hp-grd-gh-deploy` |
| Federated credential | `fc-gh-<subject>` | `fc-gh-pull-request`, `fc-gh-env-lab` |
 
## AWS
 
AWS names follow `<org>-<wl>-<env>-<name>`, since many AWS resources don't use type prefixes.
 
| Resource | Pattern | Example | Constraints to know |
|---|---|---|---|
| IAM role (CI deploy) | `<org>-<wl>-github-deploy` | `hp-grd-github-deploy` | |
| IAM policy | `<org>-<wl>-<scope>-policy` | `hp-grd-s3-deploy-policy` | |
| S3 bucket | `<org>-<wl>-<env>-<purpose>-<suffix>` | `hp-grd-lab-ref-7k2m`, `hp-grd-lab-seed-7k2m` | 3–63 chars, lowercase, globally unique: add a short random suffix |
| Budget | `<org>-<wl>-<env>-monthly` | `hp-grd-lab-monthly` | |
 
The IAM OIDC identity provider has a fixed name: `token.actions.githubusercontent.com`.
 
## Tags (Azure and AWS)
 
Every resource gets the first five. Tags carry metadata, not security; access is controlled by RBAC and IAM, never by tags.
 
| Tag | Values | Why |
|---|---|---|
| `Owner` | `john.hilton` | Control C-01 |
| `Environment` | `lab` | |
| `Workload` | `guardrails` | |
| `ManagedBy` | `terraform` or `manual` | Shows what should be fixed in code vs. the portal |
| `Expiry` | `YYYY-MM-DD` | Teardown date; anything past it should be gone |
| `Purpose` | `seeded-violation`, `compliant-reference`, `platform` | Separates deliberate bad resources from real ones |
| `Control` | `C-01` … `C-07` | Which control a test resource exists to exercise |
 
## Terraform
 
| Item | Convention | Example |
|---|---|---|
| Resource labels | `snake_case`, describe the purpose, don't repeat the type | `azurerm_storage_account.seeded_public` (not `storage_account_1`) |
| Variables and outputs | `snake_case` | `policy_effect`, `initiative_id` |
| Files | Standard set | `versions.tf`, `providers.tf`, `backend.tf`, `variables.tf`, `main.tf`, `outputs.tf` |
| State keys | `<wl>/<module>.tfstate` | `grd/m1-guardrails.tfstate` |
 
## Rego (OPA / Conftest)
 
| Item | Convention | Example |
|---|---|---|
| Policy file | `policy/<control>_<short>.rego` | `policy/c02_storage_public_access.rego` |
| Test file | same name + `_test` | `policy/c02_storage_public_access_test.rego` |
| Package | `main` (Conftest default) | `package main` |
| Deny message | starts with the control ID | `"[C-02] storage account sthpgrdseed01 allows public network access"` |
 
## GitHub
 
| Item | Convention | Example |
|---|---|---|
| Branch | `<type>/m<module>-<short>` | `feat/m1-policy-initiative`, `fix/m3-federated-subject`, `docs/m5-exec-memo` |
| Demo branch that must fail the gate | `demo/m<module>-<short>` | `demo/m1-insecure-storage` |
| Pull request title | `[M<module>] <what changed>` | `[M1] Add security baseline initiative in Audit` |
| Label for expected failures | `expected-fail` | |
| Environments | `lab` (Azure), `aws-lab` (AWS) | |
| Workflow file and jobs | `guardrails.yml`; `static-scan`, `plan-policy`, `deploy` | |
| Repository variables | `UPPER_SNAKE_CASE` | `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_PLAN_CLIENT_ID`, `AZURE_DEPLOY_CLIENT_ID`, `AWS_DEPLOY_ROLE_ARN` |
 
These IDs are identifiers, not secrets, so they're stored as **variables**. With OIDC federation there are no secrets to store.
 
## Documents, IDs and evidence
 
| Item | Convention | Example |
|---|---|---|
| Findings, requests | `F-<n>`, `R-<n>` | `F-1`, `R-1` |
| Controls | `C-<nn>` | `C-02` |
| Threats | `TM-<nn>` | `TM-03` |
| Tests | `M<module>-<control>-<check>-<nn>` | `M1-C02-DENY-01`, `M3-C06-TM01-01` |
| ADRs | `docs/decisions/ADR-<nnn>-<kebab-title>.md` | `ADR-001-assignment-scope-and-enforcement.md` |
| Evidence files | `modules/<module>/evidence/<yyyymmdd>-<test-id>-<short>.<ext>` | `20261205-M1-C02-DENY-01-request-disallowed.png` |
 
Before committing evidence, replace tenant, subscription and account IDs with `<redacted-tenant-id>`, `<redacted-subscription-id>` or `<redacted-account-id>`.
 