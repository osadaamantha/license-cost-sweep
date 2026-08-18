BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicTenantRuntimeContext' {
    AfterEach {
        Remove-Item Env:\INTEGRATION_UAMI_CLIENT_ID -ErrorAction SilentlyContinue
    }

    It 'returns the tenant config row plus shared auth metadata' {
        InModuleScope LicenseCostSweep {
            $env:INTEGRATION_UAMI_CLIENT_ID = 'uami-123'

            Mock Get-LicenseCostSweepConfiguration {
                @(
                    @{
                        TenantId         = 'tenant-a'
                        TenantDomain     = 'contoso.example'
                        ReportRecipients = @('ops@contoso.example')
                        OverlapMap       = @(@{ PrimarySkuId = 'sku-e5'; PrerequisiteSkuId = 'sku-e3'; Reason = 'E5SupersedesE3' })
                        ServiceAccountUpns = @('svc-backup@contoso.example')
                        Notes            = 'demo'
                    }
                )
            }

            $context = Get-LicTenantRuntimeContext -TenantId 'tenant-a'

            $context.TenantId | Should -Be 'tenant-a'
            $context.TenantDomain | Should -Be 'contoso.example'
            $context.ReportRecipients | Should -Be @('ops@contoso.example')
            $context.OverlapMap.Count | Should -Be 1
            $context.ServiceAccountUpns | Should -Be @('svc-backup@contoso.example')
            $context.AppId | Should -Be 'c0b73c04-cb71-4b45-ad2a-83244603b54b'
            $context.IntegrationUamiClientId | Should -Be 'uami-123'
            $context.Organization | Should -Be 'tenant-a'
        }
    }

    It 'throws when the tenant is missing from the config workbook' {
        InModuleScope LicenseCostSweep {
            $env:INTEGRATION_UAMI_CLIENT_ID = 'uami-123'
            Mock Get-LicenseCostSweepConfiguration { @() }

            { Get-LicTenantRuntimeContext -TenantId 'tenant-a' } | Should -Throw "No config-workbook entry found for tenant 'tenant-a'"
        }
    }

    It 'throws when INTEGRATION_UAMI_CLIENT_ID is unset' {
        InModuleScope LicenseCostSweep {
            Mock Get-LicenseCostSweepConfiguration {
                @(
                    @{
                        TenantId     = 'tenant-a'
                        TenantDomain = 'contoso.example'
                    }
                )
            }

            { Get-LicTenantRuntimeContext -TenantId 'tenant-a' } | Should -Throw 'INTEGRATION_UAMI_CLIENT_ID is not set -- cannot resolve the federated token identity.'
        }
    }
}
