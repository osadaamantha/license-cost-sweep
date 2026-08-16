function Test-LicDisabledAccountLicense {
    <#
        .SYNOPSIS
        Pure: disabled account with a paid licence -> Yes/No/Unknown finding.

        .DESCRIPTION
        Missing evidence is Unknown, never inferred: a null AccountEnabled or a null
        licence count both mean "can't tell," not "assume no." Caller is responsible for
        pre-filtering AssignedPaidLicenseCount to paid SKUs only (excluding free plans
        such as a "Power Automate Free" service) before calling this -- that filtering is
        a future Adapter-layer concern, not built here. Severity is a fixed, provisional
        judgment call (High), not a confirmed scoring model.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [Nullable[bool]]$AccountEnabled,

        [Parameter(Mandatory)]
        [AllowNull()]
        [Nullable[int]]$AssignedPaidLicenseCount
    )

    if ($null -eq $AccountEnabled) {
        return @{ Verdict = 'Unknown'; Severity = 'Unknown'; Reason = 'AccountEnabledUnavailable' }
    }
    if ($null -eq $AssignedPaidLicenseCount) {
        return @{ Verdict = 'Unknown'; Severity = 'Unknown'; Reason = 'LicenseAssignmentDataUnavailable' }
    }

    if ($AccountEnabled) {
        return @{ Verdict = 'No'; Severity = 'None'; Reason = 'AccountEnabled' }
    }

    if ($AssignedPaidLicenseCount -gt 0) {
        return @{ Verdict = 'Yes'; Severity = 'High'; Reason = 'DisabledAccountHasPaidLicense' }
    }

    return @{ Verdict = 'No'; Severity = 'None'; Reason = 'DisabledAccountNoPaidLicense' }
}
