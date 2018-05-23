$shortTags = @('1709','1803')
$results = @()
$tags = Invoke-RestMethod https://registry.hub.docker.com/v1/repositories/microsoft/nanoserver/tags
foreach($shortTag in $shortTags)
{
    $fullTag = $tags | 
        Where-Object{$_.name -like "${shortTag}*"} |
            Where-Object{$_.name -match '\d{4}_KB\d{7}'} | 
                Sort-Object -Descending -Property name | 
                    Select-Object -ExpandProperty name -First 1 

    $results += [PSCustomObject] @{
        Type = 'Short'
        Tag = $shortTag
        FromTag = $fullTag
    }
    $results += [PSCustomObject] @{
        Type = 'Full'
        Tag = $fullTag
        FromTag = $fullTag
    }
}

return $results