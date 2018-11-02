# Docker image file that describes Fedora 27 image with PowerShell installed from Microsoft YUM Repo
ARG fromTag=27
ARG imageRepo=fedora

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.1.0~rc.1
ARG PS_PACKAGE=powershell-preview-${PS_VERSION}-1.rhel.7.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}


# Download the Linux package and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.rpm

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Install dependencies and clean up
RUN dnf install -y /tmp/powershell.rpm \
    && dnf install -y \
	# less is needed for help
	less \
    # Needed to run localdef
        glibc-locale-source \
    # Invoke-WebRequest doesn't work correctly without this
        compat-openssl10 \
    && dnf upgrade-minimal -y --security \
    && dnf clean all \
    && localedef --charmap=UTF-8 --inputfile=en_US $LANG \
    # remove powershell package
    && rm /tmp/powershell.rpm \
    && ln -sf /opt/microsoft/powershell/6-preview/pwsh /usr/bin/pwsh

# Define args needed only for the labels
ARG VCS_REF="none"
ARG IMAGE_NAME=mcr.microsoft.com/powershell:fedora27

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
CMD [ "pwsh-preview" ]
