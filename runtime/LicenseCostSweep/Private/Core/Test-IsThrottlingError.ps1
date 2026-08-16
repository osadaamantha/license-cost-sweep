function Test-IsThrottlingError {
    <#
        .SYNOPSIS
        Pure classifier: does this error shape indicate a retryable throttle/transient
        condition, as opposed to a permission or not-found error that must not be retried?

        .DESCRIPTION
        Microsoft does not publish a concrete app-only EXO rate limit. This checks the
        observable symptoms only: HTTP 429/503/504 and EXO error text matching known
        throttling vocabulary. 401/403 are deliberately excluded here — those are RBAC/
        capability gaps, recorded and never retried.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [int]$StatusCode,
        [AllowEmptyString()]
        [string]$ErrorMessage = ''
    )

    if ($StatusCode -in 429, 503, 504) {
        return $true
    }

    if ([string]::IsNullOrEmpty($ErrorMessage)) {
        return $false
    }

    return $ErrorMessage -match '(?i)throttl|too many requests|budget|MaxConcurrency|ServerBusy|timed? ?out'
}
