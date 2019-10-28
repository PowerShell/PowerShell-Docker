FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get install docker && pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser"
