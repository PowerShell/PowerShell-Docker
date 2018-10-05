# Docker image file that describes an Debian 8 image with PowerShell installed from Microsoft APT Repo
ARG fromTag=jessie
ARG imageRepo=debian


FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.debian.8_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

RUN echo ${PS_PACKAGE_URL}
# Download the Linux package and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.deb

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # required to remove gdebi on debian 8
    SUDO_FORCE_REMOVE=yes

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install -y \
    # less is required for help in powershell
        less \
    # requied to setup the locale
        locales \
    # required for SSL
        ca-certificates \
    # simplifies deb file install
        gdebi \
    && gdebi --n /tmp/powershell.deb \
    # gdebi isn't needed anymore remove it
    && apt-get purge -y gdebi \
    # remove any unused dependecies
    && apt-get autoremove -y \
    # upgrade all packages
    && apt-get dist-upgrade -y \
    # clean the cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # generate the locales
    && locale-gen $LANG && update-locale \
    # remove powershell package
    && rm /tmp/powershell.deb

# Define args needed only for the labels
ARG VCS_REF="none"
ARG IMAGE_NAME=mcr.microsoft.com/powershell:debian-8

LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell." \
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
      org.label-schema.name="powershell" \
      org.label-schema.vendor="PowerShell" \
      org.label-schema.version=${PS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
