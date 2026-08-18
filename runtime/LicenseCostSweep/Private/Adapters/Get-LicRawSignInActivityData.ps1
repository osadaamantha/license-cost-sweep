function Get-LicRawSignInActivityData {
    <#
        .SYNOPSIS
        Retry-wrapped, paged Graph read of every user's sign-in activity, tagged with a
        signal state.

        .DESCRIPTION
        signInActivity requires Entra ID P1/P2 in the target tenant and the
        AuditLog.Read.All Graph permission. A tenant without P1/P2 must degrade the
        "never signed in" finding to Unknown/TenantLacksP1P2, never to a false "no sign
        in" verdict.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    try {
        $uri = '/v1.0/users?$select=id,signInActivity&$top=999'
        $activity = @()

        do {
            $page = Invoke-WithRetry -OperationName 'Get-LicRawSignInActivityData' -ScriptBlock {
                Invoke-MgGraphRequest -Method GET -Uri $uri
            }

            $activity += @($page.value)
            $uri = $page.'@odata.nextLink'
        } while ($uri)

        @{ Activity = $activity; SignalState = 'Available' }
    }
    catch {
        $signalState = if ($_.Exception.Message -match "(?i)doesn't have premium license") {
            'TenantLacksP1P2'
        }
        else {
            'PermissionDenied'
        }

        Write-AuditLog -Level Warning -Message 'Sign-in activity read failed for tenant' -Data @{
            tenantId    = $TenantId
            error       = $_.Exception.Message
            signalState = $signalState
        }

        @{ Activity = @(); SignalState = $signalState }
    }
}
