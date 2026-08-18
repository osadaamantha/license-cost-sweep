BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicenseCostSweepConfiguration' {

    It 'throws when the adapter does not provide GetConfigRows as a scriptblock' {
        {
            Get-LicenseCostSweepConfiguration -Adapter @{}
        } | Should -Throw 'Get-LicenseCostSweepConfiguration requires an adapter set with a GetConfigRows scriptblock.'
    }

    It 'returns only enabled tenant configs, preserving workbook order among enabled rows' {
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
                        TenantId         = 'tenant-c'
                        TenantDomain     = 'wingtip.example'
                        ReportRecipients = 'ops@example.com, client@example.com'
                    }
                )
            }
        }

        $result = Get-LicenseCostSweepConfiguration -Adapter $adapter

        @($result).Count | Should -Be 2
        $result[0].TenantId | Should -Be 'tenant-a'
        $result[1].TenantId | Should -Be 'tenant-c'
        $result[0].Enabled | Should -Be $true
        $result[1].Enabled | Should -Be $true
        $result[1].ReportRecipients | Should -Be @('ops@example.com', 'client@example.com')
    }

    It 'returns an empty array when the adapter returns no rows' {
        $adapter = @{
            GetConfigRows = { @() }
        }

        $result = Get-LicenseCostSweepConfiguration -Adapter $adapter

        @($result).Count | Should -Be 0
    }

    It 'bubbles row validation failures from ConvertTo-LicTenantConfig' {
        $adapter = @{
            GetConfigRows = {
                @(
                    @{
                        TenantDomain = 'contoso.example'
                    }
                )
            }
        }

        {
            Get-LicenseCostSweepConfiguration -Adapter $adapter
        } | Should -Throw "Config workbook row is missing required column 'TenantId'"
    }
}
