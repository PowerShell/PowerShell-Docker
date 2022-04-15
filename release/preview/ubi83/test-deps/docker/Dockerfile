# Docker image file that describes an CentOS7 image with PowerShell installed from Microsoft YUM Repo
ARG BaseImage=mcr.microsoft.com/powershell:preview-ubi-8.3

FROM ${BaseImage}

# Install dependencies and clean up
RUN yum install -y \
        sudo \
        wget \
        openssl \
        hostname \
        iputils \
        procps-ng \
        less \
        ncurses \
        openssh-clients \
        glibc-locale-source \
        glibc-langpack-en \
        libicu \
    && yum clean all \
    && rm -rf /var/cache/yum

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-ubi-8.3

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
