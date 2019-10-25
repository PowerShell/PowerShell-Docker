# Docker

These Dockerfiles enable running PowerShell in a container for each Linux distribution we support.

This requires Docker 17.05 or newer.
It also expects you to be able to run Docker without `sudo`.
Please follow [Docker's official instructions][install] to install `docker` correctly.

[install]: https://docs.docker.com/engine/installation/

## Release

The release containers derive from the official distribution image,
such as `centos:7`, then install dependencies,
and finally install the PowerShell package.

These containers live at [hub.docker.com/r/microsoft/powershell][docker-release].

At about 440 megabytes, they are decently minimal,
with their size being the sum of the base image (200 megabytes)
plus the uncompressed package (120 megabytes),
and about 120 megabytes of .NET Core and bootstrapping dependencies.

[docker-release]: https://hub.docker.com/r/microsoft/powershell/

## Community

The Dockerfiles in the community folder were contributed by the community and are not yet officially supported.

## Examples

To run PowerShell from using a container:

```sh
$ docker run -it mcr.microsoft.com/powershell
Unable to find image 'mcr.microsoft.com/powershell:latest' locally
latest: Pulling from mcr.microsoft.com/powershell
cad964aed91d: Already exists
3a80a22fea63: Already exists
50de990d7957: Already exists
61e032b8f2cb: Already exists
9f03ce1741bf: Already exists
adf6ad28fa0e: Pull complete
10db13a8ca02: Pull complete
75bdb54ff5ae: Pull complete
Digest: sha256:92c79c5fcdaf3027626643aef556344b8b4cbdaccf8443f543303319949c7f3a
Status: Downloaded newer image for mcr.microsoft.com/powershell:latest
PowerShell
Copyright (c) Microsoft Corporation. All rights reserved.

PS /> Write-Host "Hello, World!"
Hello, World!
```

## Building the images

To build an image run `./build.ps1 -build -name <ImageFolderName>`.

### Example

For example to build Ubuntu 16.04/xenial, which is in `./release/ubuntu16.04`:

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

## NanoServer-Insider Release Notes

Please be sure to use a build from the Windows Insider program, either [Windows Server Insider](https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewserver) or the [Windows 10 Insider](https://insider.windows.com/GettingStarted),
as your Container host before trying to pull this image. Otherwise, pulling this image will **fail**.

Read more about the changes coming to Nano Server in future releases of Windows Server Insider [here](https://docs.microsoft.com/en-us/windows-server/get-started/nano-in-semi-annual-channel).

### This is pre-release software

Windows Server Insider Preview builds may be substantially modified before they are commercially released. Microsoft makes no warranties, express or implied, with respect to the information provided here.
Some product features and functionality may require additional hardware or software. These builds are for testing purposes only. Microsoft is not obligated to provide any support services for this preview software.

For more information see [Using Insider Container Images](https://github.com/Microsoft/Virtualization-Documentation/blob/live/virtualization/windowscontainers/quick-start/Using-Insider-Container-Images.md)
and [Build and run an application with or without .NET Core 2.0 or PowerShell Core 6](https://github.com/Microsoft/Virtualization-Documentation/blob/live/virtualization/windowscontainers/quick-start/Nano-RS3-.NET-Core-and-PS.md).

### Known Issues

#### PowerShell Get only works with CurrentUser Scope

Due to [known issues with the nano-server-insider](https://github.com/Microsoft/Virtualization-Documentation/blob/live/virtualization/windowscontainers/quick-start/Insider-Known-Issues.md#build-16237),
you must specify `-Scope CurrentUser` when using `Install-Module`.  Example:

```powershell
Install-Module <ModuleName> -Scope CurrentUser
```

## Developing and Contributing

Please see the [Contribution Guide][] for general information about how to develop and contribute.

For information specific to `PowerShell-Docker` see [Development][development].

If you have any problems, please consult the [known issues][], developer [FAQ][], and [GitHub issues][].
If you do not see your problem captured, please file a [new issue][] and follow the provided template.
If you are developing .NET Core C# applications targeting PowerShell Core, please [check out our FAQ][] to learn more about the PowerShell SDK NuGet package.

Also make sure to check out our [PowerShell-RFC repository](https://github.com/powershell/powershell-rfc) for request-for-comments (RFC) documents to submit and give comments on proposed and future designs.

[check out our FAQ]: https://github.com/PowerShell/PowerShell/tree/master/docs/FAQ.md#where-do-i-get-the-powershell-core-sdk-package
[Contribution Guide]: https://github.com/PowerShell/PowerShell/tree/master/.github/CONTRIBUTING.md
[known issues]: https://github.com/PowerShell/PowerShell/tree/master/docs/KNOWNISSUES.md
[GitHub issues]: https://github.com/PowerShell/PowerShell/issues
[new issue]:https://github.com/PowerShell/PowerShell/issues/new
[development]: https://github.com/PowerShell/PowerShell-Docker/tree/master/docs/development.md
## Legal and Licensing

PowerShell is licensed under the [MIT license][].

[MIT license]: https://github.com/PowerShell/PowerShell/tree/master/LICENSE.txt

### Windows Docker Files and Images

License: By requesting and using the Container OS Image for Windows containers, you acknowledge, understand, and consent to the Supplemental License Terms available on Docker hub:

- [Window Server Core](https://hub.docker.com/r/microsoft/windowsservercore/)
- [Nano Server](https://hub.docker.com/r/microsoft/nanoserver/)

### Telemetry

By default, PowerShell collects the OS description and the version of PowerShell (equivalent to `$PSVersionTable.OS` and `$PSVersionTable.GitCommitId`) using [Application Insights](https://azure.microsoft.com/en-us/services/application-insights/).
To opt-out of sending telemetry, create an environment variable called `POWERSHELL_TELEMETRY_OPTOUT` set to a value of `1` before starting PowerShell from the installed location.
The telemetry we collect fall under the [Microsoft Privacy Statement](https://privacy.microsoft.com/en-us/privacystatement/).

## Governance

Governance policy for PowerShell project is described [here][].

[here]: https://github.com/PowerShell/PowerShell/blob/master/docs/community/governance.md

## [Code of Conduct][conduct-md]

This project has adopted the [Microsoft Open Source Code of Conduct][conduct-code].
For more information see the [Code of Conduct FAQ][conduct-FAQ] or contact [opencode@microsoft.com][conduct-email] with any additional questions or comments.

[conduct-code]: http://opensource.microsoft.com/codeofconduct/
[conduct-FAQ]: http://opensource.microsoft.com/codeofconduct/faq/
[conduct-email]: mailto:opencode@microsoft.com
[conduct-md]: https://github.com/PowerShell/PowerShell/tree/master/./CODE_OF_CONDUCT.md
