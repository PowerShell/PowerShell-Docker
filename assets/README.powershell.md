# ![logo][] PowerShell

[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

## Docker pull command

`docker pull mcr.microsoft.com/powershell`

## Tags

### Latest

* `latest`: The latest stable image.
  * Ubuntu 16.04 for Linux and Windows Server Core for Windows
  * `docker pull mcr.microsoft.com/powershell` or `docker pull mcr.microsoft.com/powershell:latest`

### Preview

* `preview`: The latest preview image.
  * Ubuntu 16.04 for Linux and Windows Server Core for Windows
  * `docker pull mcr.microsoft.com/powershell:preview`

### Stable Linux amd64 tags

* `ubuntu-16.04`, `6.0.2-ubuntu-16.04` [(/release/stable/ubuntu16.04/docker/Dockerfile)][ubuntu-16.04-stable]
  * `docker pull mcr.microsoft.com/powershell:ubuntu-16.04`
* `centos-7`, `6.0.2-centos-7`, `6.1.0-preview.2-centos-7` [(/release/stable/centos7/docker/Dockerfile)][centos-7-stable]
  * `docker pull mcr.microsoft.com/powershell:centos-7`
* `fedora-27`, `6.0.2-fedora-27`, `6.1.0-preview.2-fedora-27` [(/release/stable/fedora27/docker/Dockerfile)][fedora-27-stable]
  * `docker pull mcr.microsoft.com/powershell:fedora-27`

[ubuntu-16.04-stable]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/ubuntu16.04/docker/Dockerfile
[centos-7-stable]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/centos7/docker/Dockerfile
[fedora-27-stable]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/fedora27/docker/Dockerfile

### Stable Windows amd64 tags

* `nanoserver` : The latest stable nanoserver image.
  * Docker will detect your version of windows and select the most appropriate NanoServer image (1709 or 1803.)
  * `docker pull mcr.microsoft.com/powershell:nanoserver`
* `6.0.2-nanoserver` : The latest `6.0.2` nanoserver image.
  * Docker will detect your version of windows and select the most appropriate NanoServer image (1709 or 1803.)
  * `docker pull mcr.microsoft.com/powershell:6.0.2-nanoserver`
* `windowsservercore`, `6.0.2-windowsservercore`, `6.1.0-preview.2-windowsservercore` [(release/stable/windowsservercore/docker/Dockerfile)][winsrvcore-stable]
  * `docker pull mcr.microsoft.com/powershell:windowsservercore`
* `6.0.2-nanoserver-1803`, `6.0.2-nanoserver-1709` [(release/stable/nanoserver/docker/Dockerfile)][nano-stable]
  * `docker pull mcr.microsoft.com/powershell:nanoserver`

[winsrvcore-stable]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/windowsservercore/docker/Dockerfile
[nano-stable]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/nanoserver/docker/Dockerfile

### Preview Linux amd64 tags

* `6.1.0-preview.2-ubuntu-16.04` [(/release/preview/ubuntu16.04/docker/Dockerfile)][ubuntu-16.04-preview]
  * `docker pull mcr.microsoft.com/powershell:6.1.0-preview.2-ubuntu-16.04`
* `6.1.0-preview.2-centos-7` [(/release/preview/centos7/docker/Dockerfile)][centos-7-preview]
  * `docker pull mcr.microsoft.com/powershell:6.1.0-preview.2-centos-7`
* `6.1.0-preview.2-fedora-27` [(/release/preview/fedora27/docker/Dockerfile)][fedora-27-preview]
  * `docker pull mcr.microsoft.com/powershell:6.1.0-preview.2-fedora-27`

[ubuntu-16.04-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/preview/ubuntu16.04/docker/Dockerfile
[centos-7-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/preview/centos7/docker/Dockerfile
[fedora-27-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/fedora27/docker/Dockerfile
[fedora-28-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/stable/fedora28/docker/Dockerfile

### Preview Windows amd64 tags

* `6.1.0-preview.2-windowsservercore` [(release/preview/windowsservercore/docker/Dockerfile)][winsrvcore-preview]
  * `docker pull mcr.microsoft.com/powershell:6.1.0-preview.2-windowsservercore`

[winsrvcore-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/preview/windowsservercore/docker/Dockerfile
[nano-preview]:https://github.com/PowerShell/PowerShell-Docker/blob/master/release/preview/nanoserver/docker/Dockerfile

## Legal and licensing

PowerShell is licensed under the [MIT license][].

[MIT license]: https://github.com/PowerShell/PowerShell/tree/master/LICENSE.txt

By requesting and using the Container OS image for Windows containers, you acknowledge, understand, and consent to the Supplemental License Terms available on Docker Hub:

* [Window Server Core](https://hub.docker.com/r/microsoft/windowsservercore/)
* [Nano Server](https://hub.docker.com/r/microsoft/nanoserver/)

[Third-Party Software Notices and Information](https://github.com/PowerShell/PowerShell/blob/master/ThirdPartyNotices.txt)

## About the image

PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework. It works well with your existing tools and is optimized
for dealing with structured data (for example, JSON, CSV, and XML), REST APIs, and object models.
It includes a command-line shell, an associated scripting language, and a framework for processing cmdlets.

If you are new to PowerShell and want to learn more, see the [getting started][] documentation.

[getting started]: https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell

## How to use this image

See our [Docker examples](https://github.com/PowerShell/PowerShell/tree/master/docker#examples).
