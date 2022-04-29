# Docker image file that describes an Fedora32 image with PowerShell installed from Microsoft YUM Repo
ARG BaseImage=mcr.microsoft.com/powershell:fedora-34

FROM ${BaseImage}

# Install dependencies and clean up
RUN dnf install -y \
        sudo \
        wget \
        openssl \
        hostname \
        iputils \
        procps \
        findutils \
        unzip \
        git \
    && dnf clean all

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Fedora-34

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
