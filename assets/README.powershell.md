# PowerShell

## Featured Tags

### Latest

- `latest`: The latest stable image.
  - Ubuntu 18.04 for Linux and Windows Server Core for Windows
  - `docker pull mcr.microsoft.com/powershell` or `docker pull mcr.microsoft.com/powershell:latest`

### Preview

- `preview`: The latest preview image.
  - Ubuntu 18.04 for Linux and Windows Server Core for Windows
  - `docker pull mcr.microsoft.com/powershell:preview`

## About This Image

PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework.
It works well with your existing tools and is optimized
for dealing with structured data (for example, JSON, CSV, and XML), REST APIs, and object models.
It includes a command-line shell, an associated scripting language, and a framework for processing cmdlets.

If you are new to PowerShell and want to learn more, see the [getting started][] documentation.

[getting started]: https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell

## How to Use This Image

See our [Docker examples](https://github.com/PowerShell/PowerShell-Docker#examples).

## Configuration

See our [Docker examples](https://github.com/PowerShell/PowerShell-Docker#examples).

## Related Repos

- [PowerShell-test-deps](https://store.docker.com/images/microsoft-powershell-test-deps/):
  PowerShell with Test Dependencies

## Full Tag Listing

Tags go here.

## Support

For our support policy, see [PowerShell Core Support Lifecycle](https://docs.microsoft.com/en-us/powershell/scripting/powershell-core-support)

## Feedback

- To give feedback for PowerShell Core,
  file an issue at [PowerShell/Powershell](https://github.com/PowerShell/PowerShell/issues/new/choose)
- To give feedback for how the images are built,
  file an issue at [PowerShell/PowerShell-Docker](https://github.com/PowerShell/PowerShell-Docker/issues/new/choose)

## License

PowerShell is licensed under the [MIT license][].

[MIT license]: https://github.com/PowerShell/PowerShell/tree/master/LICENSE.txt

By requesting and using the Container OS image for Windows containers, you acknowledge, understand,
and consent to the Supplemental License Terms available on Docker Hub:

- [Windows Server Core](https://hub.docker.com/_/microsoft-windows-servercore)
- [Nano Server](https://hub.docker.com/_/microsoft-windows-nanoserver)

[Third-Party Software Notices and Information](https://github.com/PowerShell/PowerShell/blob/master/ThirdPartyNotices.txt)

**ADDITIONAL LICENSING REQUIREMENTS AND/OR USE RIGHTS**
Your use of the Supplement as specified in the preceding paragraph may result in the creation or
modification of a container image (“Container Image”) that includes certain Supplement components.
For clarity, a Container Image is separate and distinct from a virtual machine or virtual appliance image.
Pursuant to these license terms,
we grant you a restricted right to redistribute such Supplement components under the following conditions:

- (i) you may use the Supplement components only as used in, and as a part of, your Container Image,
- (ii) you may use such Supplement components in your Container Image as long as you have significant
  primary functionality in your Container Image that is materially separate and
  distinct from the Supplement; and
- (iii) you agree to include these license terms (or similar terms required by us or a hoster) with your
  Container Image to properly license the possible use of the Supplement components by your end-users.

We reserve all other rights not expressly granted herein.

**By using this Supplement, you accept these terms. If you do not accept them, do not use this Supplement.**

As part of the Supplemental License Terms for this Container OS Image for Windows containers,
you are also subject to the underlying Windows Server host software license terms,
which are located at https://www.microsoft.com/en-us/useterms.
