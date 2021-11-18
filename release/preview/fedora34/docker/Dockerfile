# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Docker image file that describes Fedora 34 image with PowerShell installed from Microsoft YUM Repo
ARG imageRepo=fedora

FROM ${imageRepo}:34 AS installer-env

ARG PS_VERSION=7.0.0
ARG PACKAGE_VERSION=7.0.0
ARG PS_PACKAGE=powershell-preview-${PACKAGE_VERSION}-1.rh.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}


# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Fedora-32

# Install dependencies and clean up
RUN curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell.rpm \
    && dnf install -y /tmp/powershell.rpm \
    # remove powershell package
    && rm /tmp/powershell.rpm \
    && echo "starting misc packages" \
    && dnf install -y \
    # less is needed for help
      less \
    # Needed to run localdef
      glibc-locale-source \
    # Invoke-WebRequest doesn't work correctly without this
      openssl-libs \
      ca-certificates \
      gssntlmssp \
    && echo "end - misc packages" \
    && ln -sf /opt/microsoft/powershell/7-preview/pwsh /usr/bin/pwsh \
    # This installs most security advisories
    && echo "starting upgrade minimal" \
    && dnf upgrade-minimal -y --security \
    && echo "end - upgrade minimal" \
    && echo "verifying all security advisories are installed..." \
    && dnf updateinfo list -q --security \
    && echo "end - verifying all security advisories are installed..." \
    && dnf clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US en_US.UTF-8 \
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
          }"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
