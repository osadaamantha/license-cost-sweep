BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicConfiguredServiceAccountPredicate' {
    It 'returns a predicate that matches explicit configured UPNs case-insensitively' {
        InModuleScope LicenseCostSweep {
            $predicate = Get-LicConfiguredServiceAccountPredicate -TenantContext @{
                ServiceAccountUpns = @('svc-backup@contoso.example')
            }

            $predicate | Should -BeOfType [scriptblock]
            (& $predicate @{ UserPrincipalName = 'SVC-BACKUP@contoso.example' }) | Should -Be $true
            (& $predicate @{ UserPrincipalName = 'user@contoso.example' }) | Should -Be $false
        }
    }

    It 'returns null when no explicit service-account UPNs are configured' {
        InModuleScope LicenseCostSweep {
            $predicate = Get-LicConfiguredServiceAccountPredicate -TenantContext @{}
            $predicate | Should -Be $null
        }
    }
}
