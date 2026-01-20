function Get-AllSyncedEntities {
    param (
        [string]$WorkspaceId,
        [int]$PastDays = 1
    )

    if (($null -ne $globalConfigs.pastLogDays) -and ($globalConfigs.pastLogDays -gt 0)) {
        $PastDays = $globalConfigs.pastLogDays
    }

    #TODO: Add past days arg support!

    $todayDate = [datetime]::now.AddDays(1).ToString("yyyy-MM-dd");

    $pastDate = [datetime]::now.AddDays(($PastDays * -1)).ToString("yyyy-MM-dd");

    $KqlQuery = @"
    AppRequests 
    | where TimeGenerated >= date($pastDate) and TimeGenerated < datetime($todayDate)
    | where Name == "SyncEntities"
    | where AppRoleName == '$($globalConfigs.logsFromEnvironment)'
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

    $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery

    if ($null -eq $query) {
        $query = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $KqlQuery -Debug
    }

    return $query.Results;
}

function Get-AllLogsFromSyncedEntities {
    param (
        [string]$WorkspaceId,
        [string]$OperationId,
        [string]$InvocationId,
        [Int]$PastDays = 1
    )

    if (($null -ne $globalConfigs.pastLogDays) -and ($globalConfigs.pastLogDays -gt 0)) {
        $PastDays = $globalConfigs.pastLogDays
    }

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