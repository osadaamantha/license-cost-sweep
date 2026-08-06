[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$inputJson = [Console]::In.ReadToEnd()
$event = $inputJson | ConvertFrom-Json

$command = $event.tool_input.command
if ([string]::IsNullOrWhiteSpace($command)) {
    exit 0
}

function Deny([string]$reason) {
    @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Compress
    exit 0
}

# Force-push, in any form, to any branch.
if ($command -match '\bgit\s+push\b' -and $command -match '(--force(-with-lease)?\b|(?<!\S)-f(?!\S))') {
    Deny 'Force-push is blocked. If you need to synchronize a published branch, merge origin/develop into it instead of force-pushing (see branch-creation / pr-to-develop skills).'
}

# Direct push to main or develop (push to another branch's remote ref, or a bare push while sitting on one of them).
if ($command -match '\bgit\s+push\b' -and $command -match '(?<!\S)(origin\s+)?(main|develop)(?!\S)') {
    Deny "Direct push to 'main' or 'develop' is blocked. Integrate through a reviewed pull request (see pr-to-develop skill)."
}

# Branch deletion on the remote.
if ($command -match '\bgit\s+push\b.*(--delete\b|(?<!\S):(?=\S))') {
    Deny 'Deleting a remote branch is blocked here. If this is intentional, do it manually outside this session.'
}

# Destructive Azure operations that permissions alone can't express safely.
if ($command -match '\baz\s+group\s+delete\b') {
    Deny 'Resource group deletion is blocked. Roll back by redeploying a known-good image/parameter set instead (see deploy-azure-container-job skill).'
}
if ($command -match '\baz\s+keyvault\s+(delete|purge)\b') {
    Deny 'Key Vault delete/purge is blocked — the vault has purge protection enabled and this action cannot be undone for 90 days.'
}

exit 0
