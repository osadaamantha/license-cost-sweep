function Write-AuditLog {
    <#
        .SYNOPSIS
        Single structured JSON-line logger to stdout. Container stdout is ingested by Log
        Analytics, so this is the only logging path in the module.

        .DESCRIPTION
        Every message and every value under -Data is passed through Protect-SensitiveText
        before being written. Never log user addresses, tokens, or certificate material.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Debug', 'Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [hashtable]$Data = @{}
    )

    $sanitizedData = @{}
    foreach ($key in $Data.Keys) {
        $value = $Data[$key]
        $sanitizedData[$key] = if ($value -is [string]) { Protect-SensitiveText -Text $value } else { $value }
    }

    $line = [ordered]@{
        timestamp = Get-UtcTimestamp -DateTime (Get-Date)
        level     = $Level
        message   = Protect-SensitiveText -Text $Message
        data      = $sanitizedData
    }

    ($line | ConvertTo-Json -Depth 6 -Compress) | Write-Information -InformationAction Continue
}
