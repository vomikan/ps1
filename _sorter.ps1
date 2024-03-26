# Get the path to the current working folder where the script is located
$currentFolder = Split-Path $MyInvocation.MyCommand.Path

# Specify the path to the folder with files using the current working folder
$sourceFolder = $currentFolder

# Get a list of all zip files in the specified folder
$zipFiles = Get-ChildItem -Path $sourceFolder -File | Where-Object { $_.Extension -eq '.zip' -and $_.Name -notlike "Sorted*" }

foreach ($zipFile in $zipFiles) {
    # Unzip the existing zip file to a temporary folder
    $folderName = $zipFile.BaseName + ".tmp"
    $fullPath = Join-Path $sourceFolder $folderName
    if (Test-Path $fullPath) {
        Write-Host "Directory already exists: $fullPath"
        Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Ignore
        Write-Host "$tempFolder removed successfully."
    }
    $tempFolder = New-Item -ItemType Directory -Path $sourceFolder -Name $folderName
    Expand-Archive -Path $zipFile.FullName -DestinationPath $tempFolder.FullName

    # Get a list of files with only ".png" and ".jpg" extensions in the temporary folder
    $files = Get-ChildItem -Path $tempFolder.FullName -File | Where-Object { $_.Extension -eq '.png' -or $_.Extension -eq '.jpg' }

    # Iterate through all files and move them to respective folders within the zip archive
    foreach ($file in $files) {
        $fileName = $file.Name
        $firstFolder = $fileName.Substring(7, 2)
        $secondFolder = $fileName.Substring(0, 9)
        
        $targetFolderPath = Join-Path -Path $firstFolder -ChildPath $secondFolder
        
        # Check if the target folder exists in the temporary folder, if not, create it
        $fullTargetFolderPath = Join-Path -Path $tempFolder.FullName -ChildPath $targetFolderPath
        if (-not (Test-Path -Path $fullTargetFolderPath)) {
            New-Item -Path $fullTargetFolderPath -ItemType Directory
        }
        
        # Move the file to the target folder within the zip archive
        Move-Item -Path $file.FullName -Destination (Join-Path -Path $tempFolder.FullName -ChildPath $targetFolderPath)
    }

    $archiveName = "Sorted_" + $zipFile.BaseName + ".zip"
    if (Test-Path -Path $archiveName){
        Remove-Item $archiveName -Force
        Write-Host "$archiveName removed successfully."
    }

    # Compress the sorted files into a zip archive
    $destinationArchive = Join-Path -Path $currentFolder -ChildPath ($archiveName)
    $sourcePath = Join-Path -Path $tempFolder -ChildPath "*"
    Compress-Archive -Path $sourcePath -DestinationPath $destinationArchive

    # Remove the temporary folder after processing
    Remove-Item -Path $tempFolder.FullName -Recurse -Force
}

#Start-Sleep -Seconds 10
