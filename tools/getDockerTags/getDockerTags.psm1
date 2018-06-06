# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need for a given Image
function Get-DockerTags
{
    param(
        [parameter(Mandatory)]
        [string]
        $Image,

        [parameter(Mandatory)]
        [string[]]
        $ShortTags,

        [parameter()]
        [string]
        $AlternativeShortTag,

        [parameter(Mandatory)]
        [string]
        $FullTagFilter
    )

    if($ShortTags.Count -gt 1 -and $AlternativeShortTag)
    {
        throw "-AlternativeShortTag can only be used when there is only one -ShortTag"
    }

    # The versions of nanoserver we care about
    $results = @()

    # Get all the tage
    $tags = Invoke-RestMethod "https://registry.hub.docker.com/v1/repositories/$Image/tags"
    if(!$tags)
    {
        throw 'no results'
    }

    foreach($shortTag in $ShortTags)
    {
        # filter to tags we care about
        # then, to full tags
        # then get the newest tag
        $fullTag = $tags |
            Where-Object{$_.name -like "${shortTag}*"} |
                Where-Object{$_.name -match $FullTagFilter} |
                    Sort-Object -Descending -Property name |
                        Select-Object -ExpandProperty name -First 1

        # Return the short form of the tag
        $results += [PSCustomObject] @{
            Type = 'Short'
            Tag = $shortTag
            FromTag = $fullTag
        }

        if($AlternativeShortTag)
        {
            # Return the short form of the tag
            $results += [PSCustomObject] @{
                Type = 'Short'
                Tag = $AlternativeShortTag
                FromTag = $fullTag
            }
        }

        # Return the full form of the tag
        $results += [PSCustomObject] @{
            Type = 'Full'
            Tag = $fullTag
            FromTag = $fullTag
        }
    }

    return $results
}

Export-ModuleMember -Function @( 
    'Get-DockerTags'
)
