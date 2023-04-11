# Docker image file that describes an CentOS7 image with PowerShell installed from Microsoft YUM Repo
ARG BaseImage=mcr.microsoft.com/powershell:ubi-9

FROM ${BaseImage}

# Install dependencies and clean up
RUN yum install -y \
        sudo \
        wget \
        hostname \
        iputils \
        procps-ng \
        git \
        unzip \
    && yum clean all \
    && yum upgrade -y \
    && rm -rf /var/cache/yum

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-ubi-9

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
