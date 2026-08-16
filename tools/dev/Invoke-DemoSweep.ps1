<#
    .SYNOPSIS
    Demonstration only. Feeds hand-authored, synthetic users through the pure
    Analysis functions to show the five finding types working end-to-end offline.

    .DESCRIPTION
    This is NOT a real sweep. There is no tenant connection, no Graph/EXO call, and no
    client data involved -- every user below is invented (contoso.example and
    fabrikam.example are reserved documentation domains, GUIDs are randomly generated
    placeholders). It exists to demonstrate that the rule engine built in
    feature/ps-module-skeleton actually classifies correctly, including the Unknown
    edge cases, ahead of the I/O adapters that will feed it real data.
#>

Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force

# The functions this demo calls (Test-LicDisabledAccountLicense, etc.) are Private --
# deliberately not exported, since only the four Public orchestrators are meant to be
# called from outside the module. Running the rest of this file inside the module's own
# scope, the same way the Pester suite's InModuleScope blocks do, is what gives an
# external script access to them without exporting them for real callers.
$demoBody = {

    $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()

    function Show-Finding([string]$Label, [hashtable]$Result) {
        $color = switch ($Result.Verdict) {
            'Yes' { 'Red' }
            'NeedsManualReview' { 'Yellow' }
            'Unknown' { 'DarkYellow' }
            'NotApplicable' { 'Gray' }
            default { 'Green' }
        }
        Write-Host ("  {0,-46} Verdict={1,-18} Severity={2,-10} Reason={3}" -f $Label, $Result.Verdict, $Result.Severity, $Result.Reason) -ForegroundColor $color
    }

    Write-Host "LICENSE COST SWEEP -- DEMO RUN (synthetic fixture data, NOT a live tenant)" -ForegroundColor Cyan
    Write-Host "AsOfUtc: $asOfUtc`n"

    Write-Host '--- Disabled account with paid licence ---' -ForegroundColor White
    Show-Finding 'Jordan Rivera (disabled, still licensed)' (Test-LicDisabledAccountLicense -AccountEnabled $false -AssignedPaidLicenseCount 1)
    Show-Finding 'Morgan Lee (disabled, licence already removed)' (Test-LicDisabledAccountLicense -AccountEnabled $false -AssignedPaidLicenseCount 0)
    Show-Finding 'Avery Chen (Graph account state unresolved)' (Test-LicDisabledAccountLicense -AccountEnabled $null -AssignedPaidLicenseCount 1)

    Write-Host "`n--- Never signed in ---" -ForegroundColor White
    Show-Finding 'Priya Nair (inactive 90 days)' (Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $asOfUtc.AddDays(-90) -SignInSignalState 'Available')
    Show-Finding 'Sam Okafor (new hire, 10 days old)' (Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddDays(-10) -LastSignInDateTime $null -SignInSignalState 'Available')
    Show-Finding 'Client tenant lacks Entra P1/P2' (Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $null -SignInSignalState 'TenantLacksP1P2')
    Show-Finding 'Dana Kim (old account, null sign-in -- ambiguous)' (Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $null -SignInSignalState 'Available')

    Write-Host "`n--- Duplicate / overlapping licences ---" -ForegroundColor White
    Show-Finding 'No overlap map configured yet' (Test-LicLicenseOverlap -AssignedSkuIds @('sku-e5', 'sku-e3'))
    $sampleOverlapMap = @(@{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3-SampleOnly' })
    Show-Finding 'Taylor Brooks (sample map only, not stakeholder-confirmed)' (Test-LicLicenseOverlap -AssignedSkuIds @('sku-e5', 'sku-e3') -OverlapMap $sampleOverlapMap)

    Write-Host "`n--- Shared mailbox with paid licence ---" -ForegroundColor White
    Show-Finding 'Accounts Payable (shared, licensed)' (Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount 1)
    Show-Finding 'Reception (shared, unlicensed)' (Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount 0)

    Write-Host "`n--- Service / automation account ---" -ForegroundColor White
    Show-Finding 'svc-backup (no heuristic configured yet)' (Test-LicServiceAccount -UserContext @{ UserPrincipalName = 'svc-backup@fabrikam.example' })
    $namingPredicate = { param($u) $u.UserPrincipalName -like 'svc-*' }
    Show-Finding 'svc-reporting (sample naming predicate only)' (Test-LicServiceAccount -UserContext @{ UserPrincipalName = 'svc-reporting@fabrikam.example' } -Predicate $namingPredicate)

    Write-Host "`n=== End of demo run ===" -ForegroundColor Cyan
}

& (Get-Module LicenseCostSweep) $demoBody
