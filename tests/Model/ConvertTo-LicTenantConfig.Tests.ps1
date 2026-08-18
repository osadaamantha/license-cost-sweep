BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'ConvertTo-LicTenantConfig' {

    It 'Missing TenantId throws naming the missing column, never raw row data' {
        InModuleScope LicenseCostSweep {
            { ConvertTo-LicTenantConfig -Row @{ TenantDomain = 'contoso.example' } } |
                Should -Throw "Config workbook row is missing required column 'TenantId'"
        }
    }

    It 'Missing TenantDomain throws naming the missing column, including the already-validated TenantId' {
        InModuleScope LicenseCostSweep {
            { ConvertTo-LicTenantConfig -Row @{ TenantId = '11111111-1111-1111-1111-111111111111' } } |
                Should -Throw "Config workbook row for tenant '11111111-1111-1111-1111-111111111111' is missing required column 'TenantDomain'"
        }
    }

    It 'Blank ReportRecipients normalizes to an empty array, never a one-element empty string' {
        InModuleScope LicenseCostSweep {
            $row = @{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example'; ReportRecipients = '' }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.ReportRecipients | Should -BeOfType [array]
            $config.ReportRecipients.Count | Should -Be 0
        }
    }

    It 'Comma-separated ReportRecipients splits, trims, and filters empty entries' {
        InModuleScope LicenseCostSweep {
            $row = @{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example'; ReportRecipients = 'msp@example.com, client@contoso.example ,' }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.ReportRecipients | Should -Be @('msp@example.com', 'client@contoso.example')
        }
    }

    It 'Enabled defaults to true when the column is absent' {
        InModuleScope LicenseCostSweep {
            $config = ConvertTo-LicTenantConfig -Row @{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example' }
            $config.Enabled | Should -Be $true
        }
    }

    It 'Enabled = N (case-insensitive) -> false' -TestCases @(
        @{ EnabledRaw = 'N' }
        @{ EnabledRaw = 'n' }
    ) {
        InModuleScope LicenseCostSweep -Parameters @{ EnabledRaw = $EnabledRaw } {
            param($EnabledRaw)
            $config = ConvertTo-LicTenantConfig -Row @{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example'; Enabled = $EnabledRaw }
            $config.Enabled | Should -Be $false
        }
    }

    It 'Parses optional OverlapMapJson into validated overlap-rule entries' {
        InModuleScope LicenseCostSweep {
            $row = @{
                TenantId       = 'tenant-a'
                TenantDomain   = 'contoso.example'
                OverlapMapJson = '[{"PrimarySkuId":"sku-e5","PrerequisiteSkuId":"sku-e3","Reason":"E5SupersedesE3"}]'
            }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.OverlapMap.Count | Should -Be 1
            $config.OverlapMap[0].Reason | Should -Be 'E5SupersedesE3'
        }
    }

    It 'Invalid OverlapMapJson throws naming the optional column' {
        InModuleScope LicenseCostSweep {
            $row = @{
                TenantId       = 'tenant-a'
                TenantDomain   = 'contoso.example'
                OverlapMapJson = '[{"PrimarySkuId":"sku-e5"}]'
            }

            { ConvertTo-LicTenantConfig -Row $row } |
                Should -Throw "Config workbook row for tenant 'tenant-a' has an invalid entry in optional column 'OverlapMapJson'"
        }
    }

    It 'Comma-separated ServiceAccountUpns splits, trims, and filters empty entries' {
        InModuleScope LicenseCostSweep {
            $row = @{
                TenantId           = 'tenant-a'
                TenantDomain       = 'contoso.example'
                ServiceAccountUpns = 'svc-backup@contoso.example, svc-sync@contoso.example ,'
            }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.ServiceAccountUpns | Should -Be @('svc-backup@contoso.example', 'svc-sync@contoso.example')
        }
    }

    It 'Accepts a PSCustomObject row shape, not just a hashtable' {
        InModuleScope LicenseCostSweep {
            $row = [PSCustomObject]@{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example'; Notes = 'demo tenant' }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.TenantId | Should -Be 'tenant-a'
            $config.Notes | Should -Be 'demo tenant'
        }
    }
}
