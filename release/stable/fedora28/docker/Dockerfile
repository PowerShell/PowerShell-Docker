# Docker image file that describes Fedora 28 image with PowerShell installed from Microsoft YUM Repo
ARG fromTag=28
ARG imageRepo=fedora

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Install dependencies
# Install dependencies and clean up
RUN dnf install -y \
        tar

# downoad the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# ------ Second stage ------
# Start a new stage so we loose all the tar.gz layers from the final image
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
    LANG=en_US.UTF-8

# Install dependencies and clean up
RUN dnf install -y \
        libicu \
        openssl-libs \
	# less is needed for help
	less \
        \
        # Needed to run localdef
        glibc-locale-source \
        \
        # Invoke-WebRequest doesn't work correctly without this
        compat-openssl10 \
    && dnf upgrade-minimal -y --security \
    && dnf clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh

# Define args needed only for the labels
ARG VCS_REF="none"
ARG PS_VERSION=6.1.0
ARG IMAGE_NAME=mcr.microsoft.com/powershell:fedora28

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
