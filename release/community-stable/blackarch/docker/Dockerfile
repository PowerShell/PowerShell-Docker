# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an BlackArch Linux image (derived from Arch
# Linux base image) with PowerShell installed from full PowerShell linux tar.gz
# package

# Define arg(s) needed for the From statement
FROM archlinux:latest AS installer-env

RUN \
    # create a builduser
    useradd builduser -m \
    # delete the builduser password
    && passwd -d builduser \
    # enable builduser to sudo without password
    && printf 'root ALL=(ALL) ALL\n' | tee -a /etc/sudoers \
    # update package database
    && pacman -Syy \
    # install dependencies
    && pacman -S --noconfirm \
      # required sudo
      sudo \
      # required to clone gss-ntlmssp git repository
      git \
      # required to make gss-ntlmssp binary package
      base-devel \
      libwbclient \
      docbook-xsl \
      doxygen \
    # change current root path to tmp directory path
    && cd /tmp \
    # clone the gss-ntlmssp package repository
    && git clone https://aur.archlinux.org/gss-ntlmssp.git \
    # change the cloned gss-ntlmssp package repository directory permission
    && chmod 777 /tmp/gss-ntlmssp/ \
    # change current path to gss-ntlmssp package repository folder path
    && cd gss-ntlmssp \
    # utilise sudo to builduser in order to make the gss-ntlmssp package
    && sudo -u builduser bash -c makepkg -s --noconfirm

# Start a new stage so we lose all the tar.gz layers from the final image
FROM archlinux:latest

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/tmp/gss-ntlmssp/gss-ntlmssp-0.8.0.r3.g2251a72-1-x86_64.pkg.tar.xz", "/tmp/gss-ntlmssp-0.8.0.r3.g2251a72-1-x86_64.pkg.tar.xz"]

# Define Args for the needed for BlackArch Linux
ARG BlackArch_Strap_URL=https://blackarch.org/strap.sh

# Download BlackArch Linux strap shell script
ADD ${BlackArch_Strap_URL} /tmp/strap.sh

# Define Args for the needed to add the package
ARG PS_VERSION=7.0.1
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7

# Define Args and Env needed to create links
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # Set up PowerShell module analysis cache path
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    # Opt out of SocketsHttpHandler in DotNet Core 2.1 to use HttpClientHandler
    # with installed libcurl4 package to resolve
    # Invoke-WebRequest : Authentication failed" issue when executing using
    # docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [Invoke-WebRequest] [-Uri <HTTPS URL>]
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0 \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-BlackArch-latest

# Installation
RUN \
    # enable en_US.UTF-8 locale
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    # generate locale
    && locale-gen \
    # set execute permission on BlackArch strap shell script
    && chmod +x /tmp/strap.sh \
    # update keyring server in /tmp/strap.sh
    && sed -i "s|pgp.mit.edu|hkp://pool.sks-keyservers.net|g" /tmp/strap.sh \
    # run BlackArch strap shell script
    && /tmp/strap.sh \
    # remove BlackArch strap shell script
    && rm -f /tmp/strap.sh \
    # update package database
    && pacman -Syy \
    # install dependencies
    && pacman -S --noconfirm \
      # required for International Components for Unicode
      core/icu \
      # required for SSL
      openssl-1.0 \
    # install gss-ntlmssp package from the previous stage
    && pacman -U --noconfirm /tmp/gss-ntlmssp-0.8.0.r3.g2251a72-1-x86_64.pkg.tar.xz \
    # create powershell folder
    && mkdir -p ${PS_INSTALL_FOLDER} \
    # Pull down the powershell linux tar file
    && curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell-linux.tar.gz \
    # uncompress powershell linux tar file
    && tar zxf /tmp/powershell-linux.tar.gz -C ${PS_INSTALL_FOLDER} \
    # remove powershell linux tar file
    && rm -f /tmp/powershell-linux.tar.gz \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # intialize powershell module cache
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            Start-Sleep -Seconds 6 ; \
          }" \
    # upgrade distro
    && pacman -Syyu --noconfirm \
    # clean downloaded packages
    && yes | pacman -Scc

CMD [ "pwsh" ]
