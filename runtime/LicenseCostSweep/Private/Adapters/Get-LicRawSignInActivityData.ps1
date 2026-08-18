function Get-LicRawSignInActivityData {
    <#
        .SYNOPSIS
        Collects the raw sign-in activity data for one tenant.

        .DESCRIPTION
        Not implemented yet. This will become the real Graph-backed sign-in activity
        collection path.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    throw [System.NotImplementedException]::new('Get-LicRawSignInActivityData is not implemented yet.')
}
