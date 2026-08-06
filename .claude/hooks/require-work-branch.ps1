[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$inputJson = [Console]::In.ReadToEnd()
$event = $inputJson | ConvertFrom-Json

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$git = if ($gitCommand) { $gitCommand.Source } else { 'C:\Program Files\Git\cmd\git.exe' }

$cwd = if ($event.cwd) { $event.cwd } else { (Get-Location).Path }

try {
    $branch = (& $git -C $cwd branch --show-current 2>$null).Trim()
}
catch {
    $branch = ''
}

if ([string]::IsNullOrWhiteSpace($branch)) {
    @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = 'Unable to determine the current Git branch. Create and publish a work branch before editing.' } } | ConvertTo-Json -Compress
    exit 0
}

if ($branch -in @('main', 'develop')) {
    @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = "Edits are blocked on '$branch'. Create and publish feature/<slug>, fix/<slug>, chore/<slug>, or docs/<slug> from origin/develop first (see the branch-creation skill)." } } | ConvertTo-Json -Compress
    exit 0
}

@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; additionalContext = "Current work branch: $branch" } } | ConvertTo-Json -Compress
