function Get-LicRawUserData {
    <#
        .SYNOPSIS
        Retry-wrapped, paged Graph read of every user's base licence-audit fields.

        .DESCRIPTION
        Kept separate from sign-in activity on purpose: signInActivity depends on
        AuditLog.Read.All and Entra ID P1/P2, while the base user/licence read should
        still succeed independently.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $uri = '/v1.0/users?$select=id,userPrincipalName,displayName,accountEnabled,createdDateTime,assignedLicenses&$top=999'
    $users = @()

    do {
        $page = Invoke-WithRetry -OperationName 'Get-LicRawUserData' -ScriptBlock {
            Invoke-MgGraphRequest -Method GET -Uri $uri
        }

        $users += @($page.value)
        $uri = $page.'@odata.nextLink'
    } while ($uri)

    $users
}
