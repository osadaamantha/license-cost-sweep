BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicPaidSkuIds' {
    AfterEach {
        Remove-Item Env:\LIC_PAID_SKU_IDS -ErrorAction SilentlyContinue
    }

    It 'returns an empty array when no paid SKU allowlist is configured' {
        InModuleScope LicenseCostSweep {
            Mock Get-LicRawSubscribedSkuData { throw 'should not be called without an allowlist' }

            $result = Get-LicPaidSkuIds -TenantId 'tenant-a'

            @($result).Count | Should -Be 0
        }
    }

    It 'returns only allowlisted SKU ids that are actually subscribed in the tenant' {
        InModuleScope LicenseCostSweep {
            $env:LIC_PAID_SKU_IDS = 'sku-a, sku-c, sku-z'
            Mock Get-LicRawSubscribedSkuData {
                @(
                    @{ skuId = 'sku-a'; skuPartNumber = 'PART_A' }
                    @{ skuId = 'sku-b'; skuPartNumber = 'PART_B' }
                    @{ skuId = 'sku-c'; skuPartNumber = 'PART_C' }
                )
            }

            $result = Get-LicPaidSkuIds -TenantId 'tenant-a'

            $result | Should -Be @('sku-a', 'sku-c')
        }
    }
}
