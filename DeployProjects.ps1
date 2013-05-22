#
#
# This script emulates Octopus Deploy behavior:
#   - Installs all packets from packages.config
#   - Starts PreDeploy.ps1, Deploy.ps1, PostDeploy.ps1 from each package
#
# Usage (with Admin privileges): powershell -f DeployProjects.ps1 -source "http://someserver/NuGet/api/v2/" -pre 1
#
#
param (
	# NuGet Repository Source
	[string]$source = "https://nuget.org/api/v2/",
	# Output Directory
	[string]$output = "Packages/",
	# Allow to look for prerelease packages. Allowed values - 0 or 1
	[string]$pre = "0"
)

$PackagesVersionsArray = $null
$PreRelease = @("")
if ($pre -eq "1")
{
	$PreRelease = @("-PreRelease")
}

$VersionPattern = "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"
if ($pre -eq "1")
{
	$VersionPattern = "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\-\w*)"
}


##############################
# Get packages from the Server
[xml]$packages = Get-Content packages.config
foreach($package in $packages.packages.ChildNodes)
{
	if (($package.NodeType -eq "Element") -and ($package.id -ne $null))
	{
		$version = $package.version
		Write-Host
		if ($version -ne $null)
		{
			Write-Host "Downloading and extracting package "$package.id" (version "$package.version")"
			$results = .\.nuget\nuget.exe install $package.id -OutputDirectory $output -Source $source -Verbosity detailed -Version $package.version @PreRelease
		}
		else
		{
			# Downloading and extracting the package
			Write-Host "Downloading and extracting package "$package.id" (Latest version)"
			$results = .\.nuget\nuget.exe install $package.id -OutputDirectory $output -Source $source -Verbosity detailed @PreRelease

			# Detecting version of the package
			$alreadyInstalledPattern = "'" + $package.id + "\s+" + $VersionPattern + "' already installed"
			#write-host $alreadyInstalledPattern
			$alreadyInstalled = $results | Select-String -Pattern $alreadyInstalledPattern
			if ($alreadyInstalled)
			{
				$matches = $alreadyInstalled | Select -Expand Matches
				$version = $matches[0].Groups[1].Value
				Write-Host "Already Installed "$version
			}

			$successfullyInstalledPattern = "Successfully installed '" + $package.id + "\s+" + $VersionPattern + "'."
			#write-host $successfullyInstalledPattern
			$successfullyInstalled = $results | Select-String -Pattern $successfullyInstalledPattern
			if ($successfullyInstalled)
			{
				$matches = $successfullyInstalled | Select -Expand Matches
				$version = $matches[0].Groups[1].Value
				Write-Host "Successfully Installed "$version
			}
		}
	
		$packageObject = New-Object System.Object
		$packageObject | Add-Member -type NoteProperty -name id -value $package.id
		$packageObject | Add-Member -type NoteProperty -name version -value $version
		$PackagesVersionsArray = $PackagesVersionsArray + ,$packageObject

		#if ($results -eq  "All packages listed in packages.config are already installed.")
		#{
		#	Write-Host "Package already installed"
		#}
		#else
		#{
		#	Write-Host $results
		#}





		Write-Host $results
	
		if ((!$?) -or ($LASTEXITCODE -ne 0))
		{
			Throw "Error during running nuget.exe command. Code: " + $LASTEXITCODE
		}
	}
}


#################################
# Run Deploy.ps1 for each package
Write-Host
$current_directory = (Get-Location -PSProvider FileSystem).ProviderPath
Write-Host "Current directory: "$current_directory
foreach ($packageObject in $PackagesVersionsArray)
{
		Write-Host
		Write-Host "Deploying: "$packageObject.id" version: "$packageObject.version
		#TODO:NIKO: check if directory exists
	
	
		$packageDirectory = $output + $packageObject.id + "." + $packageObject.version
		$packageDirectory = Join-Path $current_directory $packageDirectory
		Write-Host "From directory "$packageDirectory
	
		$preDeployScript = Join-Path $packageDirectory "PreDeploy.ps1"
		if ([IO.File]::Exists($preDeployScript))
		{
			Write-Host "Starting Pre-Deploy scripts"
			cd $packageDirectory
			Invoke-Command -ScriptBlock {.\PreDeploy.ps1}
			#.\PreDeploy.ps1
		}
	
		$deployScript = Join-Path $packageDirectory "Deploy.ps1"
		if (![IO.File]::Exists($deployScript))
		{
			Throw "Deploy.ps1 not found. Terminating..."
		}
	
		Write-Host "Starting Deploy scripts"
		cd $packageDirectory
		Invoke-Command -ScriptBlock {.\Deploy.ps1}
		#.\Deploy.ps1
	
	
	
		$postDeployScript = Join-Path $packageDirectory "PostDeploy.ps1"
		if ([IO.File]::Exists($postDeployScript))
		{
			Write-Host "Starting Post-Deploy scripts"
			cd $packageDirectory
			Invoke-Command -ScriptBlock {.\PostDeploy.ps1}
			#.\PostDeploy.ps1
		}
		
		cd $current_directory
}
