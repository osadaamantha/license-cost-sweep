BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Test-LicDisabledAccountLicense' {

    It 'AccountEnabled null -> Unknown, never inferred' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicDisabledAccountLicense -AccountEnabled $null -AssignedPaidLicenseCount 1
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be 'AccountEnabledUnavailable'
        }
    }

    It 'AssignedPaidLicenseCount null -> Unknown, even when the account is known disabled' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicDisabledAccountLicense -AccountEnabled $false -AssignedPaidLicenseCount $null
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be 'LicenseAssignmentDataUnavailable'
        }
    }

    It 'Enabled account -> No, regardless of licence count' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicDisabledAccountLicense -AccountEnabled $true -AssignedPaidLicenseCount 3
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'AccountEnabled'
        }
    }

    It 'Disabled account with no paid licence -> No' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicDisabledAccountLicense -AccountEnabled $false -AssignedPaidLicenseCount 0
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'DisabledAccountNoPaidLicense'
        }
    }

    It 'Disabled account with a paid licence -> Yes, severity High' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicDisabledAccountLicense -AccountEnabled $false -AssignedPaidLicenseCount 2
            $result.Verdict | Should -Be 'Yes'
            $result.Severity | Should -Be 'High' -Because 'this is the fixed, provisional severity for this finding type'
            $result.Reason | Should -Be 'DisabledAccountHasPaidLicense'
        }
    }
}
