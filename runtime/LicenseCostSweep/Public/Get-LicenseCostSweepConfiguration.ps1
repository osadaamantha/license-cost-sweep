function Get-LicenseCostSweepConfiguration {
    <#
        .SYNOPSIS
        Reads and validates the per-tenant config workbook rows for this run.

        .DESCRIPTION
        Adapter-driven config-reader orchestrator. The adapter supplies raw workbook
        rows; this function validates and normalizes each row through
        ConvertTo-LicTenantConfig, then returns only the enabled tenants for this run.
        -Adapter exists for test/replay injection only -- production call paths never
        pass it.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Adapter
    )

    $adapters = if ($Adapter) { $Adapter } else { Get-LicDefaultAdapterSet }

    if ($null -eq $adapters -or -not $adapters.ContainsKey('GetConfigRows') -or $adapters.GetConfigRows -isnot [scriptblock]) {
        throw "Get-LicenseCostSweepConfiguration requires an adapter set with a GetConfigRows scriptblock."
    }

    Write-AuditLog -Message 'Loading sweep configuration' -Data @{}

    $rows = & $adapters.GetConfigRows
    if ($null -eq $rows) {
        $rows = @()
    }

    $configs = @()
    foreach ($row in @($rows)) {
        $configs += ConvertTo-LicTenantConfig -Row $row
    }

    $enabledConfigs = @($configs | Where-Object { $_.Enabled })

    Write-AuditLog -Message 'Loaded sweep configuration' -Data @{
        totalTenantCount   = @($configs).Count
        enabledTenantCount = @($enabledConfigs).Count
    }

    return $enabledConfigs
}
