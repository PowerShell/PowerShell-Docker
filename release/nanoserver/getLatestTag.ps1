# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the nanoserver image on

# The versions of nanoserver we care about
$shortTags = @('1709','1803')
$results = @()

# Get all the tage
$tags = Invoke-RestMethod https://registry.hub.docker.com/v1/repositories/microsoft/nanoserver/tags

foreach($shortTag in $shortTags)
{
    # filter to tags we care about
    # then, to full tags
    # then get the newest tag
    $fullTag = $tags | 
        Where-Object{$_.name -like "${shortTag}*"} |
            Where-Object{$_.name -match '\d{4}_KB\d{7}'} | 
                Sort-Object -Descending -Property name | 
                    Select-Object -ExpandProperty name -First 1 

    # Return the short form of the tag
    $results += [PSCustomObject] @{
        Type = 'Short'
        Tag = $shortTag
        FromTag = $fullTag
    }

    # Return the full form of the tag
    $results += [PSCustomObject] @{
        Type = 'Full'
        Tag = $fullTag
        FromTag = $fullTag
    }
}

return $results