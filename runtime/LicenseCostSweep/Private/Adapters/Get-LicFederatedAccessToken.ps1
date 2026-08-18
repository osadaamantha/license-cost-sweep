function Get-LicFederatedAccessToken {
    <#
        .SYNOPSIS
        Exchanges the integration managed identity for a tenant-scoped app-only token.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ClientTenantId,

        [Parameter(Mandatory)]
        [string]$SharedAppId,

        [Parameter(Mandatory)]
        [string]$IntegrationUamiClientId,

        [Parameter(Mandatory)]
        [string]$ResourceScope
    )

    Invoke-WithRetry -OperationName 'Connect-AzAccount-IntegrationUami' -ScriptBlock {
        Connect-AzAccount -Identity -AccountId $IntegrationUamiClientId | Out-Null
    }

    $assertionSecure = Invoke-WithRetry -OperationName 'Get-AzAccessToken-Assertion' -ScriptBlock {
        (Get-AzAccessToken -ResourceUrl 'api://AzureADTokenExchange').Token
    }
    $assertion = [System.Net.NetworkCredential]::new('', $assertionSecure).Password

    $tokenBody = @{
        grant_type            = 'client_credentials'
        client_id             = $SharedAppId
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion      = $assertion
        scope                 = "$ResourceScope/.default"
    }

    $tokenResponse = Invoke-WithRetry -OperationName 'Invoke-FederatedTokenExchange' -ScriptBlock {
        Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$ClientTenantId/oauth2/v2.0/token" `
            -ContentType 'application/x-www-form-urlencoded' -Body $tokenBody -ErrorAction Stop
    }

    $tokenResponse.access_token
}
