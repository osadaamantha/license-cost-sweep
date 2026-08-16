function Export-LicenseCostSweepWorkbook {
    <#
        .SYNOPSIS
        Writes one client tenant's findings to an Excel workbook.

        .DESCRIPTION
        Not implemented yet. Adapter/orchestration wiring lands in a later pass; this
        pass only locks the parameter signature, which is deliberately kept to these two
        parameters so the function's contract stays honest -- one tenant's findings in,
        one file out, never two tenants combined.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TenantFindings,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    throw [System.NotImplementedException]::new('Export-LicenseCostSweepWorkbook is not implemented yet -- adapter/orchestration wiring lands in a later pass.')
}
