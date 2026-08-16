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

    It 'Accepts a PSCustomObject row shape, not just a hashtable' {
        InModuleScope LicenseCostSweep {
            $row = [PSCustomObject]@{ TenantId = 'tenant-a'; TenantDomain = 'contoso.example'; Notes = 'demo tenant' }
            $config = ConvertTo-LicTenantConfig -Row $row
            $config.TenantId | Should -Be 'tenant-a'
            $config.Notes | Should -Be 'demo tenant'
        }
    }
}
