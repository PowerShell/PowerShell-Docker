FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable" \
    && apt-get --yes install \
        docker \
        docker-ce \
    && pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser -Force"
