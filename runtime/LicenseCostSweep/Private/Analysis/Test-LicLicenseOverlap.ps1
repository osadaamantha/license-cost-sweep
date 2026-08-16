function Test-LicLicenseOverlap {
    <#
        .SYNOPSIS
        Pure: duplicate/overlapping licences -> Yes/No/NotApplicable finding against an
        injectable overlap map.

        .DESCRIPTION
        Which SKU pairs count as redundant is NOT yet confirmed by the stakeholder -- this
        function accepts the overlap map as data (each row: PrimarySkuId,
        PrerequisiteSkuId, Reason) and never hardcodes a guessed SKU-pair table. An empty
        map (the default) means the check simply is not configured yet, which resolves to
        NotApplicable/NoOverlapMapConfigured -- deliberately not Unknown, since Unknown is
        reserved for missing per-item evidence about a specific user, not for "this
        program-level configuration hasn't been supplied."

        Severity (Medium) is a fixed, provisional judgment call, not a confirmed scoring
        model.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string[]]$AssignedSkuIds,

        # Each row: @{ PrimarySkuId = '<guid>'; PrerequisiteSkuId = '<guid>'; Reason = '<label>' }
        [hashtable[]]$OverlapMap = @()
    )

    if ($OverlapMap.Count -eq 0) {
        return @{ Verdict = 'NotApplicable'; Severity = 'NotApplicable'; Reason = 'NoOverlapMapConfigured'; MatchedRules = @() }
    }

    $matchedRules = @(
        $OverlapMap | Where-Object {
            $AssignedSkuIds -contains $_.PrimarySkuId -and $AssignedSkuIds -contains $_.PrerequisiteSkuId
        } | ForEach-Object { $_.Reason }
    )

    if ($matchedRules.Count -gt 0) {
        return @{ Verdict = 'Yes'; Severity = 'Medium'; Reason = 'DuplicateLicenseDetected'; MatchedRules = $matchedRules }
    }

    return @{ Verdict = 'No'; Severity = 'None'; Reason = 'NoOverlapDetected'; MatchedRules = @() }
}
