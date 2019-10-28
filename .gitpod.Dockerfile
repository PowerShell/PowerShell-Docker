FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && apt-get --yes install docker \
    && pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser -force" 
