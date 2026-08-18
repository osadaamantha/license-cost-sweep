function Get-LicRawSubscribedSkuData {
    <#
        .SYNOPSIS
        Retry-wrapped Graph read of the tenant's subscribed SKU catalogue.

        .DESCRIPTION
        This is a raw collector only. It deliberately does not guess which SKUs are
        paid versus free/trial/bundled; that classification belongs in
        Get-LicPaidSkuIds once backed by an authoritative allowlist or other confirmed
        business rule.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $uri = '/v1.0/subscribedSkus'
    $result = Invoke-WithRetry -OperationName 'Get-LicRawSubscribedSkuData' -ScriptBlock {
        Invoke-MgGraphRequest -Method GET -Uri $uri
    }

    @($result.value)
}
