# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Republishes images between mcr.microsoft.com and Docker hub until mcr.microsoft.com automatically republishes to Docker hub
# This should be enabled now, but we will keep the script around until it proves reliable
param(
    $stableVersion = '6.0.4',
    $previewVersion = '6.1.0-rc.1',
    [ValidateSet('windows', 'linux')]
    $Target,
    [switch]$Push,
    $ImageName = 'powershell',
    [switch]$Images,
    [switch]$ManifestLists
)

function Get-Target {
    if (!$IsWindows -and !$IsMacOS -and !$IsLinux) {
        return 'windows'
    }
    elseif ($IsWindows) {
        return 'windows'
    }
    else {
        return 'linux'
    }
}

function Get-ImageType {
    param($tag)
    if ($tag -in ('preview', 'latest')) {
        return 'manifest'
    }
    if ($tag -like '*windowsservercore*' -or $tag -like '*nanoserver*') {
        return 'windows'
    }
    return 'linux'
}

function Write-Log {
    param($Message,
    [ValidateSet('Progress','Information')]
    [string] $Type='Progress')

    [System.ConsoleColor] $color = [System.ConsoleColor]::Green
    switch($Type)
    {
        'Information' {
            $color =  [System.ConsoleColor]::Gray
        }
    }

    Write-Host -Object $Message -ForegroundColor $color
}

if ($null -eq $Target) {
    $runtimeTarget = Get-Target
}
else {
    $runtimeTarget = $Target
}


Write-log -Message "--- processing images ---"

$tags = Invoke-RestMethod https://mcr.microsoft.com/v2/powershell/tags/list
$manifests = @()

foreach ($tag in $tags.Tags) {

    $type = Get-ImageType -tag $tag
    Write-Verbose -Message "Testing $mcrName ..."
    $mcrName = "mcr.microsoft.com/${imageName}:$tag"
    $mcrManifest = docker manifest inspect $mcrName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning -Message "$mcrName not found ..."
        continue
    }
    $manifest = $mcrManifest | ConvertFrom-Json
    if ($manifest.mediatype -eq 'application/vnd.docker.distribution.manifest.list.v2+json') {
        $manifests += $tag
        continue;
    }

    if ($Images.IsPresent) {
        if ($runtimeTarget -ne $type -and $type -ne 'manifest') {
            Write-Log "skipping $tag" -Type Information
            continue
        }
        $expectedVersion = $stableVersion
        if ($tag -like '*preview*') {
            $expectedVersion = $previewVersion
        }

        Write-Log "**** ${imageName}:$tag - $type - $expectedVersion ***"
        $dockerName = "microsoft/${imageName}:$tag"
        Write-Verbose -Message "Testing $dockerName ..."
        $dockerManifest = [string]::Empty
        $dockerManifest = docker manifest inspect $dockerName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Verbose -Message "$dockerName not found ..."
        }
        
        $result = Compare-Object -ReferenceObject $mcrManifest -DifferenceObject $dockerManifest
        if ($result) {
            Write-Log -Message "docker out of sync with mcr for ${imageName}:$tag ..." -Type Information
            docker pull $mcrName
            $version = &docker run $mcrName pwsh -nologo -noprofile -c '$PSVersionTable.PSVersion.ToString()'
            $version = $version.trim()
            if ($version -ne $expectedVersion) {
                Write-Warning "image is version: '$version', but expected '$expectedVersion'"
                continue
            }
            docker image tag $mcrName $dockerName 
        
            Write-Log -Message "docker image push $dockerName" -Type Information
            if ($Push.IsPresent) {
                docker image push $dockerName
            }
        }
    }
}

Write-log -Message "--- processing manifests ---"

if($ManifestLists.IsPresent)
{
    foreach ($tag in $manifests) {
        $type = Get-ImageType -tag $tag
        Write-Verbose -Message "Testing $mcrName ..."
        $mcrName = "mcr.microsoft.com/${imageName}:$tag"
        $mcrManifest = docker manifest inspect $mcrName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning -Message "$mcrName not found ..."
            continue
        }
        $manifest = $mcrManifest | ConvertFrom-Json
        if ($manifest.mediatype -eq 'application/vnd.docker.distribution.manifest.list.v2+json') {
            $type = 'manifest'
        }

        if ($runtimeTarget -ne $type -and $type -ne 'manifest') {
            Write-Log "skipping $tag"
            continue
        }
        $expectedVersion = $stableVersion
        if ($tag -like '*preview*') {
            $expectedVersion = $previewVersion
        }

        Write-Log "**** ${imageName}:$tag - $type - $expectedVersion ***"
        $dockerName = "microsoft/${imageName}:$tag"
        Write-Verbose -Message "Testing $dockerName ..."
        $dockerManifest = [string]::Empty
        $dockerManifest = docker manifest inspect $dockerName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Verbose -Message "$dockerName not found ..."
        }

        $result = Compare-Object -ReferenceObject $mcrManifest -DifferenceObject $dockerManifest
        if ($result) {
            Write-Log -Message "docker out of sync with mcr for ${imageName}:$tag ..." -Type Information
            if ($type -eq 'manifest') {
                $digests = $manifest.manifests.digest
                $manifestList = @()
                foreach($digest in $digests)
                {
                    $manifestList += "microsoft/${imageName}@$digest"
                }

                Write-Log -Message "docker manifest create $dockerName $manifestList" -Type Information
                docker manifest create $dockerName $manifestList
                Write-Log -Message "docker manifest inspect $dockerName" -Type Information
                docker manifest inspect $dockerName

                Write-Log -Message "docker manifest push --purge $dockerName"
                if ($Push.IsPresent) {
                    docker manifest push --purge $dockerName
                }
            }
        }
    }
}
