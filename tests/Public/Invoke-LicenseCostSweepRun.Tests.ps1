BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Invoke-LicenseCostSweepRun' {

    It 'uses one run id across all enabled tenants and aggregates tenant summaries' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $seenRunIds = @()

        $adapter = @{
            GetConfigRows = {
                @(
                    @{
                        TenantId     = 'tenant-a'
                        TenantDomain = 'contoso.example'
                        Enabled      = 'Y'
                    }
                    @{
                        TenantId     = 'tenant-b'
                        TenantDomain = 'fabrikam.example'
                        Enabled      = 'N'
                    }
                    @{
                        TenantId     = 'tenant-c'
                        TenantDomain = 'wingtip.example'
                        Enabled      = 'Y'
                    }
                )
            }
            GetTenantEvidence = {
                param($TenantId, $AsOfUtc, $RunId)

                $script:seenRunIds += $RunId

                switch ($TenantId) {
                    'tenant-a' {
                        return @{
                            DisabledAccountInputs = @(
                                @{
                                    UserObjectId             = 'user-disabled-a'
                                    UserPrincipalName        = 'disabled.a@contoso.example'
                                    DisplayName              = 'Disabled A'
                                    AccountEnabled           = $false
                                    AssignedPaidLicenseCount = 1
                                    AssignedPaidLicenseSkus  = @('sku-e3')
                                }
                            )
                        }
                    }
                    'tenant-c' {
                        return @{
                            NeverSignedInInputs = @(
                                @{
                                    UserObjectId       = 'user-never-c'
                                    UserPrincipalName  = 'never.c@wingtip.example'
                                    DisplayName        = 'Never C'
                                    CreatedDateTime    = $AsOfUtc.AddYears(-1)
                                    LastSignInDateTime = $AsOfUtc.AddDays(-40)
                                    SignInSignalState  = 'Available'
                                }
                            )
                        }
                    }
                    default {
                        throw "Unexpected tenant id $TenantId"
                    }
                }
            }
        }

        $result = Invoke-LicenseCostSweepRun -AsOfUtc $asOfUtc -Adapter $adapter

        $result.RunId | Should -Match '^licsweep-20260818T000000Z$'
        $result.TenantResults.Count | Should -Be 2
        $result.TenantResults[0].TenantId | Should -Be 'tenant-a'
        $result.TenantResults[1].TenantId | Should -Be 'tenant-c'
        @($script:seenRunIds | Select-Object -Unique).Count | Should -Be 1
        $script:seenRunIds[0] | Should -Be $result.RunId

        $result.Summary.TenantCount | Should -Be 2
        $result.Summary.DisabledAccountFindingCount | Should -Be 1
        $result.Summary.NeverSignedInFindingCount | Should -Be 1
        $result.Summary.DuplicateOverlapFindingCount | Should -Be 0
        $result.Summary.SharedMailboxReviewFindingCount | Should -Be 0
        $result.Summary.ServiceAccountFindingCount | Should -Be 0
        $result.Summary.ErrorCount | Should -Be 0
    }

    It 'returns zero counts when no enabled tenants are configured' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetConfigRows = {
                @(
                    @{
                        TenantId     = 'tenant-a'
                        TenantDomain = 'contoso.example'
                        Enabled      = 'N'
                    }
                )
            }
            GetTenantEvidence = {
                param($TenantId, $AsOfUtc, $RunId)
                throw 'should not be called when no tenants are enabled'
            }
        }

        $result = Invoke-LicenseCostSweepRun -AsOfUtc $asOfUtc -Adapter $adapter

        $result.TenantResults.Count | Should -Be 0
        $result.Summary.TenantCount | Should -Be 0
        $result.Summary.DisabledAccountFindingCount | Should -Be 0
        $result.Summary.ErrorCount | Should -Be 0
    }
}
