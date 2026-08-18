function Get-LicTenantEvidence {
    <#
        .SYNOPSIS
        Collects and normalizes one tenant's evidence into the shape
        Invoke-TenantSweep consumes.

        .DESCRIPTION
        This is the contract boundary between raw collection and the pure business-rule
        core. Tests and offline replay can inject collector scriptblocks through
        -Adapter; production resolves the real collector set when -Adapter is absent.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [datetime]$AsOfUtc,

        [Parameter(Mandatory)]
        [string]$RunId

        ,

        [hashtable]$Adapter
    )

    function Get-LicProp {
        param([object]$Obj, [string]$Name, $Default = $null)
        if ($null -eq $Obj) { return $Default }
        if ($Obj -is [hashtable]) {
            if ($Obj.ContainsKey($Name)) { return $Obj[$Name] }
            return $Default
        }
        $prop = $Obj.PSObject.Properties[$Name]
        if ($null -eq $prop) { return $Default }
        return $prop.Value
    }

    $collectors = if ($Adapter) {
        $Adapter
    }
    else {
        @{
            GetUsers                   = { param($TenantId) Get-LicRawUserData -TenantId $TenantId }
            GetMailboxRecipients       = { param($TenantId) Get-LicRawMailboxRecipientData -TenantId $TenantId }
            GetSignInActivity          = { param($TenantId) Get-LicRawSignInActivityData -TenantId $TenantId }
            GetPaidSkuIds              = { param($TenantId) Get-LicPaidSkuIds -TenantId $TenantId }
            GetOverlapMap              = { param($TenantId) @() }
            GetServiceAccountPredicate = { param($TenantId) $null }
        }
    }

    $requiredKeys = @('GetUsers', 'GetMailboxRecipients', 'GetSignInActivity', 'GetPaidSkuIds', 'GetOverlapMap', 'GetServiceAccountPredicate')
    foreach ($key in $requiredKeys) {
        if (-not $collectors.ContainsKey($key) -or $collectors[$key] -isnot [scriptblock]) {
            throw "Get-LicTenantEvidence requires collector '$key' as a scriptblock."
        }
    }

    $rawUsers = @(& $collectors.GetUsers $TenantId)
    $rawRecipients = @(& $collectors.GetMailboxRecipients $TenantId)
    $signInResult = & $collectors.GetSignInActivity $TenantId
    $paidSkuIds = @(& $collectors.GetPaidSkuIds $TenantId)
    $overlapMap = @(& $collectors.GetOverlapMap $TenantId)
    $serviceAccountPredicate = & $collectors.GetServiceAccountPredicate $TenantId

    $recipientById = @{}
    foreach ($recipient in $rawRecipients) {
        $recipientId = [string](Get-LicProp -Obj $recipient -Name 'ExternalDirectoryObjectId' -Default (Get-LicProp -Obj $recipient -Name 'Id' -Default ''))
        if (-not [string]::IsNullOrWhiteSpace($recipientId)) {
            $recipientById[$recipientId] = $recipient
        }
    }

    $signInById = @{}
    $signInSignalState = [string](Get-LicProp -Obj $signInResult -Name 'SignalState' -Default 'NotCollected')
    foreach ($activity in @((Get-LicProp -Obj $signInResult -Name 'Activity' -Default @()))) {
        $activityId = [string](Get-LicProp -Obj $activity -Name 'id' -Default (Get-LicProp -Obj $activity -Name 'Id' -Default ''))
        if (-not [string]::IsNullOrWhiteSpace($activityId)) {
            $signInById[$activityId] = $activity
        }
    }

    $allInputs = @()
    foreach ($rawUser in $rawUsers) {
        $userId = [string](Get-LicProp -Obj $rawUser -Name 'id' -Default (Get-LicProp -Obj $rawUser -Name 'Id' -Default ''))
        $assignedLicenses = @((Get-LicProp -Obj $rawUser -Name 'assignedLicenses' -Default @()))
        $assignedSkuIds = @(
            $assignedLicenses |
                ForEach-Object { [string](Get-LicProp -Obj $_ -Name 'skuId' -Default (Get-LicProp -Obj $_ -Name 'SkuId' -Default '')) } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $assignedPaidSkuIds = if (@($paidSkuIds).Count -gt 0) {
            @($assignedSkuIds | Where-Object { $_ -in $paidSkuIds })
        }
        else {
            $null
        }

        $recipient = if ($recipientById.ContainsKey($userId)) { $recipientById[$userId] } else { $null }
        $signInActivity = if ($signInById.ContainsKey($userId)) { $signInById[$userId] } else { $null }
        $signInDetail = Get-LicProp -Obj $signInActivity -Name 'signInActivity'
        $lastSignInRaw = Get-LicProp -Obj $signInDetail -Name 'lastSuccessfulSignInDateTime' -Default (Get-LicProp -Obj $signInDetail -Name 'LastSuccessfulSignInDateTime')
        $lastSignInDateTime = if ($lastSignInRaw) { [datetime]$lastSignInRaw } else { $null }

        $allInputs += @{
            UserObjectId             = $userId
            UserPrincipalName        = [string](Get-LicProp -Obj $rawUser -Name 'userPrincipalName' -Default (Get-LicProp -Obj $rawUser -Name 'UserPrincipalName' -Default ''))
            DisplayName              = [string](Get-LicProp -Obj $rawUser -Name 'displayName' -Default (Get-LicProp -Obj $rawUser -Name 'DisplayName' -Default ''))
            AccountEnabled           = Get-LicProp -Obj $rawUser -Name 'accountEnabled'
            AssignedPaidLicenseCount = if ($null -eq $assignedPaidSkuIds) { $null } else { @($assignedPaidSkuIds).Count }
            AssignedPaidLicenseSkus  = if ($null -eq $assignedPaidSkuIds) { @() } else { @($assignedPaidSkuIds) }
            AssignedSkuIds           = @($assignedSkuIds)
            CreatedDateTime          = Get-LicProp -Obj $rawUser -Name 'createdDateTime'
            LastSignInDateTime       = $lastSignInDateTime
            SignInSignalState        = $signInSignalState
            RecipientTypeDetails     = [string](Get-LicProp -Obj $recipient -Name 'RecipientTypeDetails' -Default 'Other')
        }
    }

    @{
        DisabledAccountInputs   = @($allInputs)
        NeverSignedInInputs     = @($allInputs)
        LicenseOverlapInputs    = @($allInputs)
        SharedMailboxInputs     = @($allInputs)
        ServiceAccountInputs    = @($allInputs)
        OverlapMap              = $overlapMap
        ServiceAccountPredicate = $serviceAccountPredicate
    }
}
