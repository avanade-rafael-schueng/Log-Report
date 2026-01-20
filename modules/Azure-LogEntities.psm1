function Get-AllSyncedEntities {
    param (
        [string]$WorkspaceId,
        [int]$PastDays = 1,
        [string]$Environment
    )

    if ([String]::IsNullOrEmpty($Environment)) {
        throw "Environment parameter is required to fetch synced entities."
    }

    Write-Host "Fetching all synced entities from Log Analytics Workspace for $($Environment)" -ForegroundColor Cyan

    $todayDate = [datetime]::now.AddDays(1).ToString("yyyy-MM-dd");

    $pastDate = [datetime]::now.AddDays(($PastDays * -1)).ToString("yyyy-MM-dd");

    $KqlQuery = @"
    AppRequests 
    | where TimeGenerated >= date($pastDate) and TimeGenerated < datetime($todayDate)
    | where Name == "SyncEntities"
    | where AppRoleName == '$($Environment)'
    | where Success == true
    | order by TimeGenerated desc 
    | project 
        Date = format_datetime(TimeGenerated, 'dd-MM-yyyy'),
        Time = format_datetime(TimeGenerated, 'HH:mm:ss'),
        AppRoleName,
        Name,
        Success,
        OperationId,
        Properties.['InvocationId']
"@

    $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery -Verbose

    Write-Host "Executed KQL Query to get all synced entities." -ForegroundColor Green

    if ($null -eq $query) {
        $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery -Debug
        Write-Host "Re-executed KQL Query to get all synced entities with Debug." -ForegroundColor Yellow
    }

    return $query.Results;
}

function Get-AllLogsFromSyncedEntities {
    param (
        [string]$WorkspaceId,
        [string]$OperationId,
        [string]$InvocationId,
        [Int]$PastDays = 365
    )

    $KqlQuery = @"
   union AppTraces
    | union AppExceptions
    | where TimeGenerated >= ago($($PastDays)d)
    | where OperationId == '$OperationId'
    | where Properties.['InvocationId'] == '$InvocationId'
    | order by TimeGenerated asc
    | project
        Date = format_datetime(TimeGenerated, 'dd-MM-yyyy'),
        Time = format_datetime(TimeGenerated, 'HH:mm:ss'),
        Message,
        Properties.['LogLevel'],
        SeverityLevel,
        Properties.['InvocationId']
"@

    $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery

    if ($null -eq $query) {
        $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery -Debug
    }

    return $query.Results;
}