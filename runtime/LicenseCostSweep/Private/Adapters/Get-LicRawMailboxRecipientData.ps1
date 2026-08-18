function Get-LicRawMailboxRecipientData {
    <#
        .SYNOPSIS
        Retry-wrapped Exchange mailbox read for recipient-type and directory-object
        identity data.

        .DESCRIPTION
        The current licence sweep only needs enough mailbox-side data to classify shared
        mailboxes and align Exchange objects to Graph users: ExternalDirectoryObjectId,
        PrimarySmtpAddress, DisplayName, UserPrincipalName, and RecipientTypeDetails.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    Invoke-WithRetry -OperationName 'Get-LicRawMailboxRecipientData' -ScriptBlock {
        @(
            Get-Mailbox -ResultSize Unlimited -ErrorAction Stop |
                Select-Object ExternalDirectoryObjectId, PrimarySmtpAddress, DisplayName, UserPrincipalName, RecipientTypeDetails
        )
    }
}
