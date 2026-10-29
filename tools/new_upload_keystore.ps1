$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$android = Join-Path $root 'app\android'
$jks = Join-Path $android 'app\upload-keystore.jks'
$props = Join-Path $android 'key.properties'
if ((Test-Path $jks) -and (Test-Path $props)) {
  Write-Host '[OK] Upload keystore already exists. Leaving it in place.'
  exit 0
}
$keytool = $null
if ($env:JAVA_HOME) {
  $candidate = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
  if (Test-Path $candidate) { $keytool = $candidate }
}
if (-not $keytool) {
  $fallback = 'D:\KU\WEB\JAVA\jdk-21.0.8\bin\keytool.exe'
  if (Test-Path $fallback) { $keytool = $fallback }
}
if (-not $keytool) {
  $cmd = Get-Command keytool -ErrorAction SilentlyContinue
  if ($cmd) { $keytool = $cmd.Source }
}
if (-not $keytool) {
  Write-Error 'keytool not found. Install a JDK and set JAVA_HOME.'
  exit 1
}
$chars = [char[]]((48..57) + (65..90) + (97..122))
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 24
$rng.GetBytes($bytes)
$pass = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
& $keytool -genkeypair -v -keystore $jks -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass $pass -keypass $pass -dname 'CN=News, OU=News, O=News, L=Unknown, ST=Unknown, C=CN'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
@"
storePassword=$pass
keyPassword=$pass
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Set-Content -Path $props -Encoding ascii
Write-Host '[OK] Wrote app\android\app\upload-keystore.jks and app\android\key.properties'
Write-Host '[WARN] Those files are gitignored. Back them up. Losing them means you cannot update an installed release APK.'
