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
            Get-LicConfigWorkbookRows
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
