# Copyright (c) Microsoft Corporation.
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
        [string[]] $ShortTag
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

    return $results
}

class UpstreamDockerTagData
{
    [string] $Type
    [string] $Tag
    [string] $FromTag
}

Export-ModuleMember -Function @(
    'Get-DockerTagsList'
    'Get-DockerTagList'
)
