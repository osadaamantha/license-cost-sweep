function Test-LicNeverSignedIn {
    <#
        .SYNOPSIS
        Pure: licensed user who has never signed in -> Yes/No/Unknown finding, honouring
        the 30-day new-user grace period and Entra ID P1/P2 availability.

        .DESCRIPTION
        SignInSignalState carries every reason sign-in evidence might be unusable for this
        tenant/user: a tenant without Entra ID P1/P2 ('TenantLacksP1P2'), a permission gap
        ('PermissionDenied'), or evidence simply not collected this run ('NotCollected').
        Any of those is Unknown -- never omitted, never asserted anyway.

        A brand-new account (younger than ThresholdDays) resolves to No/WithinNewUserGracePeriod
        regardless of whether LastSignInDateTime is null -- its own creation date already
        explains a null timestamp, so this is checked before the null-sign-in ambiguity
        rule below. This ordering reconciles two separately-confirmed rules that don't say
        which wins; flagged as a judgment call, not a stakeholder-confirmed sequencing.

        Once past the grace period, a null LastSignInDateTime is itself ambiguous -- Graph
        returns null both for "never signed in" and "beyond Entra's sign-in retention
        window." Never assert "never signed in" from a null value alone; that case is
        Unknown/NullLastSignInAmbiguous, not Yes.

        Severity (Medium) is a fixed, provisional judgment call, not a confirmed scoring
        model.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [datetime]$AsOfUtc,

        [Parameter(Mandatory)]
        [datetime]$CreatedDateTime,

        [AllowNull()]
        [Nullable[datetime]]$LastSignInDateTime = $null,

        [Parameter(Mandatory)]
        [ValidateSet('Available', 'TenantLacksP1P2', 'PermissionDenied', 'NotCollected')]
        [string]$SignInSignalState,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$ThresholdDays = 30
    )

    if ($SignInSignalState -ne 'Available') {
        $reason = switch ($SignInSignalState) {
            'TenantLacksP1P2' { 'TenantLacksEntraP1P2' }
            'PermissionDenied' { 'SignInPermissionDenied' }
            'NotCollected' { 'SignInDataNotCollected' }
        }
        return @{
            Verdict           = 'Unknown'
            Severity          = 'Unknown'
            Reason            = $reason
            DaysSinceCreation = $null
            DaysSinceSignIn   = $null
        }
    }

    $daysSinceCreation = [Math]::Floor(($AsOfUtc - $CreatedDateTime).TotalDays)

    if ($daysSinceCreation -lt $ThresholdDays) {
        return @{
            Verdict           = 'No'
            Severity          = 'None'
            Reason            = 'WithinNewUserGracePeriod'
            DaysSinceCreation = $daysSinceCreation
            DaysSinceSignIn   = $null
        }
    }

    if ($null -eq $LastSignInDateTime) {
        return @{
            Verdict           = 'Unknown'
            Severity          = 'Unknown'
            Reason            = 'NullLastSignInAmbiguous'
            DaysSinceCreation = $daysSinceCreation
            DaysSinceSignIn   = $null
        }
    }

    $daysSinceSignIn = [Math]::Floor(($AsOfUtc - $LastSignInDateTime).TotalDays)

    if ($daysSinceSignIn -ge $ThresholdDays) {
        return @{
            Verdict           = 'Yes'
            Severity          = 'Medium'
            Reason            = 'InactiveBeyondThreshold'
            DaysSinceCreation = $daysSinceCreation
            DaysSinceSignIn   = $daysSinceSignIn
        }
    }

    return @{
        Verdict           = 'No'
        Severity          = 'None'
        Reason            = 'RecentSignInWithinThreshold'
        DaysSinceCreation = $daysSinceCreation
        DaysSinceSignIn   = $daysSinceSignIn
    }
}
