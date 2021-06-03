# Docker image file that describes an Fedora32 image with PowerShell installed from Microsoft YUM Repo
ARG BaseImage=mcr.microsoft.com/powershell:preview-fedora-32

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
    && dnf clean all

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Fedora-32

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
