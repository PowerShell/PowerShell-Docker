# Docker image file that describes an Mariner image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:mariner
FROM ${BaseImage}

# To find which package provides a particular command, run:
# yum install dnf-utils
# dnf provides <command>

# Install dependencies and clean up
RUN yum update -y \
    # install dependencies
    && yum install -y \
    dnf-utils \
    sudo \
    curl \
    wget \
    # provides ping and trace path
    iputils \
    # provides ps
    procps-ng \
    # upgrade packages
    && yum upgrade -y \
    # clean cached data
    && yum clean all \
    # remove cache folders and files
    && rm -rf /var/cache/yum

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Mariner-1.0

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
