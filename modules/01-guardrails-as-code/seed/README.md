# Seed — Harbor & Pine's Brownfield Estate

> **Intentionally non-compliant.** Everything here exists to violate the guardrails on purpose. It's created with the Azure CLI, not Terraform, to simulate resources built by hand outside infrastructure as code. Module 2 discovers, imports and remediates them.

## What it creates

| Resource | Subscription | Violates | Why it's built this way |
|---|---|---|---|
| `rg-hp-grd-seed-scus-01` | nonprod | C-01 | No `Owner` tag |
| `sthpgrdseed01<sfx>` | nonprod | C-02, C-05 | Public network access on, HTTPS-only off |
| `sthpgrdseed02<sfx>` | nonprod | C-03 | In West Europe; otherwise compliant, so it isolates one violation |
| `kv-hp-grd-seed-01-<sfx>` | nonprod | C-04 | Public network access on |
| `rg-hp-grd-prod-scus-01` | prod | — | Properly tagged resource group |
| `sthpgrdprod01<sfx>` | prod | C-02 | "A production app depends on it": the Module 2 exemption story |
| `sthpgrdref01<sfx>` | prod | — | Compliant reference, to show what good looks like |

The platform subscription is left clean. It holds Terraform state.

`<sfx>` is a random 4-character suffix, because storage and Key Vault names must be globally unique. It's saved in `.seed-suffix` so `down` removes exactly what `up` created.

## Cost

Effectively zero while empty: Standard_LRS StorageV2 accounts (Cool tier) and a Standard Key Vault have no fixed monthly charge, only per-GB and per-transaction charges. No VMs, public IPs, Premium SKUs or Defender plans. Every resource carries an `Expiry` tag 14 days out.

## Safety

The seeds break policy rules, but expose nothing:

- No data is ever written to them.
- Anonymous blob access is off on every storage account.
- Shared-key (account key) access is off, so there are no keys to leak.
- The script stops if you're signed in to any tenant other than `EXPECTED_TENANT_ID`.

## Usage

```bash
cp seed.env.example seed.env      # fill in your lab tenant and three subscription IDs
chmod +x seed.sh
./seed.sh up                      # create the estate
./seed.sh status                  # list what's there, with Purpose / Control / Expiry tags
./seed.sh down                    # delete it all and purge the soft-deleted Key Vault
```

Set `ASSUME_YES=true` to skip the confirmation prompts.

## Order matters

Run `up` **before** any guardrail is set to Deny. Once C-02 is enforced in nonprod, the seed itself will fail with `RequestDisallowedByPolicy`. That's evidence the guardrail works, but it means re-seeding later needs a time-boxed exemption for the seed resource group.

## Requirements

- Azure CLI, signed in with `az login --tenant <lab-tenant-id>`
- Contributor (or Owner) on the nonprod and prod subscriptions
- Bash: Linux, macOS, WSL or Git Bash
