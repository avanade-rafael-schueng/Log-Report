Import-Module "./modules/Azure-LogEntities.psm1" -Verbose
Import-Module "./modules/Connect-AzurePortal.psm1" -Verbose
Import-Module "./modules/Find-ProductOrdersAndSuppliers.psm1" -Verbose
Import-Module "./modules/Invoke-Middleware.psm1" -Verbose
Import-Module "./modules/Log-Report.psm1" -Verbose
Import-Module "./modules/ResourceGroups.psm1" -Verbose
Import-Module "./modules/Save-Files.psm1" -Verbose

Import-Module -Name ImportExcel -Verbose

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Error "ImportExcel is no installed." 
    throw "Please, install the ImportExcel module by running: Install-Module -Name ImportExcel -Scope CurrentUser -Force"
}


$configFilePath = Get-ChildItem -Path "./config.vale.json"
if ((Test-Path -Path $configFilePath) -eq $false) {
    throw "Config file not found in the path: $($configFilePath). Please, create a config.json file with the necessary configurations!"
}

$globalConfigs = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

Connect-AzurePortal -AzureSubscriptionId $globalConfigs.AzSubscriptionId -TenantId $globalConfigs.TenantId -AppId $globalConfigs.AppId -AppSecret $globalConfigs.AppSecret | Out-Null

$resourceGroup = Select-PortalAzureResourceGroup -SubscriptionId $globalConfigs.AzSubscriptionId -ResourceGroupName $globalConfigs.AzResourceGroupName

$InsightsWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroup.ResourceGroupName
$WorkspaceId = $InsightsWorkspaces.CustomerId.ToString()

Write-Host "Using Log Analytics Workspace ID: $WorkspaceId" -ForegroundColor Cyan

$syncedEntities = Get-AllSyncedEntities -WorkspaceId $WorkspaceId -PastDays $globalConfigs.pastLogDays -Environment $globalConfigs.logsFromEnvironment

Write-Host "Total synced entities found: $($syncedEntities.Count)" -ForegroundColor Cyan

$reprocessing = Sync-LocallyLogReport -WorkspaceId $WorkspaceId -SyncedEntities $syncedEntities

if ($globalConfigs.ReprocessLogs -eq $true) {
    if ($null -eq $reprocessing.suppliers -or $reprocessing.suppliers.Count -le 0) {
        Write-Warning "No suppliers found in error logs to reprocess!"
        continue
    }
    else {
        Invoke-SupplierMiddlewareTrigger -FunctionAppName $globalConfigs.logsFromEnvironment -Code $globalConfigs.middlewareInvocationCodeAuth -Suppliers $reprocessing.suppliers | Out-Null
    
        $waitTime = $reprocessing.suppliers.Count * 5
        Write-Host "Waiting for $waitTime seconds to allow the middleware to process the suppliers..." -ForegroundColor Yellow
        Start-Sleep -Seconds $waitTime
    
        Invoke-ProductOrderMiddlewareTrigger -FunctionAppName $globalConfigs.logsFromEnvironment -Code $globalConfigs.middlewareInvocationCodeAuth -ProductOrders $reprocessing.productOrders | Out-Null
    }
}

Write-Host "Log Report process completed!" -ForegroundColor Green