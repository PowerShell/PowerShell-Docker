FROM mcr.microsoft.com/powershell:latest

USER root

RUN pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser"
