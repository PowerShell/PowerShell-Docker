# PowerShell-Docker

These `Dockerfile`s enable running PowerShell in a container for each Linux distribution we support.

This requires Docker 17.05 or newer.
It also expects you to be able to run Docker without `sudo`.
Please follow [Docker's official instructions][install] to install Docker correctly.

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

## Known Issues

See [Known Issues](https://github.com/PowerShell/PowerShell-Docker/wiki/Known-Issues)

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
[development]: https://github.com/PowerShell/PowerShell-Docker/blob/master/docs/development.md

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
