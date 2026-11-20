#!/usr/bin/env bash
# =============================================================================
# Harbor & Pine — brownfield seed script (INTENTIONALLY NON-COMPLIANT)
#
# Creates a small "hand-built" estate with deliberate policy violations so the
# guardrails in Module 1 have something to find, and Module 2 has something to
# import and remediate. Created with the Azure CLI on purpose: it simulates
# resources built outside infrastructure as code.
#
# Usage:
#   ./seed.sh up        Create the seeded estate
#   ./seed.sh status    List seeded resources in each subscription
#   ./seed.sh down      Delete everything this script created
#
# Configuration: copy seed.env.example to seed.env and fill in your IDs.
#
# Cost: Standard_LRS StorageV2 accounts with no data and a Standard Key Vault
# with no operations have no fixed monthly charge; you pay only for stored data
# and transactions. No VMs, public IPs, Premium SKUs or Defender plans.
#
# Safety: seeds break policy rules but expose nothing real. No data is stored,
# anonymous blob access is off, and shared-key access is off on every account.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/seed.env"
SUFFIX_FILE="${SCRIPT_DIR}/.seed-suffix"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

: "${EXPECTED_TENANT_ID:?Set EXPECTED_TENANT_ID in seed.env (your LAB tenant, never an employer tenant)}"
: "${PLATFORM_SUBSCRIPTION_ID:?Set PLATFORM_SUBSCRIPTION_ID in seed.env}"
: "${NONPROD_SUBSCRIPTION_ID:?Set NONPROD_SUBSCRIPTION_ID in seed.env}"
: "${PROD_SUBSCRIPTION_ID:?Set PROD_SUBSCRIPTION_ID in seed.env}"

LOCATION="${LOCATION:-southcentralus}"          # approved region
OFF_REGION="${OFF_REGION:-westeurope}"         # deliberately NOT approved (C-03)
OWNER_TAG="${OWNER_TAG:-john.hilton}"
EXPIRY_DAYS="${EXPIRY_DAYS:-14}"

# Resource groups
RG_SEED="rg-hp-grd-seed-scus-01"               # nonprod; NO Owner tag (C-01)
RG_PROD="rg-hp-grd-prod-scus-01"               # prod; properly tagged

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { printf '\033[1;34m[seed]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

expiry_date() {
  # GNU date (Linux, WSL) or BSD date (macOS)
  date -u -d "+${EXPIRY_DAYS} days" +%Y-%m-%d 2>/dev/null \
    || date -u -v+"${EXPIRY_DAYS}"d +%Y-%m-%d
}

# Globally unique names need a short random suffix; reuse it so 'down' finds
# the same resources 'up' created.
suffix() {
  if [[ ! -s "$SUFFIX_FILE" ]]; then
    local chars="abcdefghijklmnopqrstuvwxyz0123456789" out=""
    for _ in 1 2 3 4; do out+="${chars:RANDOM%36:1}"; done
    printf '%s' "$out" >"$SUFFIX_FILE"
  fi
  cat "$SUFFIX_FILE"
}

use_sub() { az account set --subscription "$1" --only-show-errors; }

preflight() {
  command -v az >/dev/null || die "Azure CLI not found."
  az account show --only-show-errors >/dev/null 2>&1 || die "Not signed in. Run: az login --tenant <lab-tenant-id>"

  local tenant
  tenant="$(az account show --query tenantId -o tsv)"
  [[ "$tenant" == "$EXPECTED_TENANT_ID" ]] \
    || die "Signed in to tenant $tenant, expected $EXPECTED_TENANT_ID. Stopping so nothing lands in the wrong tenant."

  for sub in "$PLATFORM_SUBSCRIPTION_ID" "$NONPROD_SUBSCRIPTION_ID" "$PROD_SUBSCRIPTION_ID"; do
    az account show --subscription "$sub" --query id -o tsv --only-show-errors >/dev/null 2>&1 \
      || die "Can't access subscription $sub with the current login."
  done
  log "Tenant and all three subscriptions verified."
}

confirm() {
  local prompt="$1"
  if [[ "${ASSUME_YES:-false}" == "true" ]]; then return 0; fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || die "Cancelled."
}

# Common tags. Owner is added separately so the C-01 seed can leave it out.
base_tags() {
  local purpose="$1" control="$2"
  echo "Environment=lab Workload=guardrails ManagedBy=manual Purpose=${purpose} Control=${control} Expiry=$(expiry_date)"
}

policy_hint() {
  warn "If the error says RequestDisallowedByPolicy, a Deny guardrail is already enforced here."
  warn "That's the guardrail working. Seed before enforcing, or add a time-boxed exemption for the seed resource group."
}

create_storage() {
  # name rg location public_access(Enabled|Disabled) https_only(true|false) tags...
  local name="$1" rg="$2" loc="$3" public="$4" https="$5"; shift 5
  if az storage account show -n "$name" -g "$rg" --only-show-errors >/dev/null 2>&1; then
    log "  exists: $name"
    return 0
  fi
  log "  creating storage account $name ($loc, public=$public, https_only=$https)"
  # shellcheck disable=SC2068
  az storage account create \
    --name "$name" --resource-group "$rg" --location "$loc" \
    --sku Standard_LRS --kind StorageV2 --access-tier Cool \
    --min-tls-version TLS1_2 \
    --public-network-access "$public" \
    --https-only "$https" \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --tags $@ \
    --only-show-errors -o none || { policy_hint; return 1; }
}

create_keyvault() {
  local name="$1" rg="$2"; shift 2
  if az keyvault show -n "$name" --only-show-errors >/dev/null 2>&1; then
    log "  exists: $name"
    return 0
  fi
  log "  creating key vault $name (public network access enabled)"
  # shellcheck disable=SC2068
  az keyvault create \
    --name "$name" --resource-group "$rg" --location "$LOCATION" \
    --sku standard \
    --retention-days 7 \
    --enable-rbac-authorization true \
    --public-network-access Enabled \
    --tags $@ \
    --only-show-errors -o none || { policy_hint; return 1; }
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_up() {
  preflight
  local s; s="$(suffix)"
  confirm "Create the seeded (intentionally non-compliant) estate with suffix '$s'?"

  # --- Platform: nothing seeded. It holds Terraform state and stays clean. ---
  log "Platform subscription: no seeds (reserved for Terraform state)."

  # --- Nonprod: the messy estate --------------------------------------------
  use_sub "$NONPROD_SUBSCRIPTION_ID"
  log "Nonprod subscription: seeding violations in $RG_SEED"

  # C-01: resource group with NO Owner tag
  # shellcheck disable=SC2046
  az group create -n "$RG_SEED" -l "$LOCATION" \
    --tags $(base_tags seeded-violation C-01) --only-show-errors -o none

  # C-02 + C-05: public network access on, HTTPS-only off
  # shellcheck disable=SC2046
  create_storage "sthpgrdseed01${s}" "$RG_SEED" "$LOCATION" Enabled false \
    Owner="$OWNER_TAG" $(base_tags seeded-violation C-02,C-05)

  # C-03: unapproved region. Otherwise compliant, so it isolates one violation.
  # shellcheck disable=SC2046
  create_storage "sthpgrdseed02${s}" "$RG_SEED" "$OFF_REGION" Disabled true \
    Owner="$OWNER_TAG" $(base_tags seeded-violation C-03)

  # C-04: Key Vault with public network access
  # shellcheck disable=SC2046
  create_keyvault "kv-hp-grd-seed-01-${s}" "$RG_SEED" \
    Owner="$OWNER_TAG" $(base_tags seeded-violation C-04)

  # --- Prod: one "an app depends on it" violation + one compliant reference --
  use_sub "$PROD_SUBSCRIPTION_ID"
  log "Prod subscription: seeding $RG_PROD"

  # shellcheck disable=SC2046
  az group create -n "$RG_PROD" -l "$LOCATION" \
    --tags Owner="$OWNER_TAG" $(base_tags platform none) --only-show-errors -o none

  # C-02: the Module 2 exemption story
  # shellcheck disable=SC2046
  create_storage "sthpgrdprod01${s}" "$RG_PROD" "$LOCATION" Enabled true \
    Owner="$OWNER_TAG" $(base_tags seeded-violation C-02)

  # Compliant reference: shows what "good" looks like next to the violations
  # shellcheck disable=SC2046
  create_storage "sthpgrdref01${s}" "$RG_PROD" "$LOCATION" Disabled true \
    Owner="$OWNER_TAG" $(base_tags compliant-reference none)

  log "Done. Expected violations: C-01, C-02 (x2), C-03, C-04, C-05."
  log "Next: assign the initiative, run 'az policy state trigger-scan', and capture the baseline."
}

cmd_status() {
  preflight
  for sub in "$NONPROD_SUBSCRIPTION_ID" "$PROD_SUBSCRIPTION_ID"; do
    use_sub "$sub"
    log "Subscription $(az account show --query name -o tsv):"
    az resource list --query "[?tags.Workload=='guardrails'].{name:name, type:type, location:location, purpose:tags.Purpose, control:tags.Control, expiry:tags.Expiry}" -o table
  done
}

cmd_down() {
  preflight
  confirm "Delete $RG_SEED (nonprod) and $RG_PROD (prod) and everything in them?"
  local s; s="$(suffix)"

  use_sub "$NONPROD_SUBSCRIPTION_ID"
  if az group exists -n "$RG_SEED" | grep -q true; then
    log "Deleting $RG_SEED"
    az group delete -n "$RG_SEED" --yes --only-show-errors
  fi
  # Key Vault is soft-deleted with its resource group; purge to free the name.
  if az keyvault show-deleted -n "kv-hp-grd-seed-01-${s}" --only-show-errors >/dev/null 2>&1; then
    log "Purging soft-deleted key vault kv-hp-grd-seed-01-${s}"
    az keyvault purge -n "kv-hp-grd-seed-01-${s}" --only-show-errors || warn "Purge failed; it will expire on its own after 7 days."
  fi

  use_sub "$PROD_SUBSCRIPTION_ID"
  if az group exists -n "$RG_PROD" | grep -q true; then
    log "Deleting $RG_PROD"
    az group delete -n "$RG_PROD" --yes --only-show-errors
  fi

  rm -f "$SUFFIX_FILE"
  log "Teardown complete. Check Cost Management in a day to confirm nothing is left billing."
}

case "${1:-}" in
  up)     cmd_up ;;
  status) cmd_status ;;
  down)   cmd_down ;;
  *)      echo "Usage: $0 {up|status|down}"; exit 1 ;;
esac
