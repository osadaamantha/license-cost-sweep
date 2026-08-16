function Get-RetryDelay {
    <#
        .SYNOPSIS
        Pure: attempt number + policy -> delay in seconds, honouring a server-supplied
        Retry-After when present. The testable half of the retry policy.

        .DESCRIPTION
        Policy: delay = min(2s * 2^(attempt-1), 60s), full jitter applied by the caller
        (jitter is intentionally not computed here so the function stays deterministic
        and Pester-testable; pass -JitterRandomValue only to inject a specific jitter
        draw from a test).
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$AttemptNumber,

        [ValidateRange(0, [int]::MaxValue)]
        [Nullable[int]]$RetryAfterSeconds = $null,

        [double]$BaseSeconds = 2.0,
        [double]$MaxSeconds = 60.0,

        # 0.0-1.0 draw supplied by the caller. Defaults to 1.0 (no reduction) so an
        # omitted draw fails safe toward the longer delay rather than a zero-second retry.
        [ValidateRange(0.0, 1.0)]
        [double]$JitterRandomValue = 1.0
    )

    if ($null -ne $RetryAfterSeconds) {
        return [double]$RetryAfterSeconds
    }

    $uncapped = $BaseSeconds * [Math]::Pow(2, $AttemptNumber - 1)
    $capped = [Math]::Min($uncapped, $MaxSeconds)

    return $capped * $JitterRandomValue
}
