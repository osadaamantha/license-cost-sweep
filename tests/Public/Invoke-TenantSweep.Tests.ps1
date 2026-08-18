BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Invoke-TenantSweep' {

    It 'throws when the adapter does not provide GetTenantEvidence as a scriptblock' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()

        {
            Invoke-TenantSweep -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-001' -Adapter @{}
        } | Should -Throw 'Invoke-TenantSweep requires -Adapter with a GetTenantEvidence scriptblock.'
    }

    It 'returns tenant-scoped findings and summary counts from adapter-supplied evidence' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetTenantEvidence = {
                param($TenantId, $AsOfUtc, $RunId)

                @{
                    DisabledAccountInputs = @(
                        @{
                            UserObjectId             = 'user-disabled'
                            UserPrincipalName        = 'disabled@contoso.example'
                            DisplayName              = 'Disabled User'
                            AccountEnabled           = $false
                            AssignedPaidLicenseCount = 2
                            AssignedPaidLicenseSkus  = @('sku-e3', 'sku-powerbi')
                        }
                    )
                    NeverSignedInInputs = @(
                        @{
                            UserObjectId       = 'user-never'
                            UserPrincipalName  = 'never@contoso.example'
                            DisplayName        = 'Never Signed In'
                            CreatedDateTime    = $AsOfUtc.AddYears(-1)
                            LastSignInDateTime = $AsOfUtc.AddDays(-45)
                            SignInSignalState  = 'Available'
                        }
                    )
                    LicenseOverlapInputs = @(
                        @{
                            UserObjectId      = 'user-overlap'
                            UserPrincipalName = 'overlap@contoso.example'
                            DisplayName       = 'Overlap User'
                            AssignedSkuIds    = @('sku-e5', 'sku-e3')
                        }
                    )
                    SharedMailboxInputs = @(
                        @{
                            UserObjectId             = 'mailbox-shared'
                            UserPrincipalName        = 'shared@contoso.example'
                            DisplayName              = 'Shared Mailbox'
                            RecipientTypeDetails     = 'SharedMailbox'
                            AssignedPaidLicenseCount = 1
                            AssignedPaidLicenseSkus  = @('sku-exo-p2')
                        }
                    )
                    ServiceAccountInputs = @(
                        @{
                            UserObjectId             = 'user-service'
                            UserPrincipalName        = 'svc-backup@contoso.example'
                            DisplayName              = 'Service Account'
                            AssignedPaidLicenseCount = 1
                        }
                    )
                    OverlapMap = @(
                        @{
                            PrimarySkuId      = 'sku-e5'
                            PrerequisiteSkuId = 'sku-e3'
                            Reason            = 'E5SupersedesE3'
                        }
                    )
                    ServiceAccountPredicate = { param($u) $u.UserPrincipalName -like 'svc-*' }
                }
            }
        }

        $result = Invoke-TenantSweep -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-001' -Adapter $adapter

        $result.TenantId | Should -Be 'tenant-a'
        $result.RunId | Should -Be 'run-001'
        $result.DisabledAccountFindings.Count | Should -Be 1
        $result.NeverSignedInFindings.Count | Should -Be 1
        $result.DuplicateOverlapFindings.Count | Should -Be 1
        $result.SharedMailboxReviewFindings.Count | Should -Be 1
        $result.ServiceAccountFindings.Count | Should -Be 1
        $result.ErrorsAndUnknowns.Count | Should -Be 0

        $result.DisabledAccountFindings[0].Reason | Should -Be 'DisabledAccountHasPaidLicense'
        $result.NeverSignedInFindings[0].Reason | Should -Be 'InactiveBeyondThreshold'
        $result.DuplicateOverlapFindings[0].MatchedRules | Should -Be 'E5SupersedesE3'
        $result.SharedMailboxReviewFindings[0].Verdict | Should -Be 'NeedsManualReview'
        $result.ServiceAccountFindings[0].Reason | Should -Be 'ServiceAccountDetected'

        $result.Summary.DisabledAccountFindingCount | Should -Be 1
        $result.Summary.NeverSignedInFindingCount | Should -Be 1
        $result.Summary.DuplicateOverlapFindingCount | Should -Be 1
        $result.Summary.SharedMailboxReviewFindingCount | Should -Be 1
        $result.Summary.ServiceAccountFindingCount | Should -Be 1
        $result.Summary.ErrorCount | Should -Be 0
    }

    It 'records per-item analysis failures and continues processing the rest of the tenant evidence' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetTenantEvidence = {
                param($TenantId, $AsOfUtc, $RunId)

                @{
                    NeverSignedInInputs = @(
                        @{
                            UserObjectId       = 'broken-user'
                            UserPrincipalName  = 'broken@contoso.example'
                            DisplayName        = 'Broken User'
                            LastSignInDateTime = $AsOfUtc.AddDays(-45)
                            SignInSignalState  = 'Available'
                        },
                        @{
                            UserObjectId       = 'good-user'
                            UserPrincipalName  = 'good@contoso.example'
                            DisplayName        = 'Good User'
                            CreatedDateTime    = $AsOfUtc.AddYears(-1)
                            LastSignInDateTime = $AsOfUtc.AddDays(-45)
                            SignInSignalState  = 'Available'
                        }
                    )
                }
            }
        }

        $result = Invoke-TenantSweep -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-002' -Adapter $adapter

        $result.NeverSignedInFindings.Count | Should -Be 1
        $result.ErrorsAndUnknowns.Count | Should -Be 1
        $result.ErrorsAndUnknowns[0].Stage | Should -Be 'NeverSignedInAnalysis'
        $result.ErrorsAndUnknowns[0].TargetId | Should -Be 'broken-user'
        $result.Summary.ErrorCount | Should -Be 1
    }

    It 'returns a tenant-scoped failure record when evidence loading throws' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetTenantEvidence = {
                param($TenantId, $AsOfUtc, $RunId)
                throw 'graph unavailable for test'
            }
        }

        $result = Invoke-TenantSweep -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-003' -Adapter $adapter

        $result.DisabledAccountFindings.Count | Should -Be 0
        $result.ErrorsAndUnknowns.Count | Should -Be 1
        $result.ErrorsAndUnknowns[0].Stage | Should -Be 'GetTenantEvidence'
        $result.Summary.ErrorCount | Should -Be 1
    }
}
