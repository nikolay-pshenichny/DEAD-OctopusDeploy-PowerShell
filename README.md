OctopusDeploy-PowerShell
========================

Some PowerShell scripts for the Octopus Deploy API


ExportProjectSteps
------------------

Exports all steps for an Octopus Deploy project to a new packages.config file.

### Usage

    $ powershell -f ExportProjectSteps.ps1 -server "http://server:port" -project "Project Name" -userName "userName"
    or
    $ ExportProjectSteps.bat -server "http://server:port" -project "Project Name" -userName "userName"



DeployProjects
--------------

Emulates Octopus Deploy behavior for all described packages from the packages.config file:
  #1 Installs (downloads and unpacks) a package to an output directory
  #2 Starts PreDeploy.ps1, Deploy.ps1 and PostDeploy.ps1 from the unpacked package directory.

### Usage

Note: Should be started with Administrator priveleges

    $ powershell -f DeployProjects.ps1 -source "http://someserver/NuGet/api/v2/" -pre 1
    or
    $ DeployProjects.bat -source "http://someserver/NuGet/api/v2/" -pre 1

In order to export project steps from existing Octopus Deploy server 
and deploy them to a local machine, run both commands (`ExportProjectSteps` and `DeployProjects`)

    $ ExportProjectSteps. -server "http://server:port" -project "Project Name" -userName "userName"
    $ DeployProjects.bat -source "http://someserver/NuGet/api/v2/" -pre 1
