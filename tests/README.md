# Docker tests

## Windows and Linux containers

The tests must be run separately on the Windows and Linux docker daemons. You can use the Linux docker daemon on Windows, but that will only test Linux containers not Windows Containers.

## To building and basic behavior of the containers

```powershell
Invoke-Pester
```

Note: be sure to do this using both the Windows and Linux docker daemon, as the windows.

## To test the productions containers

```powershell
Invoke-Pester -Tag Behavior
```

## To test only building the containers

```powershell
Invoke-Pester -Tag Build
```
