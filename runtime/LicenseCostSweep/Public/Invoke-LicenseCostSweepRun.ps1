function Invoke-LicenseCostSweepRun {
    <#
        .SYNOPSIS
        Runs the licence-waste sweep across every configured, enabled client tenant.

        .DESCRIPTION
        Not implemented yet. Adapter/orchestration wiring lands in a later pass; this
        pass only locks the parameter signature.
    #>
    [CmdletBinding()]
    param(
        [datetime]$AsOfUtc
    )

    throw [System.NotImplementedException]::new('Invoke-LicenseCostSweepRun is not implemented yet -- adapter/orchestration wiring lands in a later pass.')
}
