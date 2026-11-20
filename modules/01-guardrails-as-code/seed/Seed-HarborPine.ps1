#Requires -Version 7.0
<#
.SYNOPSIS
Seeds the Harbor & Pine Cloud Guardrails lab using Azure CLI from PowerShell.
.DESCRIPTION
Up creates empty lab resources with deliberate C-01 through C-05 violations.
Status inventories both lab resource groups. Down deletes the seed groups.
Use the same parameters across runs. Platform is validated and reserved for state.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('Up', 'Status', 'Down')]
    [string]$Action,

    [Parameter(Mandatory)][guid]$TenantId,
    [Parameter(Mandatory)][guid]$PlatformSubscriptionId,
    [Parameter(Mandatory)][guid]$NonProdSubscriptionId,
    [Parameter(Mandatory)][guid]$ProdSubscriptionId,

    [string]$Location = 'southcentralus',
    [string]$OffRegion = 'westeurope',
    [string]$OwnerTag = 'john.hilton',
    [ValidateRange(1, 365)][int]$ExpiryDays = 14,
    [ValidatePattern('^[a-z0-9]{4,6}$')][string]$Suffix
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Get-Command az -ErrorAction Stop | Out-Null

function Invoke-AzureCli {
    param([string[]]$Arguments)

    $output = & az @Arguments --only-show-errors
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed ($LASTEXITCODE) running az $($Arguments[0..1] -join ' '). Review the Azure error above. RequestDisallowedByPolicy indicates an active Deny guardrail."
    }
    $output
}

$subscriptionIds = @($PlatformSubscriptionId, $NonProdSubscriptionId, $ProdSubscriptionId)
if (($subscriptionIds | Select-Object -Unique).Count -ne 3) {
    throw 'Use separate Platform, NonProd, and Prod lab subscriptions.'
}
if ($Location -eq $OffRegion) {
    throw 'Location and OffRegion must differ to demonstrate C-03.'
}

foreach ($subscriptionId in $subscriptionIds) {
    $account = Invoke-AzureCli @('account', 'show', '--subscription', "$subscriptionId", '-o', 'json') |
        ConvertFrom-Json
    if ($account.tenantId -ne "$TenantId" -or $account.id -ne "$subscriptionId" -or $account.state -ne 'Enabled') {
        throw "Subscription $subscriptionId must be enabled and belong to lab tenant $TenantId."
    }
}

if (!$Suffix) {
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes("$TenantId/$NonProdSubscriptionId/$ProdSubscriptionId")
        $Suffix = [BitConverter]::ToString($hash.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant().Substring(0, 6)
    }
    finally {
        $hash.Dispose()
    }
}

$Suffix = $Suffix.ToLowerInvariant()

$expiry = [DateTime]::UtcNow.AddDays($ExpiryDays).ToString('yyyy-MM-dd')
$groups = @(
    @{
        Name = 'rg-hp-grd-seed-scus-01'; Subscription = "$NonProdSubscriptionId"
        Purpose = 'seeded-violation'; Control = 'C-01'; IncludeOwner = $false
        Resources = @(
            @{ Name = "sthpgrdseed01$Suffix"; Type = 'Microsoft.Storage/storageAccounts'; Region = $Location; Network = 'Enabled'; Https = 'false'; Control = 'C-02,C-05' }
            @{ Name = "sthpgrdseed02$Suffix"; Type = 'Microsoft.Storage/storageAccounts'; Region = $OffRegion; Network = 'Disabled'; Https = 'true'; Control = 'C-03' }
            @{ Name = "kv-hp-grd-seed-01-$Suffix"; Type = 'Microsoft.KeyVault/vaults'; Region = $Location; Network = 'Enabled'; Control = 'C-04' }
        )
    }
    @{
        Name = 'rg-hp-grd-prod-scus-01'; Subscription = "$ProdSubscriptionId"
        Purpose = 'platform'; Control = 'none'; IncludeOwner = $true
        Resources = @(
            @{ Name = "sthpgrdprod01$Suffix"; Type = 'Microsoft.Storage/storageAccounts'; Region = $Location; Network = 'Enabled'; Https = 'true'; Control = 'C-02' }
            @{ Name = "sthpgrdref01$Suffix"; Type = 'Microsoft.Storage/storageAccounts'; Region = $Location; Network = 'Disabled'; Https = 'true'; Control = 'none' }
        )
    }
)

function Get-SeedTags {
    param([string]$Purpose, [string]$Control, [bool]$IncludeOwner)

    'Environment=lab', 'Workload=guardrails', 'ManagedBy=manual', "Purpose=$Purpose",
        "Control=$Control", "Expiry=$expiry", "GuardrailsSeed=$Suffix"
    if ($IncludeOwner) { "Owner=$OwnerTag" }
}

# Inspect both groups before changing either one.
$plans = foreach ($group in $groups) {
    $scope = @('--subscription', $group.Subscription)
    $exists = (Invoke-AzureCli (@('group', 'exists', '-n', $group.Name, '-o', 'tsv') + $scope)) -eq 'true'
    $inventory = @()
    if ($exists) {
        $existingGroup = Invoke-AzureCli (@('group', 'show', '-n', $group.Name, '-o', 'json') + $scope) |
            ConvertFrom-Json
        $inventory = @(Invoke-AzureCli (@('resource', 'list', '-g', $group.Name, '-o', 'json') + $scope) |
            ConvertFrom-Json | Where-Object { $_ })
        $ownedGroup = $existingGroup.tags.GuardrailsSeed -eq $Suffix -and
            $existingGroup.tags.Environment -eq 'lab' -and $existingGroup.tags.Workload -eq 'guardrails'
        $unexpected = @($inventory | Where-Object {
            $actual = $_
            !($group.Resources | Where-Object { $_.Name -eq $actual.name -and $_.Type -eq $actual.type })
        })
        if ($Action -ne 'Status' -and (!$ownedGroup -or $unexpected.Count -gt 0)) {
            throw "Group $($group.Name) lacks the matching seed tags or contains resources outside the seed inventory. Review with Status."
        }
    }
    @{ Group = $group; Scope = $scope; Exists = $exists; Inventory = $inventory }
}

if ($Action -eq 'Down' -and !($PSBoundParameters.ContainsKey('Confirm')) -and !$WhatIfPreference) {
    $ConfirmPreference = 'Medium'
}

foreach ($plan in $plans) {
    $group = $plan.Group
    $scope = $plan.Scope
    $target = "$($group.Name) in $($group.Subscription)"

    if ($Action -eq 'Status') {
        Write-Host "$target (exists: $($plan.Exists), seed suffix: $Suffix)"
        $plan.Inventory | Select-Object name, type, location,
            @{Name = 'Control'; Expression = { $_.tags.Control }},
            @{Name = 'Expiry'; Expression = { $_.tags.Expiry }} | Format-Table -AutoSize
        continue
    }
    if ($Action -eq 'Down') {
        if ($plan.Exists -and $PSCmdlet.ShouldProcess($target, 'Delete resource group and its contents')) {
            Invoke-AzureCli (@('group', 'delete', '-n', $group.Name, '--yes') + $scope)
        }
        continue
    }

    if (!$plan.Exists -and $PSCmdlet.ShouldProcess($target, 'Create lab resource group')) {
        $tags = @(Get-SeedTags $group.Purpose $group.Control $group.IncludeOwner)
        Invoke-AzureCli (@('group', 'create', '-n', $group.Name, '-l', $Location, '-o', 'none', '--tags') + $tags + $scope)
    }
    elseif (!$plan.Exists -and !$WhatIfPreference) {
        continue
    }

    foreach ($resource in $group.Resources) {
        if ($resource.Name -in $plan.Inventory.name) {
            Write-Host "Exists: $($resource.Name)"
            continue
        }
        if (!$PSCmdlet.ShouldProcess("$target / $($resource.Name)", 'Create lab resource')) {
            continue
        }
        $purpose = if ($resource.Control -eq 'none') { 'compliant-reference' } else { 'seeded-violation' }
        $tags = @(Get-SeedTags $purpose $resource.Control $true)
        $common = @('-n', $resource.Name, '-g', $group.Name, '-l', $resource.Region,
            '--public-network-access', $resource.Network, '-o', 'none', '--tags') + $tags + $scope

        if ($resource.Type -eq 'Microsoft.Storage/storageAccounts') {
            Invoke-AzureCli (@('storage', 'account', 'create', '--sku', 'Standard_LRS',
                '--kind', 'StorageV2', '--access-tier', 'Cool', '--min-tls-version', 'TLS1_2',
                '--https-only', $resource.Https, '--allow-blob-public-access', 'false',
                '--allow-shared-key-access', 'false') + $common)
        }
        else {
            Invoke-AzureCli (@('keyvault', 'create', '--sku', 'standard', '--retention-days', '7',
                '--enable-rbac-authorization', 'true') + $common)
        }
    }
}
