function Disconnect-LicTenantSession {
    <#
        .SYNOPSIS
        Fully tears down the EXO + Graph session for one tenant.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Session
    )

    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-AuditLog -Level Warning -Message 'Disconnect-ExchangeOnline failed' -Data @{
            tenantId = $Session.TenantId
            error    = $_.Exception.Message
        }
    }

    try {
        Disconnect-MgGraph -ErrorAction Stop | Out-Null
    }
    catch {
        Write-AuditLog -Level Warning -Message 'Disconnect-MgGraph failed' -Data @{
            tenantId = $Session.TenantId
            error    = $_.Exception.Message
        }
    }

    Write-AuditLog -Level Info -Message 'Disconnected tenant session' -Data @{ tenantId = $Session.TenantId }
}
