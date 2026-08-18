function Get-LicRawUserData {
    <#
        .SYNOPSIS
        Collects the raw user/licence data for one tenant.

        .DESCRIPTION
        Not implemented yet. This will become the real Graph-backed user and licence
        collection path.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    throw [System.NotImplementedException]::new('Get-LicRawUserData is not implemented yet.')
}
