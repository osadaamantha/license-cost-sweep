BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicRawUserData' {

    It 'returns the collected users on a single successful page' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{
                            id                = 'user-1'
                            userPrincipalName = 'user.one@contoso.example'
                            displayName       = 'User One'
                            accountEnabled    = $true
                            createdDateTime   = '2026-01-01T00:00:00Z'
                            assignedLicenses  = @(@{ skuId = 'sku-a' })
                        }
                    )
                }
            }

            $result = Get-LicRawUserData -TenantId 'tenant-a'

            $result.Count | Should -Be 1
            $result[0].id | Should -Be 'user-1'
            $result[0].assignedLicenses.Count | Should -Be 1
            Should -Invoke Invoke-MgGraphRequest -Times 1 -ParameterFilter {
                $Uri -eq '/v1.0/users?$select=id,userPrincipalName,displayName,accountEnabled,createdDateTime,assignedLicenses&$top=999'
            }
        }
    }

    It 'follows @odata.nextLink until every page is collected' {
        InModuleScope LicenseCostSweep {
            $calls = 0
            Mock Invoke-MgGraphRequest {
                $script:calls++
                if ($script:calls -eq 1) {
                    return @{
                        value = @(
                            @{ id = 'user-1'; userPrincipalName = 'one@contoso.example'; displayName = 'One'; accountEnabled = $true; createdDateTime = '2026-01-01T00:00:00Z'; assignedLicenses = @() }
                        )
                        '@odata.nextLink' = '/v1.0/users?$skiptoken=page-2'
                    }
                }

                @{
                    value = @(
                        @{ id = 'user-2'; userPrincipalName = 'two@contoso.example'; displayName = 'Two'; accountEnabled = $false; createdDateTime = '2026-02-01T00:00:00Z'; assignedLicenses = @() }
                    )
                }
            }

            $result = Get-LicRawUserData -TenantId 'tenant-a'

            $result.Count | Should -Be 2
            $result[0].id | Should -Be 'user-1'
            $result[1].id | Should -Be 'user-2'
            Should -Invoke Invoke-MgGraphRequest -Times 2
        }
    }
}
