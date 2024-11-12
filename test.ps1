# Charger le type de manière explicite pour éviter l'erreur de type introuvable
Add-Type -AssemblyName System.Security

# Chemin du fichier Local State
$localStatePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"

# Vérifier si le fichier existe
if (-Not (Test-Path -Path $localStatePath)) {
    Write-Output "Le fichier Local State n'a pas été trouvé."
    exit
}

# Charger le contenu JSON du fichier Local State
$jsonData = Get-Content -Path $localStatePath -Raw | ConvertFrom-Json

# Récupérer la clé chiffrée en base64
$encryptedKeyBase64 = $jsonData.os_crypt.encrypted_key

# Décoder la clé chiffrée depuis base64
$encryptedKey = [System.Convert]::FromBase64String($encryptedKeyBase64)

# Supprimer les 5 premiers octets ("DPAPI" préfixe)
$encryptedKey = $encryptedKey[5..($encryptedKey.Length - 1)]

# Déchiffrer la clé en utilisant DPAPI
try {
    $decryptedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedKey, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)

    # Afficher la clé principale déchiffrée en hexadécimal (ou en base64 si vous préférez)
    $decryptedKeyHex = ($decryptedKey | ForEach-Object { $_.ToString("x2") }) -join ""
    Write-Output "Clé principale déchiffrée (Hex) : $decryptedKeyHex"

    # Optionnel : afficher la clé en base64
    $decryptedKeyBase64 = [Convert]::ToBase64String($decryptedKey)
    Write-Output "Clé principale déchiffrée (Base64) : $decryptedKeyBase64"
}
catch {
    Write-Output "Erreur lors du déchiffrement de la clé : $_"
}
