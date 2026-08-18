BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force

    $script:FixturePath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString() + '-fixture.xlsx')
    @(
        [pscustomobject]@{ TenantId = 'tenant-a'; TenantDomain = 'a.example'; Enabled = 'Y' }
        [pscustomobject]@{ TenantId = 'tenant-b'; TenantDomain = 'b.example'; Enabled = 'N' }
    ) | Export-Excel -Path $script:FixturePath
}

AfterAll {
    Remove-Item -Path $script:FixturePath -ErrorAction SilentlyContinue
}

Describe 'Get-LicConfigWorkbookRows' {
    It 'downloads the workbook via Graph and parses it locally with Import-Excel' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest {
                param($OutputFilePath)
                Copy-Item -Path $script:FixturePath -Destination $OutputFilePath -Force
            }

            $rows = Get-LicConfigWorkbookRows -SiteId 'site-1' -DriveItemPath '/Shared Documents/config.xlsx'

            $rows.Count | Should -Be 2
            $rows[0].TenantId | Should -Be 'tenant-a'
            $rows[1].TenantId | Should -Be 'tenant-b'
            Should -Invoke Invoke-MgGraphRequest -Times 1 -ParameterFilter {
                $Uri -eq "/v1.0/sites/site-1/drive/root:/Shared Documents/config.xlsx:/content"
            }
        }
    }

    It 'cleans up the temp file after parsing' {
        InModuleScope LicenseCostSweep {
            $capturedPath = $null
            Mock Invoke-MgGraphRequest {
                param($OutputFilePath)
                $script:capturedPath = $OutputFilePath
                Copy-Item -Path $script:FixturePath -Destination $OutputFilePath -Force
            }

            Get-LicConfigWorkbookRows -SiteId 'site-1' -DriveItemPath '/Shared Documents/config.xlsx' | Out-Null

            Test-Path -Path $capturedPath | Should -Be $false
        }
    }
}
