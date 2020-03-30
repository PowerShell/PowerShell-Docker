# Development

## Building the images

To build an image run `./build.ps1 -build -name <ImageFolderName>`.

### Example

For example to build Ubuntu 16.04/xenial, which is in `./release/stable/ubuntu16.04`:

```sh
PS /powershell-docker> ./build.ps1 -Build -Name ubuntu16.04
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.0.2-ubuntu-16.04 PSversion: 6.0.2
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.0.2-ubuntu-trusty PSversion: 6.0.2
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.0.2-ubuntu-trusty-20180531 PSversion: 6.0.2
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.1.0-preview.2-ubuntu-16.04 PSversion: 6.1.0~preview.2
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.1.0-preview.2-ubuntu-trusty PSversion: 6.1.0~preview.2
VERBOSE: lauching build with fromTag: trusty-20180531 Tag: 6.1.0-preview.2-ubuntu-trusty-20180531 PSversion: 6.1.0~preview.2
VERBOSE: image name: powershell.local:6.0.2-ubuntu-16.04
VERBOSE: image name: powershell.local:6.0.2-ubuntu-trusty
VERBOSE: image name: powershell.local:6.0.2-ubuntu-trusty-20180531
VERBOSE: image name: powershell.local:6.1.0-preview.2-ubuntu-16.04
VERBOSE: image name: powershell.local:6.1.0-preview.2-ubuntu-trusty
VERBOSE: image name: powershell.local:6.1.0-preview.2-ubuntu-trusty-20180531
```

### Run the Docker image you built

```sh
PS /powershell-docker> docker run -it --rm powershell.local:6.1.0-preview.2-ubuntu-16.04 pwsh -c '$psversiontable'

Name                           Value
----                           -----
PSVersion                      6.0.2
PSEdition                      Core
GitCommitId                    v6.0.2
OS                             Linux 4.9.87-linuxkit-aufs #1 SMP Wed Mar 14 15:12:16 UTC 2018
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

## Adding new Docker image

### Folder structure

The top level folder with the `Dockerfile`s is `release`.
This should only have folders under it.
The three folders are:

* `stable` - Images for the current stable release of PowerShell Core.
* `preview` - Images for the current preview release of PowerShell Core.
* `community-stable` - Images for the current release of PowerShell Core that are not officially supported.

Under each of these, will be a folder for each image.
The name of the folder will be the name of the image in the build system, but does not translate into anything in docker.
For example, the `stable` Ubuntu 16.04 image is in `release/stable/ubuntu16.04`.
In this folder, there are 4 items:

* `docker` - A folder containing the `Dockerfile` to build the image and any other files needed in the Docker build context.
* `test-deps` (official images only) - Directory for a sub-image. See the [`test-deps` image purpose](./index.md#test-dep-images).
* `dependabot` (optional) - in this directory you can put a dummy `Dockerfile` for [Dependabot](https://dependabot.com) to auto-bump the version. See [Dependabot](#dependabot).
* `meta.json` - See [this section](#metadata-files) later.
* `getLatestTag.ps1` - This script should use the `Get-DockerTags` command from `tools\getDockerTags` to get the tags that should be used as the tag in the `FROM` statement in the Dockerfile.

### `Dockerfile` Standards

All `Dockerfile`s should follow certain standards:

* The following comments should be applied at the beginning of the `Dockerfile`:

  * Copyright notice
  * Software license
  * A brief description should be applied after a new line.

   For example:

```dockerfile
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes a brief description of the image to describe
# this image
```

* All arguments should be defaulted if needed to successfully build without specifying the argument

* The `FROM` statement should use an argument.
  
  For example:

```dockerfile
ARG fromTag=16.04

FROM ubuntu:${fromTag}
```

* A `PS_VERSION` argument should be defined, and used wherever the version is needed.
  
  For example:

```dockerfile
ARG PS_VERSION=6.0.4
```

* An `IMAGE_NAME` argument should be defined, and used in the labels where the image name is needed.

  For example:

```dockerfile
ARG IMAGE_NAME=mcr.microsoft.com/powershell:ubuntu16.04
```

* A `VCS_REF` argument should be defined, and used wherever the `git` commit hash is needed.

  For example:

```dockerfile
ARG VCS_REF="none"
```

* The following labels should be applied to all images:

```dockerfile
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell." \
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
      org.label-schema.name="powershell" \
      org.label-schema.vendor="PowerShell" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.version=${PS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"
```

## Testing

You should not have to write any specific tests for your image,
but you should consider if it needs to be added to the CI system.

The CI definition is here at `vsts-ci.yml`.

### Template

Here is a template for an image build job:

```yaml
- template: .vsts-ci/phase.yml
  parameters:
    name: insertImageNameHere
    imagename: insertImageNameHere
    stable: false
    preview: false
    communityStable: true
    continueonerror: false
```

## Tags

Tags are a JSON array that describes the tags the image should have.

### Supported Tags

Tags you can use:

  * `#psversion#` is replaced by the version of PowerShell used to build the image.
  * `#tag#` is replaced by all tags generated by the `getLatestTag.ps1` script.
  * `#shorttag#` is replaced by short tags generated by the `getLatestTag.ps1` script.

### Example

```json
"tagTemplates": [
    "#psversion#-windowsservercore-#tag#",
    "windowsservercore-#tag#"
]
```

## Metadata Files

This file *is **required*** for all containers. Here is the bare minimum:

```json
{
    "IsLinux" : true
}
```

You should also add [tags](#tags) as a field.

## Dependabot

This repository has [Dependabot](https://dependabot.com) enabled on it.

The PRs opened for automatic base-image-version bumps will be closed, but the version will most likely get increased.

### Adding to a new Image

You will need to put a `Dockerfile` in the `dependabot` directory of your image, simply containing:

```dockerfile
FROM my-base-image:1.0.0
```

You will also need to add an entry in the `/.dependabot/config.yml` file. Here is a template for that:

```yaml
- package_manager: "docker"
    directory: "/release/theChannelHere/theImageHere/dependabot"
    update_schedule: "daily"
```

> **Do not use `latest` as the base**, as this makes the whole purpose invalid!
