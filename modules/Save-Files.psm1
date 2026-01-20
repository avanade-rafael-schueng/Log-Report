function Save-ExcelFile {
    param (
        $PathToSave,
        $Logs,
        $WorksheetName
    )

    if ($null -ne $Logs) {
        Write-Host "Writing file: $PathToSave"
        $Logs | Export-Excel -Path $PathToSave -WorksheetName $WorksheetName | Out-Null
        return $true
    }

    Write-Warning "No data to write in $($PathToSave)!"
    return $false

}

function Save-CsvLog {
    param (
        $PathToSave,
        $Logs
    )

    #TODO Add support to check if file exists and avoid overwrite or force it!
    if ($null -ne $Logs) {
        $_logs_csv = $Logs | ConvertTo-Csv
        Write-Host "Writing file: $PathToSave"
        Set-Content -Path $PathToSave -Value $_logs_csv -Force | Out-Null
        return $true
    }

    Write-Warning "No data to write in $($PathToSave)!"
    return $false

}

function Save-LogReport {
    param (
        $PathToSave,
        $TextLogReport,
        [switch]$Force
    )

    if ((Test-path -Path $PathToSave) -and -not $Force) {
        Write-Warning "The file $($PathToSave) already exists! Use -Force to overwrite it."
        return $false
    }

    #TODO Add support to check if file exists and avoid overwrite or force it!
    if ($null -ne $Logs) {
        Write-Host "Writing file: $PathToSave"
        Set-Content -Path $PathToSave -Value $TextLogReport -Force | Out-Null
        return $true
    }

    Write-Warning "No data to write in $($PathToSave)!"
    return $false

}