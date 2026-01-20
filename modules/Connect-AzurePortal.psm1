function Connect-AzurePortal {

    param (
        [Parameter(Mandatory = $true)]
        [string]$AzureSubscriptionId,

        [Parameter(Mandatory = $false)]
        [switch]$UseWamLogin
    )

    if ($UseWamLogin -eq $true) {

        Write-Host "Using WAM Login to connect to Azure Portal..." -ForegroundColor Green

        Update-AzConfig -EnableLoginByWam $false | Out-Null

        ##2. Connect to azure
        Connect-AzAccount | Out-Null

        ##3. Set as default subscription to access the AZ portal 
        ## add the possibility to choose another one Subscription Id... You can use the Get-AzContext to find and set...

        ## Attention! to Work correctly the script, the subscription must configured with: "Set-AzContext -SubscriptionId "XXXXXXX | Out-Null"
        Set-AzContext -SubscriptionId $AzureSubscriptionId | Out-Null  
        
        return $true
    }

    Write-Host "Connecting to Azure Portal using Device Code Authentication..." -ForegroundColor Green

    $tenantId = "d64db29c-619b-40bb-ab31-1a70675dac44"
    $appId = "63ce3277-31f3-4be5-b0b3-5957fc9b16cd"
    $password = "client-secret" | ConvertTo-SecureString -AsPlainText -Force

    $cred = New-Object System.Management.Automation.PSCredential($appId, $password)

    # Conecta de forma não interativa
    Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $tenantId

    return $true
}