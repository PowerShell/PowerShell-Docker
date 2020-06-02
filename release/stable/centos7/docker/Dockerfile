# Docker image file that describes an CentOS7 image with PowerShell installed from Microsoft YUM Repo
ARG fromTag=7
ARG imageRepo=centos

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.2.0
ARG PACKAGE_VERSION=6.2.0
ARG PS_PACKAGE=powershell-${PACKAGE_VERSION}-1.rhel.7.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache

# Install dependencies and clean up
RUN curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell.rpm \
    && yum install -y /tmp/powershell.rpm \
    # Required for gssntlmssp
    && yum install -y epel-release \
    # Update now that we have epel-release
    && yum update -y \
    # Install libraries for NTLM support
    && yum install -y \
      gssntlmssp \
      # less is required for help in powershell
      less \
    && yum upgrade-minimal -y --security \
    && yum clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    # remove powershell package
    && rm /tmp/powershell.rpm \
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
