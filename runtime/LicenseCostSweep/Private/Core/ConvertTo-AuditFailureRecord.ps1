function ConvertTo-AuditFailureRecord {
    <#
        .SYNOPSIS
        Exception + stage context -> a typed failure record safe to persist in run-state
        or the Errors and Unknowns report sheet.

        .DESCRIPTION
        Never carries a raw exception message or a user's address. -TargetId must be an
        object-id-shaped identifier, never a UPN or SMTP address (user addresses are
        sensitive in logs and state).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Stage,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$TargetId,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [int]$AttemptCount = 1,

        [ValidateSet('PermissionDenied', 'NotLicensed', 'Throttled', 'Timeout', 'NotFound', 'TimeBudgetExhausted', 'SignalConflict', 'ParseError', 'Unexpected')]
        [string]$Outcome = 'Unexpected'
    )

    @{
        stage        = $Stage
        targetId     = $TargetId
        outcome      = $Outcome
        attemptCount = $AttemptCount
        errorType    = $ErrorRecord.Exception.GetType().FullName
        errorMessage = Protect-SensitiveText -Text $ErrorRecord.Exception.Message
    }
}
