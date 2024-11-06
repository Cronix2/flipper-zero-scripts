import os
import json
import base64
import sqlite3
import shutil
import win32crypt
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from prettytable import PrettyTable
from colorama import Fore, init

# Initialiser Colorama
init(autoreset=True)


def decrypt_key(local_state_path):
    # Récupérer la clé secrète en lisant le fichier local_state
    with open(local_state_path, "r", encoding="utf-8") as f:
        local_state_data = json.load(f)

    encrypted_key_b64 = local_state_data["os_crypt"]["encrypted_key"]
    encrypted_key = base64.b64decode(encrypted_key_b64)
    encrypted_key = encrypted_key[5:]  # Supprimer les 5 premiers octets

    # Déchiffrer la clé avec CryptUnprotectData
    decrypted_key = win32crypt.CryptUnprotectData(encrypted_key, None, None, None, 0)[1]
    return decrypted_key


def decrypt_password(encrypted_password, key):
    # Extraction de l'IV, des données chiffrées, et du tag
    iv = encrypted_password[3:15]
    tag = encrypted_password[-16:]
    encrypted_password = encrypted_password[15:-16]

    # Initialiser le déchiffrement en mode GCM avec le tag
    cipher = Cipher(algorithms.AES(key), modes.GCM(iv, tag), backend=default_backend())
    decryptor = cipher.decryptor()
    decrypted_password = decryptor.update(encrypted_password) + decryptor.finalize()
    return decrypted_password


def get_passwords(login_data, key):
    # Copie temporaire du fichier de données
    shutil.copy2(login_data, "login_data.db")
    conn = sqlite3.connect("login_data.db")
    cursor = conn.cursor()
    cursor.execute("SELECT action_url, username_value, password_value FROM logins")

    # Initialiser le tableau d'affichage
    table = PrettyTable()
    table.field_names = ["Status", "URL", "Username", "Decrypted Password", "Error"]

    for url, username, encrypted_password in cursor.fetchall():
        status = ""
        error_message = ""

        if encrypted_password:
            try:
                # Décryptage du mot de passe
                decrypted_password = decrypt_password(encrypted_password, key)
                status = "V"
                table.add_row([
                    Fore.WHITE + status,
                    Fore.WHITE + url,
                    Fore.WHITE + username,
                    Fore.WHITE + decrypted_password.decode('utf-8', errors='ignore'),
                    ""
                ])
            except Exception as e:
                status = "X"
                error_message = str(e)
                table.add_row(
                    [Fore.YELLOW + status, Fore.YELLOW + url, Fore.YELLOW + username, "", Fore.YELLOW + error_message])

    conn.close()
    os.remove("login_data.db")
    return table


def main():
    login_data = input("Enter the path of login_data file: ")
    local_state = input("Enter the path of local_state file: ")

    # Obtenir la clé de déchiffrement
    key = decrypt_key(local_state)

    # Récupérer les mots de passe
    passwords_table = get_passwords(login_data, key)

    # Afficher les résultats
    print(passwords_table)


if __name__ == "__main__":
    main()
