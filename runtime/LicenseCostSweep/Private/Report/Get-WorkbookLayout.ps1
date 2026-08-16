function Get-WorkbookLayout {
    <#
        .SYNOPSIS
        Pure: the ordered sheet names, column headers, and explicit column widths for the
        licence-cost-sweep workbook.

        .DESCRIPTION
        Single source of truth for report shape, consumed by the (impure) writer.
        Explicit widths only -- never -AutoSize, which needs libgdiplus on Linux.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    @{
        RunSummary = @{
            SheetName = 'Run Summary'
            Columns   = @('Metric', 'Value', 'Detail')
            Widths    = @(32, 40, 60)
        }
        DisabledAccountFindings = @{
            SheetName = 'Disabled Account Findings'
            Columns   = @(
                'TenantId', 'UserObjectId', 'UserPrincipalName', 'DisplayName', 'AccountEnabled',
                'AssignedPaidLicenseCount', 'AssignedPaidLicenseSkus', 'Verdict', 'Severity', 'Reason'
            )
            Widths = @(38, 38, 34, 24, 14, 22, 40, 16, 10, 30)
        }
        NeverSignedInFindings = @{
            SheetName = 'Never Signed In Findings'
            Columns   = @(
                'TenantId', 'UserObjectId', 'UserPrincipalName', 'DisplayName', 'CreatedDateTime',
                'LastSignInDateTime', 'EntraP1P2Available', 'DaysSinceCreation', 'DaysSinceSignIn',
                'Verdict', 'Severity', 'Reason'
            )
            Widths = @(38, 38, 34, 24, 22, 22, 18, 16, 16, 16, 10, 30)
        }
        DuplicateOverlapFindings = @{
            SheetName = 'Duplicate Overlap Findings'
            Columns   = @(
                'TenantId', 'UserObjectId', 'UserPrincipalName', 'DisplayName', 'AssignedSkus',
                'OverlapMapConfigured', 'MatchedRules', 'Verdict', 'Severity', 'Reason'
            )
            Widths = @(38, 38, 34, 24, 40, 18, 50, 16, 10, 30)
        }
        SharedMailboxReviewFindings = @{
            SheetName = 'Shared Mailbox Review'
            Columns   = @(
                'TenantId', 'UserObjectId', 'UserPrincipalName', 'DisplayName', 'RecipientTypeDetails',
                'AssignedPaidLicenseCount', 'AssignedPaidLicenseSkus', 'Verdict', 'Severity', 'Reason'
            )
            Widths = @(38, 38, 34, 24, 20, 22, 40, 18, 10, 30)
        }
        ServiceAccountFindings = @{
            SheetName = 'Service Account Findings'
            Columns   = @(
                'TenantId', 'UserObjectId', 'UserPrincipalName', 'DisplayName',
                'AssignedPaidLicenseCount', 'HeuristicConfigured', 'Verdict', 'Severity', 'Reason'
            )
            Widths = @(38, 38, 34, 24, 22, 18, 16, 10, 30)
        }
        ErrorsAndUnknowns = @{
            SheetName = 'Errors and Unknowns'
            Columns   = @('Timestamp', 'TenantId', 'Stage', 'TargetId', 'Outcome', 'AttemptCount', 'ErrorType', 'ErrorMessage')
            Widths    = @(22, 38, 20, 38, 20, 12, 30, 60)
        }
    }
}
