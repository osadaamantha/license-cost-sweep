function Test-LicServiceAccount {
    <#
        .SYNOPSIS
        Pure: service/automation account identification -> Yes/No/Unknown finding behind
        an injectable, caller-supplied detection predicate.

        .DESCRIPTION
        The actual detection heuristic (naming convention? userType? a dedicated group?)
        is NOT yet confirmed by the stakeholder. This function refuses to guess: with no
        -Predicate supplied, the result is always Unknown/ServiceAccountHeuristicNotConfigured.
        The predicate contract is deliberately minimal (a single [bool] over $UserContext)
        as a placeholder -- if the real heuristic turns out to need a tri-state answer,
        this contract will need to change once that heuristic is confirmed.

        Severity (Info) is a fixed, provisional judgment call, not a confirmed scoring
        model. Findings from this function are reported separately from other categories,
        never folded into another finding or excluded from the report.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object]$UserContext,

        [scriptblock]$Predicate = $null
    )

    if ($null -eq $Predicate) {
        return @{ Verdict = 'Unknown'; Severity = 'Unknown'; Reason = 'ServiceAccountHeuristicNotConfigured' }
    }

    $isServiceAccount = [bool](& $Predicate $UserContext)

    if ($isServiceAccount) {
        return @{ Verdict = 'Yes'; Severity = 'Info'; Reason = 'ServiceAccountDetected' }
    }

    return @{ Verdict = 'No'; Severity = 'None'; Reason = 'NotAServiceAccount' }
}
