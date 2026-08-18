BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Export-LicenseCostSweepWorkbook' {

    It 'throws when the adapter does not provide WriteWorkbook as a scriptblock' {
        {
            Export-LicenseCostSweepWorkbook -TenantFindings @{} -OutputPath 'C:\temp\tenant.xlsx' -Adapter @{}
        } | Should -Throw 'Export-LicenseCostSweepWorkbook requires an adapter set with a WriteWorkbook scriptblock.'
    }

    It 'builds a workbook payload using the layout contract and tenant findings' {
        $capturedPayload = $null
        $adapter = @{
            WriteWorkbook = {
                param($Payload)
                $script:capturedPayload = $Payload
            }
        }

        $tenantFindings = @{
            TenantId                    = 'tenant-a'
            RunId                       = 'licsweep-20260818T000000Z'
            AsOfUtc                     = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
            DisabledAccountFindings     = @(
                @{
                    TenantId                 = 'tenant-a'
                    UserObjectId             = 'user-disabled'
                    UserPrincipalName        = 'disabled@contoso.example'
                    DisplayName              = 'Disabled User'
                    AccountEnabled           = $false
                    AssignedPaidLicenseCount = 1
                    AssignedPaidLicenseSkus  = 'sku-e3'
                    Verdict                  = 'Yes'
                    Severity                 = 'High'
                    Reason                   = 'DisabledAccountHasPaidLicense'
                }
            )
            NeverSignedInFindings       = @()
            DuplicateOverlapFindings    = @()
            SharedMailboxReviewFindings = @()
            ServiceAccountFindings      = @()
            ErrorsAndUnknowns           = @()
            Summary                     = @{
                DisabledAccountFindingCount     = 1
                NeverSignedInFindingCount       = 0
                DuplicateOverlapFindingCount    = 0
                SharedMailboxReviewFindingCount = 0
                ServiceAccountFindingCount      = 0
                ErrorCount                      = 0
            }
        }

        $outputPath = Export-LicenseCostSweepWorkbook -TenantFindings $tenantFindings -OutputPath 'C:\temp\tenant-a.xlsx' -Adapter $adapter

        $outputPath | Should -Be 'C:\temp\tenant-a.xlsx'
        $script:capturedPayload.OutputPath | Should -Be 'C:\temp\tenant-a.xlsx'
        @($script:capturedPayload.Sheets).Count | Should -Be 7
        $script:capturedPayload.Sheets[0].Name | Should -Be 'Run Summary'
        $script:capturedPayload.Sheets[0].Rows[0].Metric | Should -Be 'TenantId'
        $script:capturedPayload.Sheets[0].Rows[0].Value | Should -Be 'tenant-a'
        $script:capturedPayload.Sheets[1].Name | Should -Be 'Disabled Account Findings'
        $script:capturedPayload.Sheets[1].Rows.Count | Should -Be 1
        $script:capturedPayload.Sheets[1].Rows[0].Reason | Should -Be 'DisabledAccountHasPaidLicense'
        $script:capturedPayload.Sheets[6].Name | Should -Be 'Errors and Unknowns'
    }
}
