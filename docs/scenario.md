# Lab Scenario — Harbor & Pine Insurance

*Harbor & Pine Insurance is fictional. Any resemblance to a real company is coincidental.*

## The company

- Regional property and casualty insurer, about 1,200 employees.
- Microsoft shop: Microsoft 365, Entra ID, and **three Azure subscriptions** (production, non-production, sandbox), built by different teams over time with no shared standards.
- Just **acquired QuoteFast**, a small insurtech startup whose quoting app runs in **one AWS account**.
- Small platform team: two cloud engineers. Anything that isn't automated won't happen.

## What triggered the work

An internal audit reported four findings, and the business made one request:

| # | Finding or request | Risk |
|---|---|---|
| F-1 | A storage account holding policyholder documents allows public network access | Data exposure, regulatory reporting |
| F-2 | The deployment pipeline signs in with a client secret that hasn't been rotated in two years | Credential theft, unauthorized change |
| F-3 | Resource groups have no consistent owner tag; nobody can say who owns a third of the resources | Slow incident response, orphaned spend |
| F-4 | Test resources were deployed outside approved US regions | Data residency, policyholder contract terms |
| R-1 | Claims wants to adopt a new SaaS claims-intake tool next quarter | Unreviewed third-party access to claims data |

## Your role

You've just joined as **Cloud Security Architect**. The CISO asks you to close the audit findings, stop them from recurring, bring the QuoteFast AWS account up to the same baseline, and give the business a repeatable way to onboard new SaaS safely.

## Constraints

- **Don't break production.** Policyholder portals and claims systems can't go down for a security rollout.
- **Automate or it won't last.** Two engineers can't hand-check three subscriptions plus an AWS account.
- **Minimal budget.** Use built-in Azure and AWS capabilities; no new tools to buy.

## Control catalog

| Control | Requirement | Closes | Module |
|---|---|---|---|
| C-01 | Every resource group has an `Owner` tag | F-3 | 1, 2 |
| C-02 | Storage accounts disable public network access | F-1 | 1, 2, 4 |
| C-03 | Resources deploy only to approved US regions | F-4 | 1 |
| C-04 | Key Vaults disable public network access | F-1 (same class of exposure) | 1, 2 |
| C-05 | Storage requires secure transfer (HTTPS only) | F-1 | 1, 4 |
| C-06 | Deployment pipelines use no stored secrets; each identity is scoped to what it deploys | F-2 | 3, 4 |
| C-07 | New SaaS and workloads pass a security review scaled to the data they touch | R-1 | 5 |

## How you'll know it worked

- All seven controls are implemented, with evidence.
- Compliance for C-01 to C-05 shows a measured before and after.
- An insecure change is blocked in CI before it reaches Azure or AWS.
- Zero stored deployment secrets remain.
- The SaaS onboarding standard exists and fits on one page.
