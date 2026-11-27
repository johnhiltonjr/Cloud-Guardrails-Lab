# HarborPine Azure Environment — Before Remediation

## Scenario architecture before guardrails

This view represents the scenario's starting conditions. The pipeline
secret is a modeled scenario risk, not a claim that a live secret was
found in this repository.

```mermaid
flowchart TB
    pipeline["Existing deployment pipeline"]
    secret["Long-lived Azure credential"]
    pipeline --> secret

    subgraph azure["Harbor and Pine Azure estate"]
        prod["Production subscription"]
        nonprod["Nonproduction subscription"]
        platform["Platform subscription and Terraform state"]
        gap["No consistently assigned security baseline"]
    end

    secret --> prod
    secret --> nonprod
    secret --> platform

    subgraph acquisition["QuoteFast acquisition"]
        aws["AWS account — existing controls require assessment"]
    end
```

| Starting gap | Where it appears |
|---|---|
| Missing Owner tag — C-01 | Nonproduction seed resource group |
| Storage public-network access — C-02 | Production and nonproduction storage |
| Unapproved location — C-03 | East US seed storage account |
| Key Vault public-network access — C-04 | Nonproduction seed vault |
| Secure transfer disabled — C-05 | Nonproduction seed storage |
| Long-lived deployment credential | Scenario pipeline |
| Acquisition governance boundary | QuoteFast AWS account |

The resource diagram below shows the observed Azure seed baseline.
Scenario finding IDs and observed resource finding IDs must be traced
through the findings register rather than assumed to be interchangeable.

## Observed seed resources

```mermaid
flowchart TB
    subgraph sub_prod["sub-hp-lab-prod-01"]
        subgraph rg_prod["rg-hp-grd-prod-scus-01"]
            storage_prod["sthpgrdprod018edeb9 · C-02"]
            storage_ref["sthpgrdref018edeb9 · Reference"]
        end
    end

    subgraph sub_nonprod["sub-hp-lab-nonprod-01"]
        subgraph rg_seed["rg-hp-grd-seed-scus-01"]
            vault_seed["Key Vault · kv-hp-grd-seed-01-8edeb9 · C-04"]
            storage_seed_01["sthpgrdseed018edeb9 · South Central US · C-02, C-05"]
            storage_seed_02["sthpgrdseed028edeb9 · East US · C-03"]
        end
    end

    finding_01["F-01 · C-05 · HTTPS-only enforcement disabled"]
    finding_01 -.-> storage_seed_01
```