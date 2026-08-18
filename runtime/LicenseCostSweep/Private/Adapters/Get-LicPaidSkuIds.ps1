function Get-LicPaidSkuIds {
    <#
        .SYNOPSIS
        Resolves the SKU ids that count as paid licences for the target tenant.

        .DESCRIPTION
        Conservative by design: this function never guesses from SKU names. It reads
        the tenant's subscribed SKU catalogue, then intersects it with an explicit
        allowlist from LIC_PAID_SKU_IDS. If no authoritative allowlist is configured,
        it returns an empty array so the caller can degrade paid-licence evidence to
        Unknown rather than silently misclassifying free or bundled SKUs as paid.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $configuredPaidSkuIds = @(
        [string]$env:LIC_PAID_SKU_IDS -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($configuredPaidSkuIds.Count -eq 0) {
        Write-AuditLog -Level Warning -Message 'Paid SKU allowlist is not configured; paid-licence evidence will degrade to Unknown' -Data @{
            tenantId = $TenantId
        }
        return @()
    }

    $subscribedSkus = @(
        Get-LicRawSubscribedSkuData -TenantId $TenantId |
            ForEach-Object { [string]($_.skuId) } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    @($configuredPaidSkuIds | Where-Object { $_ -in $subscribedSkus })
}
