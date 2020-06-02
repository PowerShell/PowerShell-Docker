# Docker image file that describes Fedora 28 image with PowerShell installed from Microsoft YUM Repo
ARG fromTag=28
ARG imageRepo=fedora

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=7.0.0
ARG PACKAGE_VERSION=7.0.0
ARG PS_PACKAGE=powershell-${PACKAGE_VERSION}-1.rhel.7.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

ARG fromTag=28

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Fedora-${fromTag}

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
      compat-openssl10 \
      ca-certificates \
      gssntlmssp \
    && echo "end - misc packages" \
    && ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
    && echo "starting FEDORA-2019-27e7b92407" \
    # For whatever reason FEDORA-2019-27e7b92407 has to be patched manually
    # to do this, upgrade libmodulemd1, if it is installed
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          try { \$packageList = dnf list installed libmodulemd1} \
          catch {}; \
          \$module = (\$packageList | Select-String -SimpleMatch libmodulemd1);  \
          if(\$module) { \
            Write-Host '******* Patching *********'; \
            dnf upgrade -y libmodulemd1 \
          }" \
    && echo "end - FEDORA-2019-27e7b92407" \
    # This installs most security advisories
    && echo "starting upgrade minimal" \
    && dnf upgrade-minimal -y --security \
    && echo "end - upgrade minimal" \
    # query and install any remaining security advisories
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          Write-Host '******* Getting security advisory list *********'; \
          (dnf updateinfo list -q --security) |  \
              Foreach-Object { \
                  \$advisory=(\$_ -split ' ')[0]; \
                  Write-Host '******* Patching *********'; \
                  Write-Host \$advisory; \
                  Write-Host '************************'; \
                  dnf upgrade -y --advisory=\$advisory \
              }" \
    && echo "verifying all security advisories are installed..." \
    && dnf updateinfo list -q --security \
    && echo "end - verifying all security advisories are installed..." \
    && dnf clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
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
