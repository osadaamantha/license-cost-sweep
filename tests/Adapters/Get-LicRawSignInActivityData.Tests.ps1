BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicRawSignInActivityData' {

    It 'returns SignalState Available with the collected activity on success' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{
                            id = 'user-1'
                            signInActivity = @{
                                lastSuccessfulSignInDateTime = '2026-08-01T00:00:00Z'
                            }
                        }
                    )
                }
            }

            $result = Get-LicRawSignInActivityData -TenantId 'tenant-a'

            $result.SignalState | Should -Be 'Available'
            $result.Activity.Count | Should -Be 1
        }
    }

    It 'classifies the documented missing-premium-license error as TenantLacksP1P2' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest { throw "Neither tenant is B2C or tenant doesn't have premium license." }

            $result = Get-LicRawSignInActivityData -TenantId 'tenant-a'

            $result.SignalState | Should -Be 'TenantLacksP1P2'
            $result.Activity.Count | Should -Be 0
        }
    }

    It 'classifies any other failure as PermissionDenied' {
        InModuleScope LicenseCostSweep {
            Mock Invoke-MgGraphRequest { throw 'Insufficient privileges to complete the operation.' }

            $result = Get-LicRawSignInActivityData -TenantId 'tenant-a'

            $result.SignalState | Should -Be 'PermissionDenied'
            $result.Activity.Count | Should -Be 0
        }
    }
}
