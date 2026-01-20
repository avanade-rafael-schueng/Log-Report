function Invoke-SupplierMiddlewareTrigger {
    param (
        [string]$FunctionAppName,
        [string]$Code,
        [System.Collections.Generic.HashSet[Object]]$Suppliers
    )

    try {
        $_suppliers = $Suppliers -join "," 
        $uri = [System.Uri]::new("https://$($FunctionAppName).azurewebsites.net/api/TriggerManual?code=$($Code)&suppliers=$($_suppliers)")
        $uri = $uri.ToString();    
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json"
        return $response
    }
    catch {
        throw $_
    }
}

function Invoke-ProductOrderMiddlewareTrigger {
    param (
        [string]$FunctionAppName,
        [string]$Code,
        [System.Collections.Generic.HashSet[Object]]$ProductOrders
    )

    try {
        $_productOrders = $ProductOrders -join "," 
        $uri = [System.Uri]::new("https://$($FunctionAppName).azurewebsites.net/api/TriggerManual?code=$($Code)&pos=$($_productOrders)")
        $uri = $uri.ToString();    
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json"
        return $response
    }
    catch {
        throw $_
    }
}

function Invoke-MiddlewareTriggerCancellation {
    param (
        [string]$FunctionAppName,
        [string]$Code
    )

    try {
        $uri = [System.Uri]::new("https://$($FunctionAppName).azurewebsites.net/api/CancelOrchestration?code=$($Code)")
        $uri = $uri.ToString();    
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json"
        return $response
    }
    catch {
        throw $_
    }
}