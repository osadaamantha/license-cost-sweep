BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicRawSubscribedSkuData' {

    It 'returns the subscribed sku rows from Graph' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{ skuId = 'sku-a'; skuPartNumber = 'PART_A' }
                        @{ skuId = 'sku-b'; skuPartNumber = 'PART_B' }
                    )
                }
            }

            $result = Get-LicRawSubscribedSkuData -TenantId 'tenant-a'

            $result.Count | Should -Be 2
            $result[0].skuId | Should -Be 'sku-a'
            Should -Invoke Invoke-MgGraphRequest -Times 1 -ParameterFilter {
                $Uri -eq '/v1.0/subscribedSkus'
            }
        }
    }
}
