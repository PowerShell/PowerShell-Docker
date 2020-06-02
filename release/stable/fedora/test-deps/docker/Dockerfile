# Docker image file that describes an Fedora 28 image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:fedora-28

FROM ${BaseImage}

ARG fromTag=28

# Install dependencies and clean up
RUN dnf install -y \
        sudo \
        findutils \
        hostname \
        iputils \
        wget \
        procps-ng \
    && dnf clean all

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Fedora-${fromTag}

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
