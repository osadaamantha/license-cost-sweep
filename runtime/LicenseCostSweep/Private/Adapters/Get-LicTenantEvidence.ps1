function Get-LicTenantEvidence {
    <#
        .SYNOPSIS
        Collects and normalizes one tenant's licence-audit evidence for the
        analysis/orchestration layer.

        .DESCRIPTION
        Not implemented yet. This is where the real Graph/Exchange collection path will
        land once the shared-app scopes and workbook-backed tenant context are wired in.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [datetime]$AsOfUtc,

        [Parameter(Mandatory)]
        [string]$RunId
    )

    throw [System.NotImplementedException]::new('Get-LicTenantEvidence is not implemented yet.')
}
