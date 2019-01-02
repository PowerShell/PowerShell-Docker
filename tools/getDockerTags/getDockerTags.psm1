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
        $FullTagFilter,

        [Switch]
        $OnlyShortTags,

        [Switch]
        $SkipShortTagFilter,

        [switch]
        $Mcr
    )

    if($ShortTags.Count -gt 1 -and $AlternativeShortTag)
    {
        throw "-AlternativeShortTag can only be used when there is only one -ShortTag"
    }

    # The versions of nanoserver we care about
    $results = @()

    # Get all the tage
    if($Mcr.IsPresent)
    {
        $tags = Invoke-RestMethod "https://mcr.microsoft.com/v2/$Image/tags/list" | select-object -ExpandProperty tags
    }
    else {
        $tags = Invoke-RestMethod "https://registry.hub.docker.com/v1/repositories/$Image/tags" | Select-Object -ExpandProperty name
    }

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
            Where-Object{$SkipShortTagFilter.IsPresent -or $_ -like "${shortTag}*"} |
                Where-Object{$_ -match $FullTagFilter} |
                    Sort-Object -Descending |
                        Select-Object -First 1

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

        if(!$OnlyShortTags.IsPresent)
        {
            # Return the full form of the tag
            $results += [PSCustomObject] @{
                Type = 'Full'
                Tag = $fullTag
                FromTag = $fullTag
            }
        }
    }

    return $results
}

Export-ModuleMember -Function @(
    'Get-DockerTags'
)
