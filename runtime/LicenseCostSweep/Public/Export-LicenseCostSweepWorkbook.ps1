function Export-LicenseCostSweepWorkbook {
    <#
        .SYNOPSIS
        Writes one client tenant's findings to an Excel workbook.

        .DESCRIPTION
        Adapter-driven tenant workbook orchestrator. Shapes one tenant's findings into
        the workbook layout contract, then delegates the actual file write to an
        injected adapter. -Adapter exists for test/replay injection only -- production
        call paths never pass it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TenantFindings,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [hashtable]$Adapter
    )

    if ($null -eq $Adapter -or -not $Adapter.ContainsKey('WriteWorkbook') -or $Adapter.WriteWorkbook -isnot [scriptblock]) {
        throw "Export-LicenseCostSweepWorkbook requires -Adapter with a WriteWorkbook scriptblock."
    }

    $layout = Get-WorkbookLayout

    $runSummaryRows = @(
        @{
            Metric = 'TenantId'
            Value  = [string]$TenantFindings.TenantId
            Detail = 'Tenant included in this workbook'
        }
        @{
            Metric = 'RunId'
            Value  = [string]$TenantFindings.RunId
            Detail = 'Shared run identifier for this sweep execution'
        }
        @{
            Metric = 'AsOfUtc'
            Value  = if ($TenantFindings.AsOfUtc) { Get-UtcTimestamp -DateTime ([datetime]$TenantFindings.AsOfUtc) } else { '' }
            Detail = 'Evaluation timestamp for these findings'
        }
        @{
            Metric = 'DisabledAccountFindingCount'
            Value  = [int]$TenantFindings.Summary.DisabledAccountFindingCount
            Detail = 'Disabled accounts with paid licences or unknown evidence'
        }
        @{
            Metric = 'NeverSignedInFindingCount'
            Value  = [int]$TenantFindings.Summary.NeverSignedInFindingCount
            Detail = 'Never-signed-in or unknown sign-in evidence findings'
        }
        @{
            Metric = 'DuplicateOverlapFindingCount'
            Value  = [int]$TenantFindings.Summary.DuplicateOverlapFindingCount
            Detail = 'Duplicate or overlapping licence findings'
        }
        @{
            Metric = 'SharedMailboxReviewFindingCount'
            Value  = [int]$TenantFindings.Summary.SharedMailboxReviewFindingCount
            Detail = 'Shared mailboxes requiring manual review'
        }
        @{
            Metric = 'ServiceAccountFindingCount'
            Value  = [int]$TenantFindings.Summary.ServiceAccountFindingCount
            Detail = 'Service or automation account findings'
        }
        @{
            Metric = 'ErrorCount'
            Value  = [int]$TenantFindings.Summary.ErrorCount
            Detail = 'Errors and unknowns captured during this tenant sweep'
        }
    )

    $workbookPayload = @{
        OutputPath = $OutputPath
        Sheets     = @(
            @{
                Key      = 'RunSummary'
                Name     = $layout.RunSummary.SheetName
                Columns  = $layout.RunSummary.Columns
                Widths   = $layout.RunSummary.Widths
                Rows     = $runSummaryRows
            }
            @{
                Key      = 'DisabledAccountFindings'
                Name     = $layout.DisabledAccountFindings.SheetName
                Columns  = $layout.DisabledAccountFindings.Columns
                Widths   = $layout.DisabledAccountFindings.Widths
                Rows     = @($TenantFindings.DisabledAccountFindings)
            }
            @{
                Key      = 'NeverSignedInFindings'
                Name     = $layout.NeverSignedInFindings.SheetName
                Columns  = $layout.NeverSignedInFindings.Columns
                Widths   = $layout.NeverSignedInFindings.Widths
                Rows     = @($TenantFindings.NeverSignedInFindings)
            }
            @{
                Key      = 'DuplicateOverlapFindings'
                Name     = $layout.DuplicateOverlapFindings.SheetName
                Columns  = $layout.DuplicateOverlapFindings.Columns
                Widths   = $layout.DuplicateOverlapFindings.Widths
                Rows     = @($TenantFindings.DuplicateOverlapFindings)
            }
            @{
                Key      = 'SharedMailboxReviewFindings'
                Name     = $layout.SharedMailboxReviewFindings.SheetName
                Columns  = $layout.SharedMailboxReviewFindings.Columns
                Widths   = $layout.SharedMailboxReviewFindings.Widths
                Rows     = @($TenantFindings.SharedMailboxReviewFindings)
            }
            @{
                Key      = 'ServiceAccountFindings'
                Name     = $layout.ServiceAccountFindings.SheetName
                Columns  = $layout.ServiceAccountFindings.Columns
                Widths   = $layout.ServiceAccountFindings.Widths
                Rows     = @($TenantFindings.ServiceAccountFindings)
            }
            @{
                Key      = 'ErrorsAndUnknowns'
                Name     = $layout.ErrorsAndUnknowns.SheetName
                Columns  = $layout.ErrorsAndUnknowns.Columns
                Widths   = $layout.ErrorsAndUnknowns.Widths
                Rows     = @($TenantFindings.ErrorsAndUnknowns)
            }
        )
    }

    Write-AuditLog -Message 'Writing tenant workbook' -Data @{
        tenantId   = [string]$TenantFindings.TenantId
        outputPath = $OutputPath
        sheetCount = @($workbookPayload.Sheets).Count
    }

    & $Adapter.WriteWorkbook $workbookPayload

    return $OutputPath
}
