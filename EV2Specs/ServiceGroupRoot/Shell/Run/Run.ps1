# ensure SAS variables were passed in
if ($env:LINUX_IMAGES_TARGZIP -eq $null)
{
    Write-Verbose -Verbose "LINUX_IMAGES_TARGZIP variable didn't get passed correctly"
    return 1
}

if ($env:WINDOWS_IMAGES_TARGZIP -eq $null)
{
    Write-Verbose -Verbose "WINDOWS_IMAGES_TARGZIP variable didn't get passed correctly"
    return 1
}

if ($env:DESTINATION_ACR_NAME -eq $null)
{
    Write-Verbose -Verbose "DESTINATION_ACR_NAME variable didn't get passed correctly"
    return 1
}

if ($env:MI_CLIENTID -eq $null)
{
    Write-Verbose -Verbose "MI_CLIENTID variable didn't get passed correctly"
    return 1
}

if ($env:IMAGE_INFO_JSON -eq $null)
{
    Write-Verbose -Verbose "IMAGE_INFO_JSON variable didn't get parsed properly"
    return 1
}

if ($env:CHANNEL_INFO_JSON -eq $null)
{
    Write-Verbose -Verbose "CHANNEL_INFO_JSON variable didn't get parsed properly"
    return 1
}

try {
    Write-Verbose -Verbose "LinuxSrcFiles.tar.gz: $env:LINUX_IMAGES_TARGZIP"
    Write-Verbose -Verbose "WindowsSrcFiles.tar.gz: $env:WINDOWS_IMAGES_TARGZIP"
    Write-Verbose -Verbose "acrname: $env:DESTINATION_ACR_NAME"
    Write-Verbose -Verbose "MI client Id: $env:MI_CLIENTID"
    Write-Verbose -Verbose "imginfo: $env:IMAGE_INFO_JSON"
    Write-Verbose -Verbose "channel info file: $env:CHANNEL_INFO_JSON"

    Write-Verbose -Verbose "Download files"
    Invoke-WebRequest -Uri $env:LINUX_IMAGES_TARGZIP -OutFile LinuxSrcFiles.tar.gz
    Invoke-WebRequest -Uri $env:WINDOWS_IMAGES_TARGZIP -OutFile WindowsSrcFiles.tar.gz
    Invoke-WebRequest -Uri $env:IMAGE_INFO_JSON -OutFile ImageMetadata.json
    Invoke-WebRequest -Uri $env:CHANNEL_INFO_JSON -OutFile ChannelInfo.json

    $liunxPathToTarGz = Join-Path -Path "/package/unarchive/" -ChildPath "LinuxSrcFiles.tar.gz"
    $linuxPathToTarGzExists = Test-Path $liunxPathToTarGz
    Write-Verbose -Verbose "LinuxSrcFiles.tar.gz exists: $linuxPathToTarGzExists"

    $windowsPathToTarGz = Join-Path -Path "/package/unarchive/" -ChildPath "WindowsSrcFiles.tar.gz"
    $windowsPathToTarGzExists = Test-Path $windowsPathToTarGz
    Write-Verbose -Verbose "WindowsSrcFiles.tar.gz exists: $windowsPathToTarGzExists"

    $pathToChannelJson = Join-Path "/package/unarchive/" -ChildPath "ChannelInfo.json"
    $pathToChannelJsonExists = Test-Path $pathToChannelJson
    Write-Verbose -Verbose "ChannelInfo.json file exists: $pathToChannelJsonExists"

    $pathToImgMetadataJson = Join-Path -Path "/package/unarchive/" -ChildPath "ImageMetadata.json"
    $pathToImgMetadataJsonExists = Test-Path $pathToImgMetadataJson
    Write-Verbose -Verbose "ImageMetadata.json file exists: $pathToImgMetadataJsonExists"

    # Expected file structure:
    # images
    #   - linux
    #       - distro1
    #           - main
    #               - distro1.tar
    #           - test
    #               - distro1.tar
    #   - windows
    #       - distro2
    #           - main
    #               - distro2.tar
    #           - test
    #               - distro2.tar
    Write-Verbose -Verbose "Getting image .tar files"
    $unarchivePath = Join-Path -Path "/package" -ChildPath "unarchive"
    $unarchivePathExists = Test-Path -Path $unarchivePath
    Write-Verbose -Verbose "unarchive path exists: $unarchivePathExists"
    $imagesFolder = Join-Path -Path "/package/unarchive/" -ChildPath "images"
    New-Item -Path $imagesFolder -ItemType Directory
    $imagesFolderExists = Test-Path $imagesFolder
    Write-Verbose -Verbose "images folder exists: $imagesFolderExists"

    $linuxImagesFolder = Join-Path -Path $imagesFolder -ChildPath "linux"
    New-Item -Path $linuxImagesFolder -ItemType Directory
    $linuxFolderExists = Test-Path $linuxImagesFolder
    Write-Verbose -Verbose "linux folder exists: $linuxFolderExists"
    tar -xzvf $liunxPathToTarGz -C $linuxImagesFolder --force-local

    $windowsImagesFolder = Join-Path -Path $imagesFolder -ChildPath "windows"
    New-Item -Path $windowsImagesFolder -ItemType Directory
    $windowsFolderExists = Test-Path -Path $windowsImagesFolder
    Write-Verbose -Verbose "windows folder exists: $windowsFolderExists"
    tar -xzvf $windowsPathToTarGz -C $windowsImagesFolder --force-local

    Write-Verbose -Verbose "Login cli using managed identity"
    az login --identity --username $env:MI_CLIENTID

    Write-Verbose -Verbose "Getting ACR credentials"
    $token_query_res = az acr login -n "$env:DESTINATION_ACR_NAME" -t
    $token_query_json = $token_query_res | ConvertFrom-Json
    $token = $token_query_json.accessToken
    $destinationACR = $token_query_json.loginServer

    # Crane 0.15.2 comes installed on image, but has issue pushing foreign layers for windows containers.
    # This issue does not occur with version 0.19.0+ so we must download it.
    Write-Verbose -Verbose "Download crane version 0.19.0"
    wget -O crane.tar.gz https://github.com/google/go-containerregistry/releases/download/v0.19.1/go-containerregistry_Linux_x86_64.tar.gz
    gunzip crane.tar.gz
    tar -xvf crane.tar

    ./crane version
    ./crane auth login "$destinationACR" -u "00000000-0000-0000-0000-000000000000" -p "$token"
    Write-Verbose -Verbose "after crane auth"

    Write-Verbose -Verbose "Getting channel info"
    $channelJsonFileContent = Get-Content -Path $pathToChannelJson | ConvertFrom-Json
    $channel = $channelJsonFileContent.channel

    Write-Verbose -Verbose "Getting image info"
    $imgJsonFileContent = Get-Content -Path $pathToImgMetadataJson | ConvertFrom-Json
    $images = $imgJsonFileContent.$channel

    Write-Verbose -Verbose "Push images to ACR"
    foreach ($image in $images)
    {
        $name = $image.name
        if (!$name.Contains("test-deps"))
        {
            $imageOS = $image.os
            $tags = $image.tags.Split(' ')
            $tarballFileName = "$name.tar"
    
            $osFolder = Join-Path $imagesFolder -ChildPath $imageOS
            $currentImageFolder = Join-Path $osFolder -ChildPath $name
            $mainImageFolder = Join-Path $currentImageFolder -ChildPath "main"
            $tarballFilePath = Join-Path $mainImageFolder -ChildPath $tarballFileName
    
            $tarballFilePathExists = Test-Path -Path $tarballFilePath
            Write-Verbose -Verbose "name: $name os: $imageOS tarballFilePath: $tarBallFilePath exists: $tarballFilePathExists"
    
            if ($tarballFilePathExists)
            {
                foreach ($tag in $tags)
                {
                    Write-Verbose -Verbose "tag: $tag"
                    # Need to push image for each tag
                    $destination_image_full_name = "$env:DESTINATION_ACR_NAME.azurecr.io/public/powershell:${tag}"
                    Write-Verbose -Verbose "dest img full name: $destination_image_full_name"
                    Write-Verbose -Verbose "Pushing file $tarballFilePath to $destination_image_full_name"
                    ./crane push $tarballFilePath $destination_image_full_name
                    Write-Verbose -Verbose "done pushing for tag: $tag"
                }
            }
            else {
                Write-Verbose -Verbose "tarballFilePath: $tarBallFilePath does not exist"
            }
        }
    }

    Write-Verbose -Verbose "script finished running successfully"
}
catch {
    return 1
}

return 0
