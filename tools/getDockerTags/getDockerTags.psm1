# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# function to deal with pagination
# which does not happen according to spec'ed behavior
function Get-DockerTagsList
{
    param(
        [string] $Url,
        [ValidateSet('name', 'tags')]
        [string] $PropertyName
    )

    try{
        $nextUrl = $Url
        while($nextUrl)
        {
            $results = Invoke-RestMethod $nextUrl
            if($results.results)
            {
                $results.results.$PropertyName | ForEach-Object {Write-Output $_}
                $nextUrl=$results.next
            }
            elseif($results.$PropertyName)
            {
                $results.$propertyName | ForEach-Object {Write-Output $_}
                $nextUrl = $null
            }
        }
    }
    catch
    {
        throw "$_ retrieving '$Url'; nextUrl = $nextUrl"
    }
}

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
        $mcrImage = $Image -replace 'mcr\.microsoft\.com', ''
        $tags = Get-DockerTagsList "https://mcr.microsoft.com/v2/$mcrImage/tags/list" -PropertyName tags
    }
    else {
        $tags = Get-DockerTagsList "https://registry.hub.docker.com/v2/repositories/library/$Image/tags/" -PropertyName name
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
