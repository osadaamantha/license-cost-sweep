function Test-LicSharedMailboxLicense {
    <#
        .SYNOPSIS
        Pure: shared mailbox with a paid licence -> always a NeedsManualReview
        classification, never a Yes/No waste verdict, never an auto-exemption.

        .DESCRIPTION
        The stakeholder was explicit that this is context-dependent (some shared
        mailboxes are signed into as a way to send mail merges) -- there is no confirmed
        size/litigation-hold/archive exception rule, and none may be added without an
        explicit scope change; that possibility was already raised and confirmed wrong.
        A licensed shared mailbox therefore always resolves to NeedsManualReview, never a
        pass/fail verdict.

        Severity (Info) is a fixed, provisional judgment call, not a confirmed scoring
        model.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('SharedMailbox', 'UserMailbox', 'RoomMailbox', 'EquipmentMailbox', 'DiscoveryMailbox', 'Other')]
        [string]$RecipientTypeDetails,

        [Parameter(Mandatory)]
        [AllowNull()]
        [Nullable[int]]$AssignedPaidLicenseCount
    )

    if ($RecipientTypeDetails -ne 'SharedMailbox') {
        return @{ Verdict = 'NotApplicable'; Severity = 'NotApplicable'; Reason = 'NotASharedMailbox' }
    }

    if ($null -eq $AssignedPaidLicenseCount) {
        return @{ Verdict = 'Unknown'; Severity = 'Unknown'; Reason = 'LicenseAssignmentDataUnavailable' }
    }

    if ($AssignedPaidLicenseCount -gt 0) {
        return @{ Verdict = 'NeedsManualReview'; Severity = 'Info'; Reason = 'SharedMailboxHasPaidLicenseReviewRequired' }
    }

    return @{ Verdict = 'No'; Severity = 'None'; Reason = 'SharedMailboxNoPaidLicense' }
}
