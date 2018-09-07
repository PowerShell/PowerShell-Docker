# Docker image file that describes an Alpine3.8 image with PowerShell installed from .tar.gz file(s)
# NOTE: the alpine tar.gz when this was written doesn't contain the modules.  For that we need a container with modules.
# To accomplish this, we will get the modules from the full linux tar.gz package, then
# overlay the alpine tar.gz on top of it.
# There are TODO's in the file on updates that should occure one the Alpine .tar.gz contains everything

ARG fromTag=16.04

FROM alpine:3.8

ARG PS_VERSION=6.1.0-rc.1
ARG PS_VERSION_POSTFIX=-1.ubuntu.16.04
# TODO: once the official build produces a full package for alpine, update this to the full package
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG IMAGE_NAME=microsoft/powershell:ubuntu16.04
ARG VCS_REF="none"

LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PS." \
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

RUN apk add --no-cache \
        ca-certificates \
        \
        # .NET Core dependencies
        krb5-libs \
        libgcc \
        libintl \
        libssl1.0 \
        libstdc++ \
        tzdata \
        userspace-rcu \
        zlib \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
        lttng-ust

RUN apk add --no-cache \
        curl

# Set the invariant mode since icu_libs isn't included (see https://github.com/dotnet/announcements/issues/20)
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

# Get the InstallTarballPackage.sh script
ADD https://raw.githubusercontent.com/PowerShell/PowerShell/master/docker/InstallTarballPackage.sh /InstallTarballPackage.sh

# Add execution permission
RUN chmod +x /InstallTarballPackage.sh

# Install powershell from tarball package
RUN /InstallTarballPackage.sh $PS_VERSION $PS_PACKAGE

# Create the preview symbolic link that points to powershell
# InstallTarballPackage creates the pwsh link
RUN ln -s /opt/microsoft/powershell/$S_VERSION/pwsh /usr/bin/pwsh-preview

# Remove the script
RUN rm -f /InstallTarballPackage.sh

# Begin region to overlay the alpine tag.gz
# TODO: once the official build produces a full package for alpine, remove this region

# Download the powershell .tar.gz package
RUN curl -L -o /tmp/powershell.tar.gz https://github.com/TravisEz13/PowerShell/releases/download/v6.1.0-rc.1/powershell-6.1.0-fixalpine-linux-musl-x64.tar.gz

# Expand powershell to the target folder
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/$PS_VERSION

# remove tar.gz
RUN rm -f /tmp/powershell.tar.gz

# End region to overlay the alpine tag.gz

CMD [ "pwsh" ]
