function Assert-RuntimeModule {
    <#
        .SYNOPSIS
        Fails fast at container startup if a required runtime dependency is absent.

        .DESCRIPTION
        RequiredModules in the manifest is deliberately empty so the module still imports
        on a workstation that lacks EXO/Graph/ImportExcel (needed for offline testing of
        the pure business-rule core). This is the startup-time substitute, called only
        from the container entrypoint. Autotask ticket creation uses Invoke-RestMethod
        directly -- no separate PowerShell module dependency for it.
    #>
    [CmdletBinding()]
    param(
        [string[]]$RequiredModuleNames = @('ExchangeOnlineManagement', 'Microsoft.Graph.Authentication', 'ImportExcel', 'Az.KeyVault', 'Az.Storage')
    )

    $missing = @($RequiredModuleNames | Where-Object { -not (Get-Module -ListAvailable -Name $_) })

    if ($missing.Count -gt 0) {
        throw "Required runtime module(s) not available: $($missing -join ', ')"
    }
}
