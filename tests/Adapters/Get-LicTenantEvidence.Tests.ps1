BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicTenantEvidence' {

    It 'requires the full collector set when an injected adapter is supplied' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()

        {
            Get-LicTenantEvidence -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-001' -Adapter @{}
        } | Should -Throw "Get-LicTenantEvidence requires collector 'GetUsers' as a scriptblock."
    }

    It 'normalizes raw users, recipients, sign-in activity, and paid sku ids into the Invoke-TenantSweep evidence shape' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetUsers = {
                param($TenantId)
                @(
                    @{
                        id                = 'user-a'
                        userPrincipalName = 'user.a@contoso.example'
                        displayName       = 'User A'
                        accountEnabled    = $false
                        createdDateTime   = $asOfUtc.AddYears(-1)
                        assignedLicenses  = @(
                            @{ skuId = 'sku-paid-1' }
                            @{ skuId = 'sku-free-1' }
                        )
                    }
                    @{
                        id                = 'user-b'
                        userPrincipalName = 'shared@contoso.example'
                        displayName       = 'Shared Mailbox'
                        accountEnabled    = $true
                        createdDateTime   = $asOfUtc.AddMonths(-2)
                        assignedLicenses  = @(
                            @{ skuId = 'sku-paid-2' }
                        )
                    }
                )
            }
            GetMailboxRecipients = {
                param($TenantId)
                @(
                    @{ ExternalDirectoryObjectId = 'user-a'; RecipientTypeDetails = 'UserMailbox' }
                    @{ ExternalDirectoryObjectId = 'user-b'; RecipientTypeDetails = 'SharedMailbox' }
                )
            }
            GetSignInActivity = {
                param($TenantId)
                @{
                    SignalState = 'Available'
                    Activity    = @(
                        @{
                            id = 'user-a'
                            signInActivity = @{
                                lastSuccessfulSignInDateTime = $asOfUtc.AddDays(-45)
                            }
                        }
                    )
                }
            }
            GetPaidSkuIds = {
                param($TenantId)
                @('sku-paid-1', 'sku-paid-2')
            }
            GetOverlapMap = {
                param($TenantId)
                @(@{ PrimarySkuId = 'sku-paid-2'; PrerequisiteSkuId = 'sku-paid-1'; Reason = 'SampleRule' })
            }
            GetServiceAccountPredicate = {
                param($TenantId)
                { param($u) $u.UserPrincipalName -like 'svc-*' }
            }
        }

        $result = Get-LicTenantEvidence -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-001' -Adapter $adapter

        $result.DisabledAccountInputs.Count | Should -Be 2
        $result.NeverSignedInInputs.Count | Should -Be 2
        $result.LicenseOverlapInputs.Count | Should -Be 2
        $result.SharedMailboxInputs.Count | Should -Be 2
        $result.ServiceAccountInputs.Count | Should -Be 2
        $result.OverlapMap.Count | Should -Be 1
        $result.ServiceAccountPredicate | Should -BeOfType [scriptblock]

        $userA = $result.DisabledAccountInputs | Where-Object { $_.UserObjectId -eq 'user-a' }
        $userB = $result.SharedMailboxInputs | Where-Object { $_.UserObjectId -eq 'user-b' }

        $userA.AssignedPaidLicenseCount | Should -Be 1
        $userA.AssignedPaidLicenseSkus | Should -Be @('sku-paid-1')
        $userA.AssignedSkuIds | Should -Be @('sku-paid-1', 'sku-free-1')
        $userA.LastSignInDateTime | Should -Be $asOfUtc.AddDays(-45)
        $userA.SignInSignalState | Should -Be 'Available'
        $userB.RecipientTypeDetails | Should -Be 'SharedMailbox'
        $userB.AssignedPaidLicenseCount | Should -Be 1
        $userB.LastSignInDateTime | Should -Be $null
    }

    It 'degrades paid-licence evidence to null when the paid sku set is unavailable' {
        $asOfUtc = [datetime]::Parse('2026-08-18T00:00:00Z').ToUniversalTime()
        $adapter = @{
            GetUsers = {
                param($TenantId)
                @(
                    @{
                        id                = 'user-a'
                        userPrincipalName = 'user.a@contoso.example'
                        displayName       = 'User A'
                        accountEnabled    = $false
                        createdDateTime   = $asOfUtc.AddYears(-1)
                        assignedLicenses  = @(@{ skuId = 'sku-paid-1' })
                    }
                )
            }
            GetMailboxRecipients = { param($TenantId) @() }
            GetSignInActivity = { param($TenantId) @{ SignalState = 'NotCollected'; Activity = @() } }
            GetPaidSkuIds = { param($TenantId) @() }
            GetOverlapMap = { param($TenantId) @() }
            GetServiceAccountPredicate = { param($TenantId) $null }
        }

        $result = Get-LicTenantEvidence -TenantId 'tenant-a' -AsOfUtc $asOfUtc -RunId 'run-001' -Adapter $adapter

        $result.DisabledAccountInputs[0].AssignedPaidLicenseCount | Should -Be $null
        $result.DisabledAccountInputs[0].AssignedPaidLicenseSkus | Should -Be @()
    }
}
