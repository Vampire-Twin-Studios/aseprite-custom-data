# Define filenames
$zipName = "custom-data.zip"
$filesToZip = @("package.json", "custom-data.lua", "config.lua", "README.md", "types")

# Ensure we’re in the correct folder
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Remove existing zip if it exists
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
    Write-Host "Deleted existing $zipName"
}

# Create zip with required files
Compress-Archive -Path $filesToZip -DestinationPath $zipName
Write-Host "Created $zipName with:" $filesToZip
