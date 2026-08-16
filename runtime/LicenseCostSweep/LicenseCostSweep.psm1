Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot

# Load order matters only in that Private must be fully available before Public.
# Within Private, load order does not matter: functions dot-source into the module
# scope and PowerShell resolves calls at invocation time, not at parse time.
$privateFiles = Get-ChildItem -Path (Join-Path $root 'Private') -Filter '*.ps1' -Recurse -File
$publicFiles = Get-ChildItem -Path (Join-Path $root 'Public') -Filter '*.ps1' -Recurse -File

foreach ($file in $privateFiles) {
    . $file.FullName
}
foreach ($file in $publicFiles) {
    . $file.FullName
}

Export-ModuleMember -Function $publicFiles.BaseName
