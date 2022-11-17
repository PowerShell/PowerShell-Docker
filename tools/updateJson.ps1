# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

$diffFound = $false
$jsonPath = "$PSScriptRoot\..\assets\matrix.json"
$json = &"$PSScriptRoot\..\build.ps1" -GenerateMatrixJson -FullJson
$newMatrix = $json | ConvertFrom-Json
$oldMatrix = Get-Content -Raw $jsonPath | ConvertFrom-Json
$newChannels = $newMatrix | Get-Member -Type NoteProperty  | Select-Object -ExpandProperty Name | Sort-Object
$oldChannels = $oldMatrix | Get-Member -Type NoteProperty  | Select-Object -ExpandProperty Name | Sort-Object
if (Compare-Object $newChannels -DifferenceObject $oldChannels) {
    $diffFound = $true
}

if (!$diffFound) {
    foreach ($channel in $newChannels) {
        $newImages = $newMatrix.$channel
        $oldImages = $oldMatrix.$channel
        if ($newImages.Count -ne $oldImages.Count) {
            Write-Verbose -message "diff found in ${channel} image count. $($newImages.Count) : $($oldImages.Count)" -Verbose
            $diffFound = $true
            break
        }
        $newImageNames = $newImages | Select-Object -ExpandProperty JobName | Sort-Object
        foreach ($imageName in $newImageNames) {
            Write-Verbose -Message "Checking ${channel}/$($imageName)" -Verbose
            $newImage = $newImages | Where-Object { $_.JobName -eq $imageName }
            $oldImage = $oldImages | Where-Object { $_.JobName -eq $imageName }
            if (!$newImage) {
                throw "new image not found: $imageName"
            }
            $properties = $newImage | get-member -Type NoteProperty | Select-Object -ExpandProperty Name
            foreach($property in $properties) {
                if($newImage.$property -ne $oldImage.$property) {
                    Write-Verbose -Message "diff found in ${channel}/$($imageName)/$($property)" -Verbose
                    $diffFound = $true
                    break
                }
            }
            if ($diffFound) {
                Write-Verbose -Message "breaking in ${channel}/$($imageName)" -Verbose
                break
            }
        }
        if ($diffFound) {
            Write-Verbose -Message "breaking in ${channel}" -Verbose
            break
        }
    }
}

if ($diffFound) {
    Write-Verbose -message "diff found" -Verbose
    $json > $jsonPath

    $hasNode = Get-Command -Name 'node' -ErrorAction SilentlyContinue
    $hasNpx = Get-Command -Name 'npx' -ErrorAction SilentlyContinue
    if ($hasNode && $hasNpx) {
        Write-Verbose -Message "Sorting the keys of the matrix JSON..." -Verbose
        start-nativeExecution {
            npx -y json-sort-cli assets/matrix.json
        }
        Write-Verbose -Message "Sorting complete." -Verbose
    } else {
        Write-Verbose -Message "Node or npx are not available, skipping matrix JSON sorting." -Verbose
    }
}
else {
    Write-Verbose -Message "no diff found" -Verbose
}
