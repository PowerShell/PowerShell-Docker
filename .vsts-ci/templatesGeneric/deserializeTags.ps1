$json = Get-ChildItem "${ENV:PIPELINE_WORKSPACE}/releaseTags.json" -recurse -File
if ($json.Count -ge 1) {
    $jsonText = Get-Content -Raw -Path $json.FullName
    $releaseTags = $jsonText | ConvertFrom-Json
    Write-Verbose 'got json' -verbose
    $releaseTagNames = $releaseTags | Get-Member -Type NoteProperty | Select-Object -ExpandProperty name
    Write-Verbose "got names: $($releaseTagNames -join ', ')" -verbose

    foreach ($tagName in $releaseTagNames) {
        Write-Verbose "processing $tagName" -verbose
        $value = $releaseTags.$tagName
        $version = $value -replace '^v'
        $versionName = $tagName -replace 'ReleaseTag', 'Version'
        Write-Host "vso[task.setvariable variable=$tagName;]$value"
        Write-Host "##vso[task.setvariable variable=$tagName;]$value"

        $version = $value -replace '^v'
        $versionName = $tagName -replace 'ReleaseTag', 'Version'
        $message = "vso[task.setvariable variable={0};]{1}" -f $versionName, $version
        Write-verbose $message -verbose
        Write-Host "##$message"
    }
}
else {
    throw "Did not find releaseTags json"
}
