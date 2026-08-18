function Get-LicPaidSkuIds {
    <#
        .SYNOPSIS
        Resolves the SKU ids that count as paid licences for the target tenant.

        .DESCRIPTION
        Not implemented yet. The future production path will derive this from the
        tenant's subscribed SKU catalogue rather than guessing from SKU names.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    throw [System.NotImplementedException]::new('Get-LicPaidSkuIds is not implemented yet.')
}
