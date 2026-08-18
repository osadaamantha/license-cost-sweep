function Invoke-TenantSweep {
    <#
        .SYNOPSIS
        Runs the licence-waste sweep for a single client tenant.

        .DESCRIPTION
        Adapter-driven single-tenant orchestrator. The adapter supplies normalized
        tenant evidence; this function applies the pure Analysis functions, captures
        per-record failures into ErrorsAndUnknowns, and returns one tenant-scoped
        findings object. -Adapter exists for test/replay injection only -- production
        call paths never pass it.
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

    function Get-LicFieldValue {
        param(
            [Parameter(Mandatory)]
            [object]$InputObject,

            [Parameter(Mandatory)]
            [string]$Name,

            $Default = $null
        )

        if ($null -eq $InputObject) {
            return $Default
        }

        if ($InputObject -is [hashtable]) {
            if ($InputObject.ContainsKey($Name)) {
                return $InputObject[$Name]
            }

            return $Default
        }

        $property = $InputObject.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return $Default
        }

        return $property.Value
    }

    function Join-LicStringList {
        param($Value)

        if ($null -eq $Value) {
            return ''
        }

        @($Value | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join '; '
    }

    $result = @{
        TenantId                    = $TenantId
        RunId                       = $RunId
        AsOfUtc                     = $AsOfUtc.ToUniversalTime()
        DisabledAccountFindings     = @()
        NeverSignedInFindings       = @()
        DuplicateOverlapFindings    = @()
        SharedMailboxReviewFindings = @()
        ServiceAccountFindings      = @()
        ErrorsAndUnknowns           = @()
        Summary                     = @{}
    }

    function Add-LicFailureRecord {
        param(
            [Parameter(Mandatory)]
            [string]$Stage,

            [Parameter(Mandatory)]
            [AllowEmptyString()]
            [string]$TargetId,

            [Parameter(Mandatory)]
            [System.Management.Automation.ErrorRecord]$ErrorRecord
        )

        $failure = ConvertTo-AuditFailureRecord -Stage $Stage -TargetId $TargetId -ErrorRecord $ErrorRecord
        $result.ErrorsAndUnknowns += @{
            Timestamp    = Get-UtcTimestamp -DateTime (Get-Date)
            TenantId     = $TenantId
            Stage        = $failure.stage
            TargetId     = $failure.targetId
            Outcome      = $failure.outcome
            AttemptCount = $failure.attemptCount
            ErrorType    = $failure.errorType
            ErrorMessage = $failure.errorMessage
        }
    }

    if ($null -eq $Adapter -or -not $Adapter.ContainsKey('GetTenantEvidence') -or $Adapter.GetTenantEvidence -isnot [scriptblock]) {
        throw "Invoke-TenantSweep requires -Adapter with a GetTenantEvidence scriptblock."
    }

    Write-AuditLog -Message "Starting tenant sweep" -Data @{
        tenantId = $TenantId
        runId    = $RunId
    }

    try {
        $evidence = & $Adapter.GetTenantEvidence $TenantId $AsOfUtc.ToUniversalTime() $RunId
    }
    catch {
        Add-LicFailureRecord -Stage 'GetTenantEvidence' -TargetId '' -ErrorRecord $_
        $result.Summary = @{
            DisabledAccountFindingCount     = 0
            NeverSignedInFindingCount       = 0
            DuplicateOverlapFindingCount    = 0
            SharedMailboxReviewFindingCount = 0
            ServiceAccountFindingCount      = 0
            ErrorCount                      = $result.ErrorsAndUnknowns.Count
        }

        Write-AuditLog -Level 'Error' -Message 'Tenant sweep failed while loading evidence' -Data @{
            tenantId   = $TenantId
            runId      = $RunId
            errorCount = $result.ErrorsAndUnknowns.Count
        }

        return $result
    }

    if ($null -eq $evidence) {
        $evidence = @{}
    }

    $disabledInputs = @((Get-LicFieldValue -InputObject $evidence -Name 'DisabledAccountInputs' -Default @()))
    $neverSignedInInputs = @((Get-LicFieldValue -InputObject $evidence -Name 'NeverSignedInInputs' -Default @()))
    $licenseOverlapInputs = @((Get-LicFieldValue -InputObject $evidence -Name 'LicenseOverlapInputs' -Default @()))
    $sharedMailboxInputs = @((Get-LicFieldValue -InputObject $evidence -Name 'SharedMailboxInputs' -Default @()))
    $serviceAccountInputs = @((Get-LicFieldValue -InputObject $evidence -Name 'ServiceAccountInputs' -Default @()))
    $overlapMap = @((Get-LicFieldValue -InputObject $evidence -Name 'OverlapMap' -Default @()))
    $serviceAccountPredicate = Get-LicFieldValue -InputObject $evidence -Name 'ServiceAccountPredicate'

    foreach ($item in $disabledInputs) {
        try {
            $classification = Test-LicDisabledAccountLicense `
                -AccountEnabled (Get-LicFieldValue -InputObject $item -Name 'AccountEnabled') `
                -AssignedPaidLicenseCount (Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseCount')

            if ($classification.Verdict -notin @('No', 'NotApplicable')) {
                $result.DisabledAccountFindings += @{
                    TenantId                 = $TenantId
                    UserObjectId             = [string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')
                    UserPrincipalName        = [string](Get-LicFieldValue -InputObject $item -Name 'UserPrincipalName' -Default '')
                    DisplayName              = [string](Get-LicFieldValue -InputObject $item -Name 'DisplayName' -Default '')
                    AccountEnabled           = Get-LicFieldValue -InputObject $item -Name 'AccountEnabled'
                    AssignedPaidLicenseCount = Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseCount'
                    AssignedPaidLicenseSkus  = Join-LicStringList (Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseSkus' -Default @())
                    Verdict                  = $classification.Verdict
                    Severity                 = $classification.Severity
                    Reason                   = $classification.Reason
                }
            }
        }
        catch {
            Add-LicFailureRecord -Stage 'DisabledAccountAnalysis' -TargetId ([string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')) -ErrorRecord $_
        }
    }

    foreach ($item in $neverSignedInInputs) {
        try {
            $signalState = [string](Get-LicFieldValue -InputObject $item -Name 'SignInSignalState' -Default 'NotCollected')
            $classification = Test-LicNeverSignedIn `
                -AsOfUtc $AsOfUtc.ToUniversalTime() `
                -CreatedDateTime (Get-LicFieldValue -InputObject $item -Name 'CreatedDateTime') `
                -LastSignInDateTime (Get-LicFieldValue -InputObject $item -Name 'LastSignInDateTime') `
                -SignInSignalState $signalState

            if ($classification.Verdict -notin @('No', 'NotApplicable')) {
                $result.NeverSignedInFindings += @{
                    TenantId            = $TenantId
                    UserObjectId        = [string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')
                    UserPrincipalName   = [string](Get-LicFieldValue -InputObject $item -Name 'UserPrincipalName' -Default '')
                    DisplayName         = [string](Get-LicFieldValue -InputObject $item -Name 'DisplayName' -Default '')
                    CreatedDateTime     = Get-LicFieldValue -InputObject $item -Name 'CreatedDateTime'
                    LastSignInDateTime  = Get-LicFieldValue -InputObject $item -Name 'LastSignInDateTime'
                    EntraP1P2Available  = if ($signalState -eq 'Available') { $true } elseif ($signalState -eq 'TenantLacksP1P2') { $false } else { $null }
                    DaysSinceCreation   = $classification.DaysSinceCreation
                    DaysSinceSignIn     = $classification.DaysSinceSignIn
                    Verdict             = $classification.Verdict
                    Severity            = $classification.Severity
                    Reason              = $classification.Reason
                }
            }
        }
        catch {
            Add-LicFailureRecord -Stage 'NeverSignedInAnalysis' -TargetId ([string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')) -ErrorRecord $_
        }
    }

    foreach ($item in $licenseOverlapInputs) {
        try {
            $classification = Test-LicLicenseOverlap `
                -AssignedSkuIds @((Get-LicFieldValue -InputObject $item -Name 'AssignedSkuIds' -Default @())) `
                -OverlapMap $overlapMap

            if ($classification.Verdict -notin @('No', 'NotApplicable')) {
                $result.DuplicateOverlapFindings += @{
                    TenantId             = $TenantId
                    UserObjectId         = [string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')
                    UserPrincipalName    = [string](Get-LicFieldValue -InputObject $item -Name 'UserPrincipalName' -Default '')
                    DisplayName          = [string](Get-LicFieldValue -InputObject $item -Name 'DisplayName' -Default '')
                    AssignedSkus         = Join-LicStringList (Get-LicFieldValue -InputObject $item -Name 'AssignedSkuIds' -Default @())
                    OverlapMapConfigured = $overlapMap.Count -gt 0
                    MatchedRules         = Join-LicStringList $classification.MatchedRules
                    Verdict              = $classification.Verdict
                    Severity             = $classification.Severity
                    Reason               = $classification.Reason
                }
            }
        }
        catch {
            Add-LicFailureRecord -Stage 'LicenseOverlapAnalysis' -TargetId ([string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')) -ErrorRecord $_
        }
    }

    foreach ($item in $sharedMailboxInputs) {
        try {
            $classification = Test-LicSharedMailboxLicense `
                -RecipientTypeDetails ([string](Get-LicFieldValue -InputObject $item -Name 'RecipientTypeDetails' -Default 'Other')) `
                -AssignedPaidLicenseCount (Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseCount')

            if ($classification.Verdict -notin @('No', 'NotApplicable')) {
                $result.SharedMailboxReviewFindings += @{
                    TenantId                 = $TenantId
                    UserObjectId             = [string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')
                    UserPrincipalName        = [string](Get-LicFieldValue -InputObject $item -Name 'UserPrincipalName' -Default '')
                    DisplayName              = [string](Get-LicFieldValue -InputObject $item -Name 'DisplayName' -Default '')
                    RecipientTypeDetails     = [string](Get-LicFieldValue -InputObject $item -Name 'RecipientTypeDetails' -Default '')
                    AssignedPaidLicenseCount = Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseCount'
                    AssignedPaidLicenseSkus  = Join-LicStringList (Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseSkus' -Default @())
                    Verdict                  = $classification.Verdict
                    Severity                 = $classification.Severity
                    Reason                   = $classification.Reason
                }
            }
        }
        catch {
            Add-LicFailureRecord -Stage 'SharedMailboxAnalysis' -TargetId ([string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')) -ErrorRecord $_
        }
    }

    foreach ($item in $serviceAccountInputs) {
        try {
            $classification = Test-LicServiceAccount -UserContext $item -Predicate $serviceAccountPredicate

            if ($classification.Verdict -notin @('No', 'NotApplicable')) {
                $result.ServiceAccountFindings += @{
                    TenantId                 = $TenantId
                    UserObjectId             = [string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')
                    UserPrincipalName        = [string](Get-LicFieldValue -InputObject $item -Name 'UserPrincipalName' -Default '')
                    DisplayName              = [string](Get-LicFieldValue -InputObject $item -Name 'DisplayName' -Default '')
                    AssignedPaidLicenseCount = Get-LicFieldValue -InputObject $item -Name 'AssignedPaidLicenseCount'
                    HeuristicConfigured      = $null -ne $serviceAccountPredicate
                    Verdict                  = $classification.Verdict
                    Severity                 = $classification.Severity
                    Reason                   = $classification.Reason
                }
            }
        }
        catch {
            Add-LicFailureRecord -Stage 'ServiceAccountAnalysis' -TargetId ([string](Get-LicFieldValue -InputObject $item -Name 'UserObjectId' -Default '')) -ErrorRecord $_
        }
    }

    $result.Summary = @{
        DisabledAccountFindingCount     = $result.DisabledAccountFindings.Count
        NeverSignedInFindingCount       = $result.NeverSignedInFindings.Count
        DuplicateOverlapFindingCount    = $result.DuplicateOverlapFindings.Count
        SharedMailboxReviewFindingCount = $result.SharedMailboxReviewFindings.Count
        ServiceAccountFindingCount      = $result.ServiceAccountFindings.Count
        ErrorCount                      = $result.ErrorsAndUnknowns.Count
    }

    Write-AuditLog -Message 'Completed tenant sweep' -Data @{
        tenantId                         = $TenantId
        runId                            = $RunId
        disabledAccountFindingCount      = $result.Summary.DisabledAccountFindingCount
        neverSignedInFindingCount        = $result.Summary.NeverSignedInFindingCount
        duplicateOverlapFindingCount     = $result.Summary.DuplicateOverlapFindingCount
        sharedMailboxReviewFindingCount  = $result.Summary.SharedMailboxReviewFindingCount
        serviceAccountFindingCount       = $result.Summary.ServiceAccountFindingCount
        errorCount                       = $result.Summary.ErrorCount
    }

    return $result
}
