# Docker image file that describes an Kali Rolling image with PowerShell installed from tar.gz
# Implemented in two stages, one that downloads and uncompresses the tar.gz
# The next stage simply copies the files from the first stage, 
# effectively removing the tar.gz and packages that are not needed from the final image.

# Define arg(s) needed for the From statement
ARG fromTag=kali-rolling
ARG imageRepo=kalilinux/kali-linux-docker

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.debian.9_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.deb

# Install dependencies
RUN wget \
    # renew kali repository expired certificate in container image
    --no-check-certificate https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2018.1_all.deb \
    --quiet \
    && apt-get install ./kali-archive-keyring_2018.1_all.deb \
    && rm -f ./kali-archive-keyring_2018.1_all.deb \
    && wget \
      # libicu57 is required
      --no-check-certificate http://ftp.us.debian.org/debian/pool/main/i/icu/libicu57_57.1-9_amd64.deb \
      --quiet \
    && dpkg -i ./libicu57_57.1-9_amd64.deb \
    && rm -f ./libicu57_57.1-9_amd64.deb \
    && apt-get update \
    && apt-get install -y \
      # less is required for help in powershell
        less \
      # requied to setup the locale
        locales \
      # required for SSL
        ca-certificates \
    && apt-get install -y /tmp/powershell.deb \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen $LANG && update-locale \
    # remove powershell package
    && rm -f /tmp/powershell.deb

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=6
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Define args needed only for the labels
ARG IMAGE_NAME=mcr.microsoft.com/powershell:opensuse-42.3
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