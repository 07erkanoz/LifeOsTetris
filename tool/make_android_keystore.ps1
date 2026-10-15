<#
.SYNOPSIS
  Creates the Android upload key for LifeOS Küpler and stores it as GitHub
  repository secrets, so every CI build is signed with the same key.

.DESCRIPTION
  - Generates a random password and an upload keystore (RSA 2048, valid for
    10000 days, alias "upload") in a private folder under your user profile,
    outside the repository.
  - Writes a key.properties file next to it (the password lives only there).
  - Uploads ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
    ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD with `gh secret set`.

  Nothing secret is printed. Running it again reuses the existing key and only
  uploads the secrets again; it never replaces a key.

  Usage (from the repository root):
    powershell -ExecutionPolicy Bypass -File tool\make_android_keystore.ps1
#>
param(
    [string]$Repo = '07erkanoz/LifeOsTetris',
    [string]$KeyDir = (Join-Path $env:USERPROFILE '.android-keys\lifeos-kupler')
)

$ErrorActionPreference = 'Stop'
$Alias = 'upload'
$Keystore = Join-Path $KeyDir 'upload-keystore.jks'
$PropsFile = Join-Path $KeyDir 'key.properties'

function Find-Keytool {
    $candidates = @()
    $onPath = Get-Command keytool -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    if ($env:JAVA_HOME) { $candidates += Join-Path $env:JAVA_HOME 'bin\keytool.exe' }
    $candidates += @(
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    throw 'keytool bulunamadı. Android Studio kurulu olmalı ya da JAVA_HOME bir JDK''yı göstermeli.'
}

function Read-Properties([string]$path) {
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $path) {
        if ($line -match '^\s*([^#=]+?)\s*=\s*(.*)$') { $map[$Matches[1]] = $Matches[2] }
    }
    return $map
}

gh auth status *> $null
if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI oturumu yok. Önce: gh auth login' }

if ((Test-Path $Keystore) -and -not (Test-Path $PropsFile)) {
    throw "$Keystore var ama key.properties yok. Anahtar ezilmesin diye durdum; dosyaları kontrol et."
}

if (Test-Path $Keystore) {
    Write-Host "Mevcut anahtar kullanılıyor: $Keystore"
    $props = Read-Properties $PropsFile
    $password = $props['storePassword']
    $keyPassword = $props['keyPassword']
    $Alias = $props['keyAlias']
} else {
    $keytool = Find-Keytool
    New-Item -ItemType Directory -Force -Path $KeyDir | Out-Null

    # 32 random bytes as hex: strong, and safe in a properties file.
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    $password = -join ($bytes | ForEach-Object { $_.ToString('x2') })
    $keyPassword = $password  # PKCS12 keystores use one password for both.

    # Pass the password through the environment, not the command line.
    $env:KUPLER_KEYSTORE_PASS = $password
    try {
        & $keytool -genkeypair -noprompt `
            -keystore $Keystore -storetype PKCS12 `
            -alias $Alias -keyalg RSA -keysize 2048 -validity 10000 `
            -dname 'CN=LifeOS Kupler, O=LifeOS, C=TR' `
            -storepass:env KUPLER_KEYSTORE_PASS -keypass:env KUPLER_KEYSTORE_PASS
        if ($LASTEXITCODE -ne 0) { throw 'keytool anahtarı oluşturamadı.' }
    } finally {
        Remove-Item Env:\KUPLER_KEYSTORE_PASS -ErrorAction SilentlyContinue
    }

    # Same format as android/key.properties; forward slashes keep the path
    # valid in a properties file.
    $storePath = $Keystore -replace '\\', '/'
    @(
        "storeFile=$storePath",
        "storePassword=$password",
        "keyAlias=$Alias",
        "keyPassword=$keyPassword"
    ) | Set-Content -LiteralPath $PropsFile -Encoding ASCII
    Write-Host "Anahtar oluşturuldu: $Keystore"
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Keystore))
$secrets = [ordered]@{
    ANDROID_KEYSTORE_BASE64   = $base64
    ANDROID_KEYSTORE_PASSWORD = $password
    ANDROID_KEY_ALIAS         = $Alias
    ANDROID_KEY_PASSWORD      = $keyPassword
}
foreach ($name in $secrets.Keys) {
    gh secret set $name --repo $Repo --body $secrets[$name] | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "$name gizli değeri yüklenemedi." }
    Write-Host "GitHub secret yüklendi: $name"
}

Write-Host ''
Write-Host 'Tamam. Bundan sonraki her derleme bu anahtarla imzalanacak.' -ForegroundColor Green
Write-Host ''
Write-Host 'ÖNEMLİ: Bu klasörü güvenli bir yere yedekle (parola yöneticisi, şifreli disk):' -ForegroundColor Yellow
Write-Host "  $KeyDir"
Write-Host '  upload-keystore.jks  -> anahtarın kendisi'
Write-Host '  key.properties       -> parolası (yalnızca burada yazılı)'
Write-Host 'Anahtar ya da parolası kaybolursa aynı uygulamanın güncellemesi bir daha imzalanamaz.'
Write-Host 'Bu dosyaları asla depoya ekleme veya kimseyle paylaşma.'
Write-Host ''
Write-Host 'Yerelde imzalı sürüm derlemek istersen key.properties dosyasını android\ klasörüne kopyala (git onu yok sayar).'
