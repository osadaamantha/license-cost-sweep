function Get-LicConfiguredOverlapMap {
    <#
        .SYNOPSIS
        Returns the tenant-scoped overlap rules from parsed config, if any.
    #>
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [hashtable]$TenantContext
    )

    if ($null -eq $TenantContext -or -not $TenantContext.ContainsKey('OverlapMap')) {
        return @()
    }

    @($TenantContext.OverlapMap)
}
