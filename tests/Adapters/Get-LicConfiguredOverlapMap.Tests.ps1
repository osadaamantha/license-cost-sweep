BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicConfiguredOverlapMap' {
    It 'returns the configured overlap map from tenant context' {
        InModuleScope LicenseCostSweep {
            $map = Get-LicConfiguredOverlapMap -TenantContext @{
                OverlapMap = @(
                    @{
                        PrimarySkuId      = 'sku-e5'
                        PrerequisiteSkuId = 'sku-e3'
                        Reason            = 'E5SupersedesE3'
                    }
                )
            }

            $map.Count | Should -Be 1
            $map[0].Reason | Should -Be 'E5SupersedesE3'
        }
    }

    It 'returns an empty array when tenant context has no overlap map' {
        InModuleScope LicenseCostSweep {
            @(Get-LicConfiguredOverlapMap -TenantContext @{}).Count | Should -Be 0
        }
    }
}
