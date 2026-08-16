function Protect-SensitiveText {
    <#
        .SYNOPSIS
        Redacts SMTP local-parts, certificate/key material, and secret-shaped substrings
        before text is written to a log or an Errors/Unknowns report row.

        .DESCRIPTION
        Graph and EXO exceptions routinely embed a user's address, and sometimes a
        request URI with a token fragment. Never emit a raw exception message.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Text
    )

    process {
        if ([string]::IsNullOrEmpty($Text)) {
            return $Text
        }

        $redacted = $Text

        # PEM / certificate blocks
        $redacted = $redacted -replace '(?s)-----BEGIN [A-Z ]+-----.*?-----END [A-Z ]+-----', '<redacted-pem>'

        # SMTP addresses: keep the domain, redact the local part.
        $redacted = $redacted -replace '(?i)\b[A-Z0-9._%+-]+@([A-Z0-9.-]+\.[A-Z]{2,})\b', '<redacted>@$1'

        # Bearer tokens / long base64-ish blobs (JWT-shaped or >=40 char base64 runs).
        $redacted = $redacted -replace '(?i)\bBearer\s+[A-Za-z0-9\-_.=]+', 'Bearer <redacted>'
        $redacted = $redacted -replace '\b[A-Za-z0-9+/]{40,}={0,2}\b', '<redacted-blob>'

        # Bare GUIDs (object ids, tenant ids, correlation ids).
        $redacted = $redacted -replace '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b', '<redacted-guid>'

        $redacted
    }
}
