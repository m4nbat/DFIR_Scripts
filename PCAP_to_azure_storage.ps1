# Define variables
$storageAccountName = "yourstorageaccountname"
$storageContainerName = "yourcontainername"
$sasToken = "?sv=2022-02-xx&ss=bfqt&srt=sco&sp=rwdlacuptfx&se=2023-03-29T00:00:00Z&st=2022-03-28T00:00:00Z&spr=https&sig=yourSASToken"

# Define required modules
$requiredModules = "Az.Storage"

# Check for required modules and install if not found
$missingModules = $requiredModules | Where-Object {-not (Get-Module -Name $_ -ListAvailable)}
if ($missingModules) {
    Write-Host "Installing missing modules: $missingModules"
    Install-Module $missingModules -Scope CurrentUser -Force
}

# Download NetshToPcapng.exe if it doesn't exist
$netshToPcapngExePath = ".\NetshToPcapng.exe"
if (!(Test-Path $netshToPcapngExePath)) {
    $url = "https://github.com/microsoft/WindowsProtocolTestSuites/releases/latest/download/NetshToPcapng.exe"
    Invoke-WebRequest -Uri $url -OutFile $netshToPcapngExePath
}

# Start packet capture
netsh trace start capture=yes tracefile=$env:TEMP\capture.etl

# Wait for capture to complete
Start-Sleep -Seconds 10

# Stop packet capture
netsh trace stop

# Convert ETL to PcapNG format
$etlFile = "$env:TEMP\capture.etl"
$pcapngFile = "$env:TEMP\capture.pcapng"
New-Item -ItemType File -Path $pcapngFile -Force
.\NetshToPcapng.exe $etlFile $pcapngFile

# Upload capture file to Azure Storage
$context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
Set-AzStorageBlobContent -File $pcapngFile -Container $storageContainerName -Blob "capture.pcapng" -Context $context -Force

# Delete temporary files
Remove-Item $etlFile
Remove-Item $pcapngFile
