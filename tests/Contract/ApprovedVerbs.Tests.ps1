BeforeAll {
    $script:RuntimeRoot = Join-Path $PSScriptRoot '..\..\runtime'
    $script:ApprovedVerbs = (Get-Verb).Verb
}

Describe 'Approved-verb contract: every function filename uses a Get-Verb verb' {

    It 'uses only approved verbs in the runtime module' {
        $files = Get-ChildItem -Path $script:RuntimeRoot -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
        $violations = @()

        foreach ($file in $files) {
            if ($file.BaseName -notmatch '^([A-Za-z]+)-\w+$') {
                $violations += "$($file.Name): filename is not Verb-Noun shaped"
                continue
            }
            $verb = $Matches[1]
            if ($verb -notin $script:ApprovedVerbs) {
                $violations += "$($file.Name): verb '$verb' is not an approved PowerShell verb"
            }
        }

        $violations | Should -BeNullOrEmpty
    }
}
