FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && apt-get install --yes software-properties-common \
    && curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh \
    && pwsh -NoLogo -NoProfile -c "Install-Module -Name Pester -Scope CurrentUser -Force"
