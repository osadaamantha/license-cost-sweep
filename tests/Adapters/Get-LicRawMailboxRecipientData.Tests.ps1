BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Get-LicRawMailboxRecipientData' {

    It 'returns the mailbox recipient rows needed for recipient-type classification' {
        InModuleScope LicenseCostSweep {
            Mock Get-Mailbox {
                @(
                    [pscustomobject]@{
                        ExternalDirectoryObjectId = 'user-1'
                        PrimarySmtpAddress        = 'user.one@contoso.example'
                        DisplayName               = 'User One'
                        UserPrincipalName         = 'user.one@contoso.example'
                        RecipientTypeDetails      = 'UserMailbox'
                    }
                    [pscustomobject]@{
                        ExternalDirectoryObjectId = 'user-2'
                        PrimarySmtpAddress        = 'shared@contoso.example'
                        DisplayName               = 'Shared Mailbox'
                        UserPrincipalName         = 'shared@contoso.example'
                        RecipientTypeDetails      = 'SharedMailbox'
                    }
                )
            }

            $result = Get-LicRawMailboxRecipientData -TenantId 'tenant-a'

            $result.Count | Should -Be 2
            $result[0].ExternalDirectoryObjectId | Should -Be 'user-1'
            $result[1].RecipientTypeDetails | Should -Be 'SharedMailbox'
            Should -Invoke Get-Mailbox -Times 1 -ParameterFilter {
                $ResultSize -eq 'Unlimited'
            }
        }
    }
}
