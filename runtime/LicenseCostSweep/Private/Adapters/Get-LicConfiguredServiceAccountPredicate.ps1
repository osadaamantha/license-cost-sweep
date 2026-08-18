function Get-LicConfiguredServiceAccountPredicate {
    <#
        .SYNOPSIS
        Builds an exact-UPN service-account predicate from tenant config.
    #>
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [hashtable]$TenantContext
    )

    if ($null -eq $TenantContext -or -not $TenantContext.ContainsKey('ServiceAccountUpns')) {
        return $null
    }

    $configuredUpns = @($TenantContext.ServiceAccountUpns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($configuredUpns.Count -eq 0) {
        return $null
    }

    $upnSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($configuredUpn in $configuredUpns) {
        [void]$upnSet.Add([string]$configuredUpn)
    }

    {
        param($UserContext)

        $candidateUpn = if ($UserContext -is [hashtable]) {
            [string]$UserContext['UserPrincipalName']
        }
        else {
            [string]$UserContext.UserPrincipalName
        }

        if ([string]::IsNullOrWhiteSpace($candidateUpn)) {
            return $false
        }

        $upnSet.Contains($candidateUpn)
    }.GetNewClosure()
}
