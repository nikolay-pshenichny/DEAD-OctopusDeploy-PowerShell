# All Export functions here


function ExportSteps-PackagesConfig
{ 
	param
	(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[Object[]]$octopusSteps,

		[Parameter(Mandatory=$true)]
		[String]$outputFile
	)
	begin
	{
		$pipelinedData = @()
	}
	process
	{
		$pipelinedData += $octopusSteps
	}
	end
	{
		# Write all steps to XML file
		$xml = New-Object XML
		$declaration = $xml.CreateXmlDeclaration("1.0", "utf-8", $null)
		$packagesElement = $xml.CreateElement("packages")
		$xml.InsertBefore($declaration, $xml.DocumentElement)

		$xml.AppendChild($packagesElement)

		foreach($step in $pipelinedData)
		{
			$packageElement = $xml.CreateElement("package")
			$packageElement.SetAttribute("id", $step.NuGetPackageId)
			$packagesElement.AppendChild($packageElement)
		}
		
		$xml.Save($outputFile)
	}
}


Export-ModuleMember ExportSteps-PackagesConfig