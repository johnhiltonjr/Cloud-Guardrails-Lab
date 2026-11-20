# Module 5 — New Workload and SaaS Onboarding Standard, and Packaging

**Week 6**

**Proves:** you can guide other teams through secure implementation, the "guiding cross-functional teams" part of architect roles. It answers the scenario's request R-1 (control C-07): Claims wants a new SaaS intake tool.

## Part A — the standard

Write `docs/standards/onboarding-security-standard.md`, **one page**, in your own words, from how you actually review apps. Suggested structure:

1. **Scope:** new Azure workloads and new SaaS applications.
2. **Tiering:** what data the app touches decides the review depth (for example: public, internal, confidential, restricted).
3. **Required controls by tier:** SSO through Entra ID (SAML/OIDC), MFA via Conditional Access, SCIM or a defined deprovisioning path, admin-consent review of API permissions, logging available to the security team, vendor assurance (SOC 2 or equivalent), data residency, offboarding and data return.
4. **Outcomes:** approve, approve with conditions, or reject, and who decides.
5. **Exceptions:** route to a time-bound exception with a named risk owner and compensating controls (reuse the rule from Module 2).
6. **For Azure workloads:** landing in the right management group means Module 1's guardrails apply automatically; the review covers only what the guardrails can't.

Keep it to one page. A standard nobody reads is not a standard.

## Part B — executive memo and final evidence pass

- [ ] Write `docs/executive-memo.md` from the [executive memo template](../../docs/templates/executive-memo-template.md). One page, real numbers from Module 2, one decision you need from leadership.
- [ ] Final pass on the control catalog in `docs/scenario.md`: every control links to its evidence.
- [ ] Fill in every module's "At 200 subscriptions" section.
- [ ] Final pass on the root README: check every link, add the before/after numbers from Module 2.
- [ ] Redact any tenant, subscription, or account IDs across `evidence/`.
- [ ] Close the loop in `docs/scenario.md`: for each finding, link the evidence that closes it.

**Done when:** a stranger can open the repo, understand it in five minutes, and click through to evidence for every claim.
