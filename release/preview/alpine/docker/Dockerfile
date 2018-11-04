# Docker image file that describes an Alpine3.8 image with PowerShell installed from .tar.gz file(s)
# NOTE: the Alpine tar.gz when this was written doesn't contain the modules.  For that we need a container with modules.
# To accomplish this, we will get the modules from the full linux tar.gz package, then
# overlay the Alpine tar.gz on top of it.
# There are TODO's in the file on updates that should occur one the Alpine .tar.gz contains everything

# Define arg(s) needed for the From statement
ARG fromTag=3.8

FROM alpine:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.1.0-rc.1
# TODO: once the official build produces a full package for Alpine, update this to the full Alpine package
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6-preview

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# TODO: once the official build produces a full package for Alpine, remove this overlay of the Alpine files
# Download the Alpine powershell .tar.gz package
ADD https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/powershell-6.1.0-linux-musl-x64.tar.gz /tmp/alpine.tar.gz

# Extract the Alpine tar.gz
RUN tar zxf /tmp/alpine.tar.gz -C ${PS_INSTALL_FOLDER}

# Start a new stage so we lose all the tar.gz layers from the final image
FROM alpine:${fromTag}

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=6-preview
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Install dotnet dependencies and ca-certificates
RUN apk add --no-cache \
    ca-certificates \
    less \
    \
    # PSReadline/console dependencies
    ncurses-terminfo-base \
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
    icu-libs \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
    \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    \
    # Create the pwsh-preview symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview

# Define args needed only for the labels
ARG PS_VERSION=6.1.0-rc.1
ARG IMAGE_NAME=mcr.microsoft.com/powershell:preview-alpine-3.8
ARG VCS_REF="none"
# Add label last as it's just metadata and uses a lot of parameters
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
    readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
    description="This Dockerfile will install the latest release of PowerShell." \
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

CMD [ "pwsh" ]
