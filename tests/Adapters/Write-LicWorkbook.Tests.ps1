BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\runtime\LicenseCostSweep\LicenseCostSweep.psd1') -Force
}

Describe 'Write-LicWorkbook' {

    It 'throws when OutputPath is missing from the workbook payload' {
        InModuleScope LicenseCostSweep {
            { Write-LicWorkbook -WorkbookPayload @{ Sheets = @() } } |
                Should -Throw 'Workbook payload is missing OutputPath.'
        }
    }

    It 'writes each sheet with the provided rows and sets explicit column widths' {
        InModuleScope LicenseCostSweep {
            Mock Export-Excel {}
            Mock Set-ExcelColumnWidth {}

            $payload = @{
                OutputPath = 'C:\temp\tenant-a.xlsx'
                Sheets = @(
                    @{
                        Name = 'Run Summary'
                        Columns = @('Metric', 'Value')
                        Widths = @(20, 30)
                        Rows = @(
                            [pscustomobject]@{ Metric = 'TenantId'; Value = 'tenant-a' }
                        )
                    }
                    @{
                        Name = 'Disabled Account Findings'
                        Columns = @('TenantId', 'Reason')
                        Widths = @(20, 40)
                        Rows = @(
                            [pscustomobject]@{ TenantId = 'tenant-a'; Reason = 'DisabledAccountHasPaidLicense' }
                        )
                    }
                )
            }

            $result = Write-LicWorkbook -WorkbookPayload $payload

            $result | Should -Be 'C:\temp\tenant-a.xlsx'
            Should -Invoke Export-Excel -Times 2
            Should -Invoke Export-Excel -Times 1 -ParameterFilter {
                $WorksheetName -eq 'Run Summary' -and $Path -eq 'C:\temp\tenant-a.xlsx'
            }
            Should -Invoke Export-Excel -Times 1 -ParameterFilter {
                $WorksheetName -eq 'Disabled Account Findings' -and $Path -eq 'C:\temp\tenant-a.xlsx'
            }
            Should -Invoke Set-ExcelColumnWidth -Times 4
        }
    }

    It 'emits a single placeholder row when a sheet has zero data rows' {
        InModuleScope LicenseCostSweep {
            Mock Export-Excel {}
            Mock Set-ExcelColumnWidth {}

            $payload = @{
                OutputPath = 'C:\temp\tenant-a.xlsx'
                Sheets = @(
                    @{
                        Name = 'Errors and Unknowns'
                        Columns = @('Timestamp', 'ErrorMessage')
                        Widths = @(20, 40)
                        Rows = @()
                    }
                )
            }

            Write-LicWorkbook -WorkbookPayload $payload | Out-Null

            Should -Invoke Export-Excel -Times 1 -ParameterFilter {
                $WorksheetName -eq 'Errors and Unknowns' -and
                $InputObject.Count -eq 1 -and
                $InputObject[0].PSObject.Properties.Name -eq @('Timestamp', 'ErrorMessage')
            }
        }
    }
}
