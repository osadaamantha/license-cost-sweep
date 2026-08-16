BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Test-LicSharedMailboxLicense' {

    It 'Not a shared mailbox -> NotApplicable' -TestCases @(
        @{ RecipientTypeDetails = 'UserMailbox' }
        @{ RecipientTypeDetails = 'RoomMailbox' }
        @{ RecipientTypeDetails = 'EquipmentMailbox' }
        @{ RecipientTypeDetails = 'DiscoveryMailbox' }
        @{ RecipientTypeDetails = 'Other' }
    ) {
        InModuleScope LicenseCostSweep -Parameters @{ RecipientTypeDetails = $RecipientTypeDetails } {
            param($RecipientTypeDetails)
            $result = Test-LicSharedMailboxLicense -RecipientTypeDetails $RecipientTypeDetails -AssignedPaidLicenseCount 1
            $result.Verdict | Should -Be 'NotApplicable'
            $result.Reason | Should -Be 'NotASharedMailbox'
        }
    }

    It 'Shared mailbox, licence data unavailable -> Unknown' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount $null
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be 'LicenseAssignmentDataUnavailable'
        }
    }

    It 'Shared mailbox, no paid licence -> No' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount 0
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'SharedMailboxNoPaidLicense'
        }
    }

    It 'Shared mailbox with a paid licence -> always NeedsManualReview, never a waste verdict' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount 1
            $result.Verdict | Should -Be 'NeedsManualReview'
            $result.Severity | Should -Be 'Info'
            $result.Reason | Should -Be 'SharedMailboxHasPaidLicenseReviewRequired'
        }
    }

    It 'Regression guard: a licensed shared mailbox never resolves to a bare Yes/No waste verdict' -TestCases @(
        @{ Count = 1 }
        @{ Count = 5 }
    ) {
        InModuleScope LicenseCostSweep -Parameters @{ Count = $Count } {
            param($Count)
            $result = Test-LicSharedMailboxLicense -RecipientTypeDetails 'SharedMailbox' -AssignedPaidLicenseCount $Count
            $result.Verdict | Should -Not -BeIn @('Yes', 'No') -Because 'shared mailbox findings are always a review category, never an auto-classified waste verdict or an auto-exemption'
        }
    }
}
