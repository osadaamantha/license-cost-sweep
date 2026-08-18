function Write-LicWorkbook {
    <#
        .SYNOPSIS
        Writes a shaped workbook payload to a local .xlsx file.

        .DESCRIPTION
        ImportExcel-backed file writer. Export-LicenseCostSweepWorkbook shapes the
        workbook payload; this adapter is responsible only for materializing it to one
        local .xlsx file with explicit column widths and one worksheet per payload
        entry.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$WorkbookPayload
    )

    $outputPath = [string]$WorkbookPayload.OutputPath
    $sheets = @($WorkbookPayload.Sheets)

    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        throw 'Workbook payload is missing OutputPath.'
    }

    if (Test-Path -Path $outputPath) {
        Remove-Item -Path $outputPath -Force
    }

    foreach ($sheet in $sheets) {
        $rows = @($sheet.Rows)
        $columns = @($sheet.Columns)
        $widths = @($sheet.Widths)

        # Export-Excel needs at least one object to infer headers. Keep empty finding
        # categories visible by emitting a single all-null placeholder row.
        if ($rows.Count -eq 0) {
            $placeholder = [ordered]@{}
            foreach ($column in $columns) {
                $placeholder[$column] = $null
            }
            $rows = @([pscustomobject]$placeholder)
        }

        Export-Excel -Path $outputPath -WorksheetName $sheet.Name -InputObject $rows -NoAutoSize

        for ($i = 0; $i -lt $widths.Count; $i++) {
            Set-ExcelColumnWidth -Path $outputPath -WorksheetName $sheet.Name -ColumnNumber ($i + 1) -Width $widths[$i]
        }
    }

    return $outputPath
}
