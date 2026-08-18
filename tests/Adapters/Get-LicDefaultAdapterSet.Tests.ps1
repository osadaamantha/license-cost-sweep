BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicDefaultAdapterSet' {
    AfterEach {
        Remove-Item Env:\CONFIG_SITE_ID -ErrorAction SilentlyContinue
        Remove-Item Env:\CONFIG_DRIVE_ITEM_PATH -ErrorAction SilentlyContinue
    }

    It 'GetConfigRows reads CONFIG_SITE_ID and CONFIG_DRIVE_ITEM_PATH from the environment' {
        InModuleScope LicenseCostSweep {
            $env:CONFIG_SITE_ID = 'site-1'
            $env:CONFIG_DRIVE_ITEM_PATH = '/Shared Documents/license-config.xlsx'

            Mock Get-LicConfigWorkbookRows { @(@{ TenantId = 'tenant-a' }) }

            $adapter = Get-LicDefaultAdapterSet
            $rows = & $adapter.GetConfigRows

            @($rows).Count | Should -Be 1
            Should -Invoke Get-LicConfigWorkbookRows -Times 1 -ParameterFilter {
                $SiteId -eq 'site-1' -and $DriveItemPath -eq '/Shared Documents/license-config.xlsx'
            }
        }
    }

    It 'GetConfigRows throws when config workbook environment variables are unset' {
        InModuleScope LicenseCostSweep {
            $adapter = Get-LicDefaultAdapterSet

            { & $adapter.GetConfigRows } | Should -Throw 'CONFIG_SITE_ID/CONFIG_DRIVE_ITEM_PATH are not set -- cannot reach the primary config workbook.'
        }
    }
}
