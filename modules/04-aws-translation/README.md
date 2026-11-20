# Module 4 — Same Guardrails in AWS

**Week 5**

**Proves:** your control thinking transfers across clouds. Dallas architect postings above $160K increasingly ask for Azure *and* AWS. This module gives you a truthful multi-cloud answer without claiming production AWS experience.

## Design

Bring the acquired QuoteFast AWS account up to Harbor & Pine's baseline through the **same CI gate**:

- **C-06, secretless deployment:** GitHub OIDC to a narrowly scoped IAM role.
- **C-02 and C-05 equivalents:** no public S3 buckets, encryption on, TLS-only access.

## Tasks

- [ ] **First:** create an AWS Budget with a $5 alert. Nothing else until it exists.
- [ ] Create the IAM OIDC identity provider for `token.actions.githubusercontent.com`, audience `sts.amazonaws.com`.
- [ ] Create a deploy role (`hp-grd-github-deploy`) whose trust policy requires `token.actions.githubusercontent.com:sub` = `repo:<owner>/azure-aws-security-guardrails:environment:aws-lab`. Grant only the S3 actions the module needs, on buckets with the lab name prefix.
- [ ] In Terraform: an S3 bucket with `aws_s3_bucket_public_access_block` (all four settings true), default encryption, and a bucket policy denying requests where `aws:SecureTransport` is false.
- [ ] Turn on account-level S3 Block Public Access.
- [ ] Add one Rego rule for the S3 public-access block; reuse the same Checkov and Conftest steps from Module 1.
- [ ] Insecure PR (public bucket) must fail the gate; compliant PR deploys through OIDC.
- [ ] In CloudTrail event history, find the `AssumeRoleWithWebIdentity` event for the deploy.

**Done when:** the same gate blocks an insecure AWS plan and the OIDC role deploys a compliant one.

## Deliverable: the Azure ↔ AWS mapping

Fill this in from what you actually built and read. It's the table interviewers want you to talk through.

| Control intent | Azure (Modules 1–3) | AWS (this module) | Key difference |
|---|---|---|---|
| Org-wide preventive guardrail | Azure Policy `Deny` at management group | Service Control Policy at OU (not built here) | |
| Detect misconfiguration | Azure Policy `Audit`, Defender for Cloud | AWS Config rules, Security Hub (not built here) | |
| Pre-deployment check | Checkov + Conftest on Terraform plan | Same | |
| Secretless CI/CD | Entra federated credential | IAM OIDC provider + role trust policy | |
| Scope the deployer | RBAC role at resource group | IAM policy resource ARNs / permission boundary | |
| Audit trail | Activity Log | CloudTrail | |

## At 200 accounts

How would you structure AWS Organizations OUs to mirror Harbor & Pine's management groups as more acquisitions arrive? Where do SCPs replace Azure Policy `Deny`, and where can't they?

## Teardown

`terraform destroy`, empty and delete the bucket, keep the OIDC provider and role only if you'll demo them, and confirm the Billing console shows nothing running.
