function Get-LicDefaultAdapterSet {
    <#
        .SYNOPSIS
        The real production adapter set for the licence-cost-sweep runtime.

        .DESCRIPTION
        Public orchestrators resolve this set whenever their optional -Adapter
        parameter is absent. Tests and offline replay can still inject a hashtable with
        the same key contract.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    @{
        GetConfigRows    = {
            $siteId = $env:CONFIG_SITE_ID
            $driveItemPath = $env:CONFIG_DRIVE_ITEM_PATH

            if ([string]::IsNullOrWhiteSpace($siteId) -or [string]::IsNullOrWhiteSpace($driveItemPath)) {
                throw 'CONFIG_SITE_ID/CONFIG_DRIVE_ITEM_PATH are not set -- cannot reach the primary config workbook.'
            }

            Get-LicConfigWorkbookRows -SiteId $siteId -DriveItemPath $driveItemPath
        }
        GetTenantEvidence = {
            param($TenantId, $AsOfUtc, $RunId)
            Get-LicTenantEvidence -TenantId $TenantId -AsOfUtc $AsOfUtc -RunId $RunId
        }
        WriteWorkbook    = {
            param($WorkbookPayload)
            Write-LicWorkbook -WorkbookPayload $WorkbookPayload
        }
    }
}
