# syntax = docker/dockerfile:1.2
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
FROM registry.access.redhat.com/ubi8/ubi:8.6 AS installer-env
ARG PS_VERSION=7.3.0-preview.8
ARG PACKAGE_VERSION=7.3.0_preview.8
ARG PS_PACKAGE=powershell-preview-${PACKAGE_VERSION}-1.rh.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

# Install powershell
# create folder at install location
RUN curl -sSL ${PS_PACKAGE_URL} -o /tmp/linux.rpm
# start new stage so that the tar.gz layers are left behind in multi-stage build
FROM registry.access.redhat.com/ubi8/ubi:8.6 AS final-image
ARG PS_VERSION=7.3.0-preview.8
ARG PS_INSTALL_VERSION=7-preview

RUN --mount=type=cache,target=/var/cache/yum,rw \
    yum install -y \
      less \
      ncurses \
      openssh-clients \
      glibc-locale-source \
      glibc-langpack-en \
      libicu \
    && yum clean all
RUN --mount=type=cache,target=/var/cache/yum,rw \
    --mount=from=installer-env,target=/mnt/rpm,source=/tmp \
    yum localinstall -y \
      /mnt/rpm/linux.rpm \
    # ubi 8 security updates are not marked as security updates.
    && yum upgrade -y \
    && yum clean all
# Define ENVs for Localization/Globalization
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/${PS_INSTALL_VERSION} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-UBI-8.4

RUN localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    && export POWERSHELL_TELEMETRY_OPTOUT=1 \
    && pwsh\
        -NoLogo \
        -NoProfile \
        -Command " \
                    \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            Start-Sleep -Seconds 6 ; \
          }"
# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD ["pwsh-preview"]
