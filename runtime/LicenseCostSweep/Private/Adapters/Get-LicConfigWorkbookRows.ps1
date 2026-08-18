function Get-LicConfigWorkbookRows {
    <#
        .SYNOPSIS
        Retry-wrapped download and local parse of the per-tenant config workbook's
        rows.

        .DESCRIPTION
        The config workbook is treated as a real .xlsx hosted on SharePoint Online, not
        a Graph Workbook REST surface. Following the sibling mailbox-audit-sweep
        pattern, this downloads the raw file bytes through Graph's plain file-content
        endpoint, then parses locally with Import-Excel. That keeps the read path on a
        well-documented app-only permission model instead of relying on workbook APIs
        whose application-permission coverage is less clear.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$SiteId,

        [Parameter(Mandatory)]
        [string]$DriveItemPath
    )

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString() + '.xlsx')

    try {
        $uri = "/v1.0/sites/$SiteId/drive/root:${DriveItemPath}:/content"

        Invoke-WithRetry -OperationName 'Get-LicConfigWorkbookRows' -ScriptBlock {
            Invoke-MgGraphRequest -Method GET -Uri $uri -OutputFilePath $tempPath
        }

        @(Import-Excel -Path $tempPath)
    }
    finally {
        Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    }
}
