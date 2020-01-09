FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && apt-get install -y curl \
    && curl -fsSL https://get.docker.com | sh \
    && pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser -force" 
