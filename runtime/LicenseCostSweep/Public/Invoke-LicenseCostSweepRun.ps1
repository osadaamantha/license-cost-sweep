function Invoke-LicenseCostSweepRun {
    <#
        .SYNOPSIS
        Runs the licence-waste sweep across every configured, enabled client tenant.

        .DESCRIPTION
        Adapter-driven multi-tenant run orchestrator. Loads the enabled tenant config
        set for this run, generates one run id, invokes Invoke-TenantSweep once per
        tenant, and returns an aggregate run result. -Adapter exists for test/replay
        injection only -- production call paths never pass it.
    #>
    [CmdletBinding()]
    param(
        [datetime]$AsOfUtc,

        [hashtable]$Adapter
    )

    $effectiveAsOfUtc = if ($PSBoundParameters.ContainsKey('AsOfUtc')) {
        $AsOfUtc.ToUniversalTime()
    }
    else {
        (Get-Date).ToUniversalTime()
    }

    $runId = "licsweep-$((Get-UtcTimestamp -DateTime $effectiveAsOfUtc -Format 'BlobSafe'))"

    Write-AuditLog -Message 'Starting multi-tenant sweep run' -Data @{
        runId   = $runId
        asOfUtc = Get-UtcTimestamp -DateTime $effectiveAsOfUtc
    }

    $adapters = if ($Adapter) { $Adapter } else { Get-LicDefaultAdapterSet }
    $tenantConfigs = Get-LicenseCostSweepConfiguration -Adapter $adapters
    $tenantResults = @()

    foreach ($tenantConfig in @($tenantConfigs)) {
        $tenantResults += Invoke-TenantSweep `
            -TenantId $tenantConfig.TenantId `
            -AsOfUtc $effectiveAsOfUtc `
            -RunId $runId `
            -Adapter $adapters
    }

    $result = @{
        RunId         = $runId
        AsOfUtc       = $effectiveAsOfUtc
        TenantResults = $tenantResults
        Summary       = @{
            TenantCount                      = @($tenantResults).Count
            DisabledAccountFindingCount      = @($tenantResults | ForEach-Object { $_.Summary.DisabledAccountFindingCount } | Measure-Object -Sum).Sum
            NeverSignedInFindingCount        = @($tenantResults | ForEach-Object { $_.Summary.NeverSignedInFindingCount } | Measure-Object -Sum).Sum
            DuplicateOverlapFindingCount     = @($tenantResults | ForEach-Object { $_.Summary.DuplicateOverlapFindingCount } | Measure-Object -Sum).Sum
            SharedMailboxReviewFindingCount  = @($tenantResults | ForEach-Object { $_.Summary.SharedMailboxReviewFindingCount } | Measure-Object -Sum).Sum
            ServiceAccountFindingCount       = @($tenantResults | ForEach-Object { $_.Summary.ServiceAccountFindingCount } | Measure-Object -Sum).Sum
            ErrorCount                       = @($tenantResults | ForEach-Object { $_.Summary.ErrorCount } | Measure-Object -Sum).Sum
        }
    }

    Write-AuditLog -Message 'Completed multi-tenant sweep run' -Data @{
        runId                            = $runId
        tenantCount                      = $result.Summary.TenantCount
        disabledAccountFindingCount      = $result.Summary.DisabledAccountFindingCount
        neverSignedInFindingCount        = $result.Summary.NeverSignedInFindingCount
        duplicateOverlapFindingCount     = $result.Summary.DuplicateOverlapFindingCount
        sharedMailboxReviewFindingCount  = $result.Summary.SharedMailboxReviewFindingCount
        serviceAccountFindingCount       = $result.Summary.ServiceAccountFindingCount
        errorCount                       = $result.Summary.ErrorCount
    }

    return $result
}
