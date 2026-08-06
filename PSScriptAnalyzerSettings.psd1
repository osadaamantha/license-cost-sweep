@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # No LicenseCostSweep module exists yet — this exclusion anticipates the same
        # shape as the sibling mailbox-audit-sweep repo: Invoke-* orchestrators that
        # read Graph/EXO and only write report/state files, which the analyzer can't
        # distinguish from a state-changing cmdlet by name alone. Revisit once the
        # module lands rather than assuming this still applies unchanged.
        'PSUseShouldProcessForStateChangingFunctions'
    )
    Rules        = @{
        PSAvoidUsingCmdletAliases    = @{ Enable = $true }
        PSAvoidUsingPositionalParameters = @{ Enable = $true }
        PSUseDeclaredVarsMoreThanAssignments = @{ Enable = $true }
    }
}
