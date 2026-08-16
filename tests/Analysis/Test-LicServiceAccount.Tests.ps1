BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Test-LicServiceAccount' {

    It 'No predicate supplied (default) -> Unknown, refusing to guess an unconfirmed heuristic' {
        InModuleScope LicenseCostSweep {
            $result = Test-LicServiceAccount -UserContext @{ UserPrincipalName = 'svc-backup@contoso.example' }
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be 'ServiceAccountHeuristicNotConfigured'
        }
    }

    It 'Predicate supplied, returns true -> Yes/Info/ServiceAccountDetected' {
        InModuleScope LicenseCostSweep {
            $predicate = { param($u) $u.UserPrincipalName -like 'svc-*' }
            $result = Test-LicServiceAccount -UserContext @{ UserPrincipalName = 'svc-backup@contoso.example' } -Predicate $predicate
            $result.Verdict | Should -Be 'Yes'
            $result.Severity | Should -Be 'Info'
            $result.Reason | Should -Be 'ServiceAccountDetected'
        }
    }

    It 'Predicate supplied, returns false -> No/NotAServiceAccount' {
        InModuleScope LicenseCostSweep {
            $predicate = { param($u) $u.UserPrincipalName -like 'svc-*' }
            $result = Test-LicServiceAccount -UserContext @{ UserPrincipalName = 'jordan.rivera@contoso.example' } -Predicate $predicate
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'NotAServiceAccount'
        }
    }

    It 'Predicate receives the exact UserContext object passed in' {
        InModuleScope LicenseCostSweep {
            $captured = $null
            $predicate = { param($u) $script:captured = $u; $true }
            $context = @{ UserPrincipalName = 'svc-reporting@contoso.example'; Marker = 'unique-token' }
            Test-LicServiceAccount -UserContext $context -Predicate $predicate | Out-Null
            $captured.Marker | Should -Be 'unique-token'
        }
    }
}
