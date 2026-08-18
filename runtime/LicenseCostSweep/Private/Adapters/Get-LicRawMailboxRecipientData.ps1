function Get-LicRawMailboxRecipientData {
    <#
        .SYNOPSIS
        Collects the raw recipient/mailbox-type data for one tenant.

        .DESCRIPTION
        Not implemented yet. This will become the real Exchange/Graph-backed recipient
        collection path.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    throw [System.NotImplementedException]::new('Get-LicRawMailboxRecipientData is not implemented yet.')
}
