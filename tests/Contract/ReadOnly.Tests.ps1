BeforeAll {
    # A docstring that explains a property's relationship to Set-MgUserLicense/Set-Mailbox
    # parameters is documentation, not a mutation call. Strip comments before scanning.
    function script:Remove-PowerShellComment {
        param([string]$Content)
        $noBlockComments = [regex]::Replace($Content, '(?s)<#.*?#>', '')
        [regex]::Replace($noBlockComments, '(?m)#.*$', '')
    }

    $script:RuntimeRoot = Join-Path $PSScriptRoot '..\..\runtime'

    # Exchange/Graph-shaped mutation cmdlet names. Mirrors /safety-scan's mandate:
    # Set-\w+|New-\w+|Remove-\w+|Enable-\w+|Disable-\w+, filtered to cmdlets that look
    # like they mutate Exchange, Graph, or Entra ID state (not every New-/Set- named
    # function -- e.g. New-Object or New-Item are unrelated). Runtime code must never call
    # these. The explicit named entries duplicate some of the regexes below on purpose --
    # CLAUDE.md calls these out by name as the ones most likely to be reached for by
    # mistake (Remove-MgGroupMemberByRef/Remove-MgUserMemberOf especially, since neither
    # name mentions "licence" even though removing a group member revokes a
    # group-assigned one).
    $script:MutationCmdlets = @(
        'Set-Mailbox', 'Set-CASMailbox', 'New-Mailbox', 'Remove-Mailbox', 'Enable-Mailbox', 'Disable-Mailbox',
        'Set-MgUserLicense', 'Set-MsolUserLicense', 'Set-AzureADUserLicense', 'Update-MgUser',
        'Remove-MgGroupMemberByRef', 'Remove-MgUserMemberOf',
        'New-Mg[A-Z]\w*', 'Update-Mg[A-Z]\w*', 'Remove-Mg[A-Z]\w*', 'Set-Mg[A-Z]\w*',
        'New-ServicePrincipal', 'Add-RoleGroupMember'
    )

    # Path-prefix allowlist, not a filename allowlist -- scoped to a directory that
    # doesn't exist yet, so this carve-out has nothing real to hide behind until
    # Private/Adapters/ lands. The ONE confirmed exception to the read-only rule is
    # Autotask ticket creation (one ticket per client tenant); this exists solely so that
    # future adapter isn't blocked by the filename-verb-prefix check below. It must never
    # widen to cover an Exchange/Graph mutation -- see the guard test at the bottom.
    $script:MutationVerbPrefixExemptPaths = @(
        'Private\Adapters\*Autotask*.ps1'
    )
}

Describe 'Read-only contract: runtime/ never calls a mutation cmdlet' {

    It 'has runtime files to check' {
        $files = Get-ChildItem -Path $script:RuntimeRoot -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
        $files.Count | Should -BeGreaterThan 0
    }

    It 'contains no Exchange/Graph/Entra mutation cmdlet anywhere under runtime/' {
        $files = Get-ChildItem -Path $script:RuntimeRoot -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
        $violations = @()

        foreach ($file in $files) {
            $content = Remove-PowerShellComment -Content (Get-Content -Path $file.FullName -Raw)
            foreach ($cmdlet in $script:MutationCmdlets) {
                if ($content -match "\b$cmdlet\b") {
                    $violations += "$($file.Name): matched mutation cmdlet pattern '$cmdlet'"
                }
            }
        }

        $violations | Should -BeNullOrEmpty -Because 'the production runtime is read-only against Exchange Online, Microsoft Graph, and Entra ID -- the one confirmed exception is Autotask ticket creation, which never needs any of these cmdlets'
    }

    It 'defines no runtime function with a mutation-verb prefix, except the confirmed Autotask ticket-creation adapter' {
        $files = Get-ChildItem -Path $script:RuntimeRoot -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
        $violations = @()

        foreach ($file in $files) {
            if ($file.BaseName -match '^(Set|New|Remove|Enable|Disable)-') {
                $relativePath = $file.FullName.Substring($script:RuntimeRoot.Length).TrimStart('\', '/')
                $isExempt = @($script:MutationVerbPrefixExemptPaths | Where-Object { $relativePath -like $_ }).Count -gt 0
                if (-not $isExempt) {
                    $violations += $file.Name
                }
            }
        }

        $violations | Should -BeNullOrEmpty -Because 'no runtime function should be named with a mutation verb, except the one confirmed intentional mutation this runtime performs (Autotask ticket creation) -- it keeps /safety-scan''s grep output reviewable instead of full of false positives'
    }

    It 'never widens the mutation-verb-prefix exemption beyond the confirmed Autotask adapter' {
        foreach ($pattern in $script:MutationVerbPrefixExemptPaths) {
            $pattern | Should -Match '^Private\\Adapters\\.*Autotask.*\.ps1$' -Because 'the only confirmed mutation exception is the Autotask ticket-creation adapter -- this allowlist must never grow to cover an Exchange/Graph/Entra mutation by accident'
        }
    }
}
