function Connect-LicTenantSession {
    <#
        .SYNOPSIS
        Establishes one federated-identity-authenticated Exchange Online + Graph
        session for a single tenant.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'Not a hardcoded secret -- $graphToken is a freshly-issued OAuth bearer token, converted only to satisfy Connect-MgGraph -AccessToken''s SecureString parameter type.'
    )]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$Organization,

        [Parameter(Mandatory)]
        [string]$IntegrationUamiClientId
    )

    $graphToken = Get-LicFederatedAccessToken -ClientTenantId $TenantId -SharedAppId $AppId `
        -IntegrationUamiClientId $IntegrationUamiClientId -ResourceScope 'https://graph.microsoft.com'

    $exoToken = Get-LicFederatedAccessToken -ClientTenantId $TenantId -SharedAppId $AppId `
        -IntegrationUamiClientId $IntegrationUamiClientId -ResourceScope 'https://outlook.office365.com'

    Invoke-WithRetry -OperationName 'Connect-ExchangeOnline' -ScriptBlock {
        Connect-ExchangeOnline -AccessToken $exoToken -Organization $Organization -ShowBanner:$false | Out-Null
    }

    Invoke-WithRetry -OperationName 'Connect-MgGraph' -ScriptBlock {
        Connect-MgGraph -AccessToken (ConvertTo-SecureString -String $graphToken -AsPlainText -Force) -NoWelcome | Out-Null
    }

    Write-AuditLog -Level Info -Message 'Connected tenant session' -Data @{ tenantId = $TenantId }

    @{
        TenantId     = $TenantId
        AppId        = $AppId
        Organization = $Organization
    }
}
