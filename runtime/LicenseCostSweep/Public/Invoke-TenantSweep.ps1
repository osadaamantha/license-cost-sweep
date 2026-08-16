function Invoke-TenantSweep {
    <#
        .SYNOPSIS
        Runs the licence-waste sweep for a single client tenant.

        .DESCRIPTION
        Not implemented yet. Adapter/orchestration wiring lands in a later pass; this
        pass only locks the parameter signature. -Adapter exists for test/replay
        injection only -- production call paths never pass it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [datetime]$AsOfUtc,

        [Parameter(Mandatory)]
        [string]$RunId,

        [hashtable]$Adapter
    )

    throw [System.NotImplementedException]::new('Invoke-TenantSweep is not implemented yet -- adapter/orchestration wiring lands in a later pass.')
}
