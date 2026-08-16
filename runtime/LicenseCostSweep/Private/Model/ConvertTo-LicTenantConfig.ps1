function ConvertTo-LicTenantConfig {
    <#
        .SYNOPSIS
        Pure: one raw config-workbook row -> a validated, typed tenant-config hashtable.

        .DESCRIPTION
        Validates the two required columns (docs/config-workbook-contract.md, DRAFT)
        are present and non-empty, raising a structured error naming the missing column
        -- never raw row data, which could contain a client's report-recipient addresses
        or notes. A blank/missing ReportRecipients column normalizes to an empty array,
        never a one-element array containing an empty string.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object]$Row
    )

    function Get-LicRowProp {
        param([object]$Obj, [string]$Name, $Default = $null)
        if ($null -eq $Obj) { return $Default }
        if ($Obj -is [hashtable]) {
            if ($Obj.ContainsKey($Name)) { return $Obj[$Name] }
            return $Default
        }
        $prop = $Obj.PSObject.Properties[$Name]
        if ($null -eq $prop) { return $Default }
        return $prop.Value
    }

    function ConvertTo-LicStringList {
        param($Value)
        if ([string]::IsNullOrWhiteSpace([string]$Value)) { return @() }
        @([string]$Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }

    $tenantId = [string](Get-LicRowProp -Obj $Row -Name 'TenantId')
    if ([string]::IsNullOrWhiteSpace($tenantId)) {
        throw "Config workbook row is missing required column 'TenantId'"
    }

    $tenantDomain = [string](Get-LicRowProp -Obj $Row -Name 'TenantDomain')
    if ([string]::IsNullOrWhiteSpace($tenantDomain)) {
        throw "Config workbook row for tenant '$tenantId' is missing required column 'TenantDomain'"
    }

    $enabledRaw = [string](Get-LicRowProp -Obj $Row -Name 'Enabled' -Default 'Y')

    @{
        TenantId         = $tenantId
        TenantDomain     = $tenantDomain
        ReportRecipients = ConvertTo-LicStringList (Get-LicRowProp -Obj $Row -Name 'ReportRecipients')
        Enabled          = $enabledRaw.ToUpperInvariant() -ne 'N'
        Notes            = [string](Get-LicRowProp -Obj $Row -Name 'Notes' -Default '')
    }
}
