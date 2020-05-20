# ![logo][] PowerShell

[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

## Docker pull command

```bash
$ docker pull pshorg/powershellcommunity
```

## Tags

### Community Stable Linux amd64 tags

* **[Amazon Linux][amazon-linux-uri]**
  * Tags: `amazonlinux-2.0` , `6.1.1-amazonlinux-2.0.20181114`
  * Dockerfile: [/release/community-stable/amazonlinux/docker/Dockerfile][amazon-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:amazonlinux-2.0`
* **[Arch Linux][arch-linux-uri]**
  * Tags: `archlinux-2018.10.01` , `6.1.1-archlinux-2018.10.01`
  * Dockerfile: [/release/community-stable/archlinux/docker/Dockerfile][arch-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:archlinux-2018.10.01`
* **[BlackArch Linux][blackarch-linux-uri]**
  * Tags: `blackarch-2018.10.01` , `6.1.1-blackarch-2018.10.01`
  * Dockerfile: [/release/community-stable/blackarch/docker/Dockerfile][blackarch-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:blackarch-2018.10.01`
<!-- Broken
* **[Clear Linux][clear-linux-uri]**
  * Tags: `clearlinux-base` , `6.1.1-clearlinux-base`
  * Dockerfile: [/release/community-stable/clearlinux/docker/Dockerfile][clear-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:clearlinux-base`
* **[Kali Linux][kali-linux-uri]**
  * Tags: `kali-kali-rolling` , `6.1.1-kali-kali-rolling`
  * Dockerfile: [/release/community-stable/kali-rolling/docker/Dockerfile][kali-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:kali-kali-rolling`
-->
* **[Oracle Linux][oracle-linux-uri]**
  * Tags: `oraclelinux-7.5` , `6.1.1-oraclelinux-7.5`
  * Dockerfile: [/release/community-stable/oraclelinux/docker/Dockerfile][oracle-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:oraclelinux-7.5`

* **[Parrot Linux][parrotsec-linux-uri]**
  * Tags: `parrotsec-latest` , `7.0.1-parrotsec-latest`
  * Dockerfile: [/release/community-stable/parrot/docker/Dockerfile][parrotsec-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:parrotsec-latest`

* **[Photon Linux][parrotsec-linux-uri]**
  * Tags: `photon-2.0` , `6.1.1-photon-2.0`
  * Dockerfile: [/release/community-stable/photon/docker/Dockerfile][photon-linux-stable-dockerfile]
  * Example: `docker pull pshorg/powershellcommunity:photon-2.0`

[amazon-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/amazonlinux/docker/Dockerfile
[arch-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/archlinux/docker/Dockerfile
[blackarch-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/blackarch/docker/Dockerfile
[clear-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/clearlinux/docker/Dockerfile
[kali-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/kali-rolling/docker/Dockerfile
[oracle-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/oraclelinux/docker/Dockerfile
[parrotsec-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/parrotsec/docker/Dockerfile
[photon-linux-stable-dockerfile]: https://github.com/PowerShell/PowerShell-Docker/blob/master/release/community-stable/photon/docker/Dockerfile

[amazon-linux-uri]: https://aws.amazon.com/amazon-linux-2/
[arch-linux-uri]: https://www.archlinux.org/
[blackarch-linux-uri]: https://www.blackarch.org/
[clear-linux-uri]: https://www.clearlinux.org/
[kali-linux-uri]: https://www.kali.org/
[oracle-linux-uri]: https://www.oracle.com/linux/
[parrotsec-linux-uri]: https://www.parrotsec.org/
[photon-linux-uri]: https://vmware.github.io/photon/

## Legal and licensing

PowerShell is licensed under the [MIT license][].

[MIT license]: https://github.com/PowerShell/PowerShell/tree/master/LICENSE.txt

[Third-Party Software Notices and Information](https://github.com/PowerShell/PowerShell/blob/master/ThirdPartyNotices.txt)

## About the image

PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework. It works well with your existing tools and is optimized for dealing with structured data (for example, JSON, CSV, and XML), REST APIs, and object models.
It includes a command-line shell, an associated scripting language, and a framework for processing cmdlets.

If you are new to PowerShell and want to learn more, see the [getting started][] documentation.

[getting started]: https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell

## How to use this image

See our [Docker examples](https://github.com/PowerShell/PowerShell-Docker#examples).

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue][].

[GitHub issue]: https://github.com/PowerShell/PowerShell-Docker/issues

## Related

PowerShell Docker Hub repo:

* [microsoft/powershell][] for Microsoft supported images.

[microsoft/powershell]: https://hub.docker.com/r/microsoft/powershell/
