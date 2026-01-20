Import-Module "./modules/Azure-LogEntities.psm1" -Verbose
Import-Module "./modules/Connect-AzurePortal.psm1" -Verbose
Import-Module "./modules/Find-ProductOrdersAndSuppliers.psm1" -Verbose
Import-Module "./modules/Invoke-Middleware.psm1" -Verbose
Import-Module "./modules/Log-Report.psm1" -Verbose
Import-Module "./modules/ResourceGroups.psm1" -Verbose
Import-Module "./modules/Save-Files.psm1" -Verbose

Import-Module -Name ImportExcel -Verbose

if (Get-Module -ListAvailable -Name ImportExcel) {
    Write-Host "ImportExcel is installed." -ForegroundColor Green
}
else {
    Write-Host "ImportExcel is NOT installed." -ForegroundColor Red
}

$configFilePath = Get-ChildItem -Path "./config.vale.json"
if ((Test-Path -Path $configFilePath) -eq $false) {
    throw "Config file not found in the path: $($configFilePath). Please, create a config.json file with the necessary configurations!"
}

$globalConfigs = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

##TODO: add if to verify modules/dependencies!!

Connect-AzurePortal -AzureSubscriptionId $globalConfigs.AzSubscriptionId -UseWamLogin | Out-Null

$resourceGroup = Select-PortalAzureResourceGroup -SubscriptionId $globalConfigs.AzSubscriptionId -ResourceGroupName $globalConfigs.AzResourceGroupName
# $resourceGroup = Select-PortalAzureResourceGroup -SubscriptionId $globalConfigs.AzSubscriptionId

$InsightsWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroup.ResourceGroupName
$WorkspaceId = $InsightsWorkspaces.CustomerId.ToString()

$syncedEntities = Get-AllSyncedEntities -WorkspaceId $WorkspaceId

$reprocessing = Sync-LocallyLogReport -WorkspaceId $WorkspaceId -SyncedEntities $syncedEntities

if ($null -eq $reprocessing.suppliers -or $reprocessing.suppliers.Count -le 0) {
    Write-Warning "No suppliers found in error logs to reprocess!"
    continue
}
else {
    Invoke-MiddlewareTriggerCancellation -FunctionAppName $globalConfigs.logsFromEnvironment -Code $globalConfigs.middlewareInvocationCodeAuth | Out-Null

    Invoke-SupplierMiddlewareTrigger -FunctionAppName $globalConfigs.logsFromEnvironment -Code $globalConfigs.middlewareInvocationCodeAuth -Suppliers $reprocessing.suppliers | Out-Null
    
    $waitTime = $reprocessing.suppliers.Count * 3
    Write-Host "Waiting for $waitTime seconds to allow the middleware to process the suppliers..." -ForegroundColor Yellow
    Start-Sleep -Seconds $waitTime
    
    Invoke-ProductOrderMiddlewareTrigger -FunctionAppName $globalConfigs.logsFromEnvironment -Code $globalConfigs.middlewareInvocationCodeAuth -ProductOrders $reprocessing.productOrders | Out-Null
}

