BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Test-LicLicenseOverlap' {

    It 'Empty overlap map (default) -> NotApplicable regardless of assigned SKUs, refusing to guess a table' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicLicenseOverlap -AssignedSkuIds @('sku-a', 'sku-b')
            $result.Verdict | Should -Be 'NotApplicable'
            $result.Reason | Should -Be 'NoOverlapMapConfigured'
        }
    }

    It 'Non-empty map, user holds both sides of a pair -> Yes with MatchedRules populated' {
        InModuleScope LicenseCostSweep {
            $map = @(@{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3' })
            $result = Test-LicLicenseOverlap -AssignedSkuIds @('sku-e5', 'sku-e3') -OverlapMap $map
            $result.Verdict | Should -Be 'Yes'
            $result.Severity | Should -Be 'Medium'
            $result.Reason | Should -Be 'DuplicateLicenseDetected'
            $result.MatchedRules | Should -Contain 'E5SupersedesE3'
        }
    }

    It 'Non-empty map, user holds only one side of the pair -> No' {
        InModuleScope LicenseCostSweep {
            $map = @(@{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3' })
            $result = Test-LicLicenseOverlap -AssignedSkuIds @('sku-e5') -OverlapMap $map
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'NoOverlapDetected'
        }
    }

    It 'Non-empty map, multiple rules match -> MatchedRules contains every matched reason' {
        InModuleScope LicenseCostSweep {
            $map = @(
                @{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3' }
                @{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-emsE5'; Reason = 'E5IncludesEmsE5' }
            )
            $result = Test-LicLicenseOverlap -AssignedSkuIds @('sku-e5', 'sku-e3', 'sku-emsE5') -OverlapMap $map
            $result.Verdict | Should -Be 'Yes'
            $result.MatchedRules | Should -HaveCount 2
            $result.MatchedRules | Should -Contain 'E5SupersedesE3'
            $result.MatchedRules | Should -Contain 'E5IncludesEmsE5'
        }
    }

    It 'Non-empty map, empty AssignedSkuIds -> No' {
        InModuleScope LicenseCostSweep {
            $map = @(@{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3' })
            $result = Test-LicLicenseOverlap -AssignedSkuIds @() -OverlapMap $map
            $result.Verdict | Should -Be 'No'
        }
    }
}
