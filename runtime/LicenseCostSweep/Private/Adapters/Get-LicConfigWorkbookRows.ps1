function Get-LicConfigWorkbookRows {
    <#
        .SYNOPSIS
        Reads the raw per-tenant configuration workbook rows from the real backing
        store.

        .DESCRIPTION
        Not implemented yet. This is the real production adapter behind
        Get-LicenseCostSweepConfiguration once the workbook location and auth path are
        wired in.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    throw [System.NotImplementedException]::new('Get-LicConfigWorkbookRows is not implemented yet.')
}
