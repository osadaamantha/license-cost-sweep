@{
    RootModule        = 'LicenseCostSweep.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a7d4e1c2-9f3b-4c8a-b6d5-2e8f1a4c7b90'
    Author            = 'MSP Blueshift'
    CompanyName       = 'MSP Blueshift'
    Copyright         = '(c) MSP Blueshift'
    Description       = 'Read-only multi-tenant M365 licence-waste audit.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')

    # Deliberately empty: Graph/EXO/ImportExcel are declared in the container image and
    # checked at startup by Assert-RuntimeModule, not here. Declaring them here would stop
    # the module importing on a workstation that lacks them, which would block offline
    # testing of the pure business-rule core.
    RequiredModules   = @()

    FunctionsToExport = @(
        'Invoke-LicenseCostSweepRun'
        'Invoke-TenantSweep'
        'Get-LicenseCostSweepConfiguration'
        'Export-LicenseCostSweepWorkbook'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @('LicenseCostSweep', 'MicrosoftGraph', 'ExchangeOnline', 'ReadOnly')
        }
    }
}
