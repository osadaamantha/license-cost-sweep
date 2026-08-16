function Invoke-WithRetry {
    <#
        .SYNOPSIS
        Bounded exponential backoff with full jitter around a scriptblock. Impure by
        design (Start-Sleep, Get-Random) — never called from Private/Analysis, Model, or
        Report.

        .DESCRIPTION
        Retries only on throttling/transient shapes (see Test-IsThrottlingError). Never
        retries 401/403 (RBAC/capability gap) or any other error — those are recorded and
        the caller moves on. Maximum 5 attempts, matching the documented policy.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(1, 20)]
        [int]$MaxAttempts = 5,

        [string]$OperationName = 'operation'
    )

    $attempt = 0
    while ($true) {
        $attempt++
        try {
            return & $ScriptBlock
        }
        catch {
            $statusCode = 0
            if ($_.Exception.PSObject.Properties.Match('Response').Count -gt 0 -and $_.Exception.Response) {
                try { $statusCode = [int]$_.Exception.Response.StatusCode } catch { $statusCode = 0 }
            }

            $isThrottled = Test-IsThrottlingError -StatusCode $statusCode -ErrorMessage $_.Exception.Message

            if (-not $isThrottled -or $attempt -ge $MaxAttempts) {
                throw
            }

            $retryAfter = $null
            if ($_.Exception.PSObject.Properties.Match('Response').Count -gt 0 -and $_.Exception.Response -and $_.Exception.Response.Headers) {
                $header = $_.Exception.Response.Headers['Retry-After']
                if ($header) { [int]$parsed = 0; if ([int]::TryParse($header, [ref]$parsed)) { $retryAfter = $parsed } }
            }

            $jitter = Get-Random -Minimum 0.0 -Maximum 1.0
            $delaySeconds = Get-RetryDelay -AttemptNumber $attempt -RetryAfterSeconds $retryAfter -JitterRandomValue $jitter

            Write-AuditLog -Level 'Warning' -Message "Retrying $OperationName after throttle/transient error" -Data @{
                attempt      = $attempt
                maxAttempts  = $MaxAttempts
                delaySeconds = [Math]::Round($delaySeconds, 2)
            }

            Start-Sleep -Seconds $delaySeconds
        }
    }
}
