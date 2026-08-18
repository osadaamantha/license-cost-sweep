function Get-LicTenantRuntimeContext {
    <#
        .SYNOPSIS
        Resolves the auth + config context Invoke-TenantSweep needs for one tenant.

        .DESCRIPTION
        Mirrors the shared multi-tenant app + federated managed identity model already
        proven in mailbox-audit-sweep. This keeps the assumption isolated to one place:
        if the auth design changes later, the public orchestration contract does not.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $allTenantConfig = @(Get-LicenseCostSweepConfiguration)
    $tenantRow = $allTenantConfig | Where-Object { $_.TenantId -eq $TenantId } | Select-Object -First 1
    if (-not $tenantRow) {
        throw "No config-workbook entry found for tenant '$TenantId'"
    }

    $integrationUamiClientId = $env:INTEGRATION_UAMI_CLIENT_ID
    if ([string]::IsNullOrWhiteSpace($integrationUamiClientId)) {
        throw 'INTEGRATION_UAMI_CLIENT_ID is not set -- cannot resolve the federated token identity.'
    }

    @{
        TenantId                = $TenantId
        TenantDomain            = $tenantRow.TenantDomain
        ReportRecipients        = @($tenantRow.ReportRecipients)
        OverlapMap              = @($tenantRow.OverlapMap)
        ServiceAccountUpns      = @($tenantRow.ServiceAccountUpns)
        Notes                   = $tenantRow.Notes
        AppId                   = 'c0b73c04-cb71-4b45-ad2a-83244603b54b'
        IntegrationUamiClientId = $integrationUamiClientId
        Organization            = $TenantId
    }
}
