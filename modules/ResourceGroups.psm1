function Get-PortalAzureResourceGroup {
    param (
        [string]$SubscriptionId,
        [string]$ResourceGroupName
    )

    $resourceGroupsAvailables = Get-AzResourceGroup

    if ($resourceGroupsAvailables.Count -le 0) {
        throw "Resource Groups Not Found! Enter or select another account in Azure Portal!"
    }

    0..($resourceGroupsAvailables.Count - 1) | ForEach-Object { $resourceGroupsAvailables[$_] | Add-Member -MemberType NoteProperty -Name Id -Value $_ }
    
    return $resourceGroupsAvailables

}

function Select-PortalAzureResourceGroup {
    param (
        [string]$SubscriptionId,
        [string]$ResourceGroupName
    )

    if ([string]::IsNullOrEmpty($ResourceGroupName)) {

        Write-Host "You don't configurated a Resource Group name, please select one from the list below:" -ForegroundColor Yellow

        $resourceGroupsAvailables = Get-PortalAzureResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName

        $resourceGroupsAvailables | Format-Table -Property Id, ResourceGroupName, Location, ProvisioningState, Tags | Out-Host

        $selectedResourceGroup = Read-Host "Select the Resource Group that you want by 'Id'"

        $isValidRgSelection = ($selectedResourceGroup -gt 0) -and ($selectedResourceGroup -le $resourceGroupsAvailables.Count)
        
        while ($isValidRgSelection -eq $false) {
            Write-Host "Not valid resource group selected!"
            $selectedResourceGroup = Read-Host "Select again the Resource Group that you want by 'Id'"
            $isValidRgSelection = ($selectedResourceGroup -gt 0) -and ($selectedResourceGroup -le $resourceGroupsAvailables.Count - 1)
        }

        return $resourceGroupsAvailables[$selectedResourceGroup]
    }

    $resourceGroupsAvailables = Get-PortalAzureResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName

    if ($resourceGroupsAvailables.Count -le 0) {
        throw "No Resource Groups Not Found! Enter or select another account in Azure Portal!"
    }

    $selectedResourceGroup = $resourceGroupsAvailables | Where-Object { $_.ResourceGroupName.ToLower().Contains($ResourceGroupName.ToLower()) } | Select-Object -First 1

    if ($null -ne $selectedResourceGroup) {
        Write-Host "Selected Resource Group: $($selectedResourceGroup.ResourceGroupName)" -ForegroundColor Green
        return $selectedResourceGroup
    } 

    throw "Resource Group '$ResourceGroupName' Not Found! Enter or select another Resource Group in Azure Portal!"
}