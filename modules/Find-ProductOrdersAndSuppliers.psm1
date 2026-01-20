function Find-ProductOrderOrSupplierNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Line,
        [switch]$Order,
        [switch]$Supplier
    )

    $_matches = $Line | Select-String -Pattern "(order|supplier)\s?\:?\d+" -AllMatches
    if ($_matches.Matches.Count -gt 0) {
        if ($Order) {
            $orderNumber = $_matches.Matches.Where({ $_.Value.ToLower().Contains("order") })?.Value.Split(" ")[1];
            return $orderNumber
        }
        if ($Supplier) {
            $number = $_matches.Matches.Where({ $_.Value.ToLower().Contains("supplier") })?.Value.Split(" ")[1];
            return $number
        }
    }
    return $null
}


function Find-SkippedProductOrder {
    param (
        $Logs
    )
    
    if ($null -ne $Logs) {
        $skippedLogs = $Logs | Where-Object { ($_."Message" -imatch "skipping.*|\:\s?skip.*") }
        return $skippedLogs
    }

    Write-Warning "The Logs argument is null!"
    return $null

}