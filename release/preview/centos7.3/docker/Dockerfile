# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM centos:7.3.1611 as installer-env

ARG PS_VERSION=7.0.0-preview.1
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# download linux powershell tar.gz and save it (to tmp folder to later be left behind)
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# print url just so we can double check
RUN echo ${PS_PACKAGE_URL}

# extract contents from the tar.gz file
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# start new stage so that the tar.gz layers are left behind in multi-stage build
FROM centos:7.3.1611 AS final-image

ARG PS_VERSION=7.0.0-preview.1
ARG PS_INSTALL_VERSION=7-preview

# create the install folder- COPY creates directory if it doesn't already exist
# RUN mkdir -p ${PS_INSTALL_FOLDER}

# copy only files needed from the prior stage, others will be left behind
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define ENVs for Localization/Globalization
ENV PS_INSTALL_VERSION=7-preview \
    PS_INSTALL_FOLDER=/opt/microsoft/powershell/${PS_INSTALL_VERSION} \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache ?
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-CentOS-7.3.1611 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1


# Install dependencies and clean up
RUN yum install -y epel-release \
    # epel-release required for gssntlmssp, now we can update
    && yum update -y \
    # Install libraries for NTLM support
    && yum install -y \
      gssntlmssp \
      # less is required for help in powershell
      less \
      # clear is part of ncurses which is used by clear
      ncurses \
      openssh-clients \
    && yum upgrade-minimal -y --security \
    && yum clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    # give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # create pwsh symbolic link pointing to powershell
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # create pwsh symbolic link pointing to powershell preview
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    # initialize powershell module cache and disable telemetry support
    && export POWERSHELL_TELEMETRY_OPTOUT=1 \
    # && export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
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












# # Download the Linux tar.gz and save it
# ADD ${PS_PACKAGE_URL} ${PS_INSTALL_FOLDER}/linux.tar.gz

# RUN echo ${PS_PACKAGE_URL}

# # unzip the linux tar.gz
# RUN tar zxf ${PS_INSTALL_FOLDER}/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# # remove the tar.gz file we extracted out in last step/layer?
# RUN rm ${PS_INSTALL_FOLDER}/linux.tar.gz


#
# # Create the install folder, get the linux tar.gz, unzip it
# RUN mkdir -p ${PS_INSTALL_FOLDER} \
#     && curl ${PS_PACKAGE_URL} -O . \
#     | tar -zxf ./

