# Docker image file that describes an OpenSuse 42.3 image with PowerShell installed from tar.gz
# Implemented in two stages, one that downloads and uncompresses the tar.gz
# The next stage simply copies the files from the first stage,
# effectively removing the tar.gz and packages that are not needed from the final image.

# Define arg(s) needed for the From statement
ARG fromTag=42.3
ARG imageRepo=opensuse/leap

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.2.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Install dependencies
RUN zypper --non-interactive update --skip-interactive

RUN zypper --non-interactive install \
        tar

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER} -v

# ------ Second stage ------
# Start a new stage so we lose all the tar.gz layers from the final image
FROM ${imageRepo}:${fromTag}

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=6
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache


# Install dependencies
RUN zypper --non-interactive update --skip-interactive \
    && zypper --non-interactive install \
        glibc-locale \
        glibc-i18ndata \
        libicu \
        openssl \
        less \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # clean package manager cache
    && zypper clean -a \
    # remove package manager log file
    && rm -f /var/log/zypp/history /var/log/zypper.log \
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

CMD [ "pwsh" ]
