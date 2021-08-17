function New-ModCategory {
    [CmdletBinding()]
    param (
        # Populates the author field in About.xml and the first part of packageId
        [Parameter(Mandatory)]
        [string]
        $Author,

        # Populates the middle section of packageId.
        [string]
        $PackageId_Category,

        # An array of category names. Spaces are valid and will be stripped out of the folder name, packageId, and manifest identifier.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $CategoryNames,

        # The target directory where the mods will be created
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $TargetDirectory,

        # Force all categories to use this description instead of asking for input.
        $ForceDescription
    )
    
    begin {
        if  ( -Not (Test-Path -Path $TargetDirectory -PathType Container)) {
            throw "TargetDirectory must be an existing path with PathType Container"
        }

        $AuthorNoSpaces = $Author.Replace(" ", "")
        $PackageId_Category = $PackageId_Category.Replace(" ", "")

        $TemplatePath = ".\Resources\Template\*"
        $CategoryPrefix = "ModCategory_"

        $LoadBeforePrompt = "List the packageId(s) of any mods that {0} should be loaded BEFORE - enter a blank line to end input"
        $LoadAfterPrompt = "List the packageId(s) of any mods that {0} should be loaded AFTER - enter a blank line to end input"

        [string]$About
        [string]$Manifest
        [string]$PackageId
        [string]$Description
        [string[]]$LoadBefore
        [string[]]$LoadAfter
        [System.IO.FileInfo]$FullName
        [System.IO.FileInfo]$FullPath
        [System.IO.FileInfo]$AboutPath
        [System.IO.FileInfo]$ManifestPath
    }
    
    process {
        foreach ($CategoryName in $CategoryNames) {
            $CategoryNameNoSpaces = $CategoryName.Replace(" ", "")
            $FullName = "$CategoryPrefix$CategoryNameNoSpaces"
            $FullPath = "$TargetDirectory\$FullName"
            $AboutPath = "$FullPath\About\About.xml"
            $ManifestPath = "$FullPath\About\Manifest.xml"

            # Create the new directory and populate it from the template
            if (-Not (Test-Path -Path $FullPath -PathType Container)) {
                New-Item -Path $TargetDirectory -Name $FullName -ItemType Container
                Copy-Item -Path $TemplatePath -Destination $FullPath -Recurse
            }
            else {
                throw "The directory $FullPath already exists"
            }

            # Build the packageId
            if (-Not $PackageId_Category) {
                $PackageId = Join-String -Separator "." -InputObject ($AuthorNoSpaces, $CategoryNameNoSpaces)
            }
            else {
                $PackageId = Join-String -Separator "." -InputObject ($AuthorNoSpaces, $PackageId_Category, $CategoryNameNoSpaces)
            }

            # Check if ForceDescription was provided
            if ($ForceDescription) {
                $Description = $ForceDescription
            }
            else {
                $Description = Read-Host -Prompt "Input a description for $CategoryName"
            }

            # Get load after input and attempt to strip out any spaces, just to be safe
            $LoadAfter = ""
            while (1) {
                Read-Host -Prompt ($LoadAfterPrompt -f $CategoryName) | Set-Variable lineA
                if (-Not $lineA) {break}
                $lineA.Replace(" ", "") | Set-Variable lineA
                Set-Variable LoadAfter -Value ("$LoadAfter`n        <li>$lineA</li>") # 8 spaces
            }
            if ($LoadAfter) {
                $LoadAfter = $LoadAfter.Trim()
            }

            Write-Host "`n"

            # Get load before input and attempt to strip out any spaces, just to be safe
            $LoadBefore = ""
            while (1) {
                Read-Host -Prompt ($LoadBeforePrompt -f $CategoryName) | Set-Variable lineB
                if (-Not $lineB) {break}
                $lineB.Replace(" ", "") | Set-Variable lineB
                Set-Variable LoadBefore -Value ("$LoadBefore`n        <li>$lineB</li>") # 8 spaces
            }
            if ($LoadBefore) {
                $LoadBefore = $LoadBefore.Trim()
            }

            # Load the About.xml and Manifest.xml files
            $About = Get-Content -Path $AboutPath
            $Manifest = Get-Content -Path $ManifestPath

            # Update the About.xml file
            $About = $About.Replace("PS_MODNAME", $CategoryName.ToUpper())
            $About = $About.Replace("PS_MODAUTHOR", $Author)
            $About = $About.Replace("PS_MODPACKAGEID", $PackageId)
            $About = $About.Replace("PS_MODDESCRIPTION", $Description)
            $About = $About.Replace("PS_LOADAFTER", $LoadAfter)
            $About | Set-Content -Path $AboutPath
            
            #Update the Manifest.xml file
            $Manifest = $Manifest.Replace("PS_MANIFESTIDENTIFIER", $PackageId)
            $Manifest = $Manifest.Replace("PS_LOADBEFORE", $LoadBefore)
            $Manifest | Set-Content -Path $ManifestPath

            Write-Host "Successfully created category mod for $CategoryName at $FullPath"
        }
    }
    
    end {
        Write-Host "All operations complete"
    }
}

New-ModCategory -PackageId_Category "ModCategories" -TargetDirectory ".\Categories" -ForceDescription (Get-Content -Path ".\Resources\Mod-Description.txt" -Raw)
