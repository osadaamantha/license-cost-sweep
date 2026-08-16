BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Test-LicNeverSignedIn' {

    It 'SignInSignalState not Available -> Unknown with the matching reason' -TestCases @(
        @{ SignalState = 'TenantLacksP1P2'; ExpectedReason = 'TenantLacksEntraP1P2' }
        @{ SignalState = 'PermissionDenied'; ExpectedReason = 'SignInPermissionDenied' }
        @{ SignalState = 'NotCollected'; ExpectedReason = 'SignInDataNotCollected' }
    ) {
        InModuleScope LicenseCostSweep -Parameters @{ SignalState = $SignalState; ExpectedReason = $ExpectedReason } {
            param($SignalState, $ExpectedReason)
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-1) -LastSignInDateTime $null -SignInSignalState $SignalState
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be $ExpectedReason
        }
    }

    It 'New user within grace period, null sign-in -> No/WithinNewUserGracePeriod (grace period wins over the null-ambiguity rule)' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddDays(-10) -LastSignInDateTime $null -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'WithinNewUserGracePeriod'
        }
    }

    It 'New user within grace period, recent sign-in -> No/WithinNewUserGracePeriod' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddDays(-10) -LastSignInDateTime $asOfUtc.AddDays(-2) -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'WithinNewUserGracePeriod'
        }
    }

    It 'Past grace period, null sign-in -> Unknown/NullLastSignInAmbiguous, never asserted Yes from null alone' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $null -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'Unknown'
            $result.Reason | Should -Be 'NullLastSignInAmbiguous'
        }
    }

    It 'Past grace period, sign-in beyond threshold -> Yes/Medium/InactiveBeyondThreshold' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $asOfUtc.AddDays(-40) -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'Yes'
            $result.Severity | Should -Be 'Medium'
            $result.Reason | Should -Be 'InactiveBeyondThreshold'
        }
    }

    It 'Past grace period, sign-in within threshold -> No/RecentSignInWithinThreshold' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $asOfUtc.AddDays(-5) -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'No'
            $result.Reason | Should -Be 'RecentSignInWithinThreshold'
        }
    }

    It 'Boundary: sign-in exactly ThresholdDays ago -> Yes (>=, not >)' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddYears(-2) -LastSignInDateTime $asOfUtc.AddDays(-30) -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'Yes' -Because 'the threshold comparison is inclusive'
        }
    }

    It 'Boundary: created exactly ThresholdDays ago -> grace period no longer applies' {
        InModuleScope LicenseCostSweep {
            $asOfUtc = [datetime]::Parse('2026-08-16T00:00:00Z').ToUniversalTime()
            $result = Test-LicNeverSignedIn -AsOfUtc $asOfUtc -CreatedDateTime $asOfUtc.AddDays(-30) -LastSignInDateTime $null -SignInSignalState 'Available'
            $result.Verdict | Should -Be 'Unknown' -Because 'daysSinceCreation is no longer strictly less than ThresholdDays, so the null-ambiguity rule applies instead'
            $result.Reason | Should -Be 'NullLastSignInAmbiguous'
        }
    }
}
