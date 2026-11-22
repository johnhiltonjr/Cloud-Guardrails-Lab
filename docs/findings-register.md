# Harbor & Pine Insurance — Azure Current State

**Module 1 · Before remediation · November 22, 2026**

The baseline covers two Azure subscriptions, two resource groups, and five resources. South Central US (`southcentralus`) is the only approved region for the evaluated subscriptions. The sandbox subscription is outside this evidence capture.

```mermaid
flowchart TB
    subgraph sub_prod["sub-hp-lab-prod-01"]
        subgraph rg_prod["rg-hp-grd-prod-scus-01 · Owner tag present"]
            storage_prod["Storage · sthpgrdprod018edeb9 · South Central US · F-03 · Public network access enabled"]
            storage_ref["Storage · sthpgrdref018edeb9 · South Central US · Public network access disabled · HTTPS only"]
        end
    end

    subgraph sub_nonprod["sub-hp-lab-nonprod-01"]
        subgraph rg_seed["rg-hp-grd-seed-scus-01 · F-02 · Owner tag missing"]
            storage_seed_01["Storage · sthpgrdseed018edeb9 · South Central US · F-01 · HTTPS-only enforcement disabled · F-04 · Public network access enabled"]
            storage_seed_02["Storage · sthpgrdseed028edeb9 · F-06 · East US is outside the approved region"]
            vault_seed["Key Vault · kv-hp-grd-seed-01-8edeb9 · South Central US · F-05 · Public network access enabled"]
        end
    end

    classDef finding fill:#fff1e8,stroke:#b45309,color:#431407
    class storage_prod,storage_seed_01,storage_seed_02,vault_seed finding
```

Nested boxes show Azure scope. A finding appears at the level where it was observed. F-02 applies to the nonprod resource group, and F-06 applies to the East US storage account inside it.

See the [findings register](findings-register.md) for control mappings, baseline results, and closure criteria.
