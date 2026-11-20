# Module 3 — Secretless Pipelines, Proven

**Week 4**

**Proves:** you can secure non-human identities, and you test your designs instead of assuming them. Closes scenario finding F-2 (control C-06): replace the two-year-old pipeline secret with federation, then prove the design holds.

## Design

Two federated identities, each with the least access its job needs:

| Identity | Federated subject | Azure role and scope | Used by |
|---|---|---|---|
| `app-hp-grd-gh-plan` | `repo:<owner>/azure-aws-security-guardrails:pull_request` | Reader on `mg-hp-guardrails-lab` | PR plan job (if you chose option 1 in Module 1) |
| `app-hp-grd-gh-deploy` | `repo:<owner>/azure-aws-security-guardrails:environment:lab` | Resource Policy Contributor on `mg-hp-guardrails-lab`; Contributor on the lab resource group only | Deploy job in the protected `lab` environment |

The deployer cannot create role assignments. Identity and RBAC administration stay outside the pipeline.

## Tasks

- [ ] Write `threat-model.md` from the [threat model template](../../docs/templates/threat-model-template.md): data flow (GitHub → Entra ID → Azure) and the five threats in the table below, status **Designed**.
- [ ] Write **ADR-003: federation vs. stored secrets** in `docs/decisions/` using the [ADR template](../../docs/templates/adr-template.md). Include what a compromised approved job can still do.
- [ ] Create both app registrations and federated credentials. Use Terraform's `azuread` provider if your account allows it; otherwise create them once by CLI and document the steps.
- [ ] Create the `lab` GitHub environment with a required reviewer and `main` as the only deployment branch.
- [ ] In the workflow, grant `id-token: write` only to jobs that need it. Pin every third-party action to a full commit SHA.
- [ ] Add a secrets scan (for example gitleaks) to the PR job.
- [ ] Run the threat-model checks and capture the result of each:

| Test | Threat | Action | Expected result |
|---|---|---|---|
| TM-01 | Spoofing | Run a job that requests a token without the `lab` environment | Token exchange fails with a "no matching federated identity record" error |
| TM-02 | Tampering | Show branch protection, environment rules, and SHA-pinned actions | Unapproved change cannot reach the deploy job |
| TM-03 | Elevation of privilege | From the deploy job, attempt one role assignment and one write outside the lab resource group | Both fail with `AuthorizationFailed` |
| TM-04 | Information disclosure | Review run logs and artifacts | No token or credential appears |
| TM-05 | Repudiation | Match one deployment to its commit, run ID, and Azure Activity Log entry | Correlation recorded |

**Done when:** each test row has a result and a link or screenshot.

## Evidence to commit (`evidence/`)

- Federated credential configuration (IDs redacted)
- Failed TM-01 and TM-03 runs
- Activity Log correlation for TM-05
- The secrets-scan result on a clean repo

Then update `threat-model.md`: each threat's result, and the status from **Designed** to **Validated**.

## At 200 subscriptions

How do you manage hundreds of federated credentials? (Consider one identity per workload and environment, and the federated-credential count limit per app.) Who owns them? How do you detect a misused workload identity?

## Teardown

Keep the identities until Module 4 is done; remove role assignments when the lab closes.
