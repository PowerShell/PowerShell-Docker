# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Kali Rolling image with PowerShell
# installed from Debian9 PowerShell package

# Define arg(s) needed for the From statement
ARG fromTag=kali-rolling
ARG imageRepo=kalilinux/kali-linux-docker

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.debian.9_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# Define Args and Env needed to create links
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Download the Debian9 PowerShell package and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.deb

# Define Args for the needed to add the package
ARG KALI_REPO_KEY_PACKAGE_URL=https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2018.1_all.deb

# Download the Kali repository package and save it
ADD ${KALI_REPO_KEY_PACKAGE_URL} /tmp/kali-archive-keyring_2018.1_all.deb

# Define Args for the needed to add the package
ARG DEBIAN_PACKAGE_URL=http://ftp.us.debian.org/debian/pool/main/i/icu/libicu57_57.1-9_amd64.deb

# Download the libicu57 Debian package and save it
ADD ${DEBIAN_PACKAGE_URL} /tmp/libicu57_57.1-9_amd64.deb

# Install dependencies
RUN \
    # renew kali repository expired certificate in container image
    apt-get install /tmp/kali-archive-keyring_2018.1_all.deb \ 
    && rm -f /tmp/kali-archive-keyring_2018.1_all.deb \
    && \
    # install required libicu57 package
    dpkg -i /tmp/libicu57_57.1-9_amd64.deb \
    && rm -f /tmp/libicu57_57.1-9_amd64.deb \
    && apt-get update \
    && apt-get install -y \
      # less is required for help in powershell
        less \
      # required to setup the locale
        locales \
      # required for SSL
        ca-certificates \
    && apt-get install -y /tmp/powershell.deb \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen && update-locale \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # remove powershell package
    && rm -f /tmp/powershell.deb

# Define args needed only for the labels
ARG IMAGE_NAME=openatmicrosoft/powershell:kali-rolling
ARG VCS_REF="none"

# Add label last as it's just metadata and uses a lot of parameters
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

CMD [ "pwsh" ]