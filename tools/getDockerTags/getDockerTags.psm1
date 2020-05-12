# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#Requires -Version 6.2
# function to deal with pagination
# which does not happen according to spec'ed behavior
function Get-DockerTagsList
{
    param(
        [Parameter(Mandatory)]
        [string] $Url,
        [Parameter(Mandatory)]
        [ValidateSet('name', 'tags')]
        [string] $PropertyName
    )

    try{
        $nextUrl = $Url
        while($nextUrl)
        {
            $results = Invoke-RestMethod $nextUrl -MaximumRetryCount 5 -RetryIntervalSec 12
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
            else
            {
                $nextUrl = $null
            }
        }
    }
    catch
    {
        throw "$_ retrieving '$Url'; nextUrl = $nextUrl"
    }
}

function Get-DockerTagList
{
    param(
        [Parameter(Mandatory)]
        [string[]] $ShortTag,
        [Parameter(Mandatory)]
        [string] $fullTag
    )
    $results = @()

    foreach($tag in $ShortTag)
    {
        $results += [UpstreamDockerTagData] @{
            Type = 'Short'
            Tag = $tag
            FromTag = 'notUsed'
        }
    }

    # Return the full form of the tag
    $results += [UpstreamDockerTagData] @{
        Type = 'Full'
        Tag = $fullTag
        FromTag = 'notUsed'
    }

    Write-Verbose "returning $($results.count)" -Verbose

    return $results
}

class UpstreamDockerTagData
{
    [string] $Type
    [string] $Tag
    [string] $FromTag
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

    # Get all the tags
    if($Mcr.IsPresent)
    {
        $mcrImage = $Image -replace 'mcr\.microsoft\.com', ''
        $tags = Get-DockerTagsList "https://mcr.microsoft.com/v2/$mcrImage/tags/list" -PropertyName tags
    }
    else {
        if($image -match '/')
        {
            $dockerImage = $Image
        }
        else
        {
            $dockerImage = "library/$Image"
        }

        $tags = Get-DockerTagsList "https://registry.hub.docker.com/v2/repositories/$dockerImage/tags/" -PropertyName name
    }

    if(!$tags)
    {
        throw 'no results: '+$Image
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

        if($fullTag)
        {
            # Return the short form of the tag
            $results += [UpstreamDockerTagData] @{
                Type = 'Short'
                Tag = $shortTag
                FromTag = $fullTag
            }

            if($AlternativeShortTag)
            {
                # Return the short form of the tag
                $results += [UpstreamDockerTagData] @{
                    Type = 'Short'
                    Tag = $AlternativeShortTag
                    FromTag = $fullTag
                }
            }

            if(!$OnlyShortTags.IsPresent)
            {
                # Return the full form of the tag
                $results += [UpstreamDockerTagData] @{
                    Type = 'Full'
                    Tag = $fullTag
                    FromTag = $fullTag
                }
            }
        }
    }

    return $results
}

Export-ModuleMember -Function @(
    'Get-DockerTags'
    'Get-DockerTagsList'
    'Get-DockerTagList'
)
