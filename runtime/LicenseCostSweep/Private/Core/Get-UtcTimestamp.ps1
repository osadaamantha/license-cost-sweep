function Get-UtcTimestamp {
    <#
        .SYNOPSIS
        Single source of UTC timestamp formatting for the module.

        .DESCRIPTION
        Takes an explicit [datetime] rather than defaulting to Get-Date, so callers under
        Private/Analysis and Private/Report can format a caller-supplied instant without
        introducing an ambient clock read into pure business-rule code.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [datetime]$DateTime,

        [ValidateSet('Iso8601', 'BlobSafe')]
        [string]$Format = 'Iso8601'
    )

    $utc = $DateTime.ToUniversalTime()

    switch ($Format) {
        'Iso8601' { $utc.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture) }
        'BlobSafe' { $utc.ToString('yyyyMMddTHHmmssZ', [System.Globalization.CultureInfo]::InvariantCulture) }
    }
}
