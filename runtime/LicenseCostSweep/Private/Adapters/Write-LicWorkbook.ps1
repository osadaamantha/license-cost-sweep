function Write-LicWorkbook {
    <#
        .SYNOPSIS
        Writes a shaped workbook payload to a local .xlsx file.

        .DESCRIPTION
        Not implemented yet. Export-LicenseCostSweepWorkbook already shapes the payload;
        this adapter will become the ImportExcel-backed file writer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$WorkbookPayload
    )

    throw [System.NotImplementedException]::new('Write-LicWorkbook is not implemented yet.')
}
