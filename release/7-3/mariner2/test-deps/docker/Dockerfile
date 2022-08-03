# Docker image file that describes an Mariner image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:mariner
FROM ${BaseImage}

# To find which package provides a particular command, run:
# tdnf install dnf-utils
# dnf provides <command>

# Install dependencies and clean up
RUN --mount=type=cache,target=/var/cache/tdnf \
    tdnf update -y \
    # install dependencies
    && tdnf install -y \
    dnf-utils \
    sudo \
    curl \
    wget \
    # provides ping and trace path
    iputils \
    # provides ps
    procps-ng \
    unzip \
    git \
    mariner-repos-microsoft-preview \
    net-tools \
    tar \
    util-linux \
    # clean cached data
    && tdnf clean all

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Mariner-2.0

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
