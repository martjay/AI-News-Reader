@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter was not found in PATH.
  exit /b 1
)

if not exist "app\assets\icons\app_icon.png" (
  echo [ERROR] Missing app\assets\icons\app_icon.png.
  exit /b 1
)

echo [INFO] Applying snapshot repo if config\snapshot.repo exists...
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\apply_snapshot_repo.ps1"
if errorlevel 1 (
  echo [ERROR] Failed to apply the snapshot repo.
  exit /b 1
)

echo [INFO] Refreshing the overseas snapshot for the phone bundle...
pushd tools\aggregator
call dart pub get
if errorlevel 1 (
  echo [WARN] aggregator pub get failed. Keeping the existing data\snapshot.json.
) else (
  call dart run bin\aggregator.dart
  if errorlevel 1 echo [WARN] Snapshot fetch failed. Keeping the existing data\snapshot.json.
)
popd

if not exist "app\assets\config" mkdir "app\assets\config"
if not exist "app\assets\data" mkdir "app\assets\data"
copy /Y "config\sources.yaml" "app\assets\config\sources.yaml" >nul
if exist "data\snapshot.json" (
  copy /Y "data\snapshot.json" "app\assets\data\snapshot.json" >nul
) else (
  echo [ERROR] data\snapshot.json is missing. The phone bundle needs it.
  exit /b 1
)

if not exist "app\android\key.properties" (
  echo [INFO] Creating an upload keystore for release signing...
  powershell -NoProfile -ExecutionPolicy Bypass -File "tools\new_upload_keystore.ps1"
  if errorlevel 1 (
    echo [ERROR] Could not create the upload keystore. The APK was not built.
    exit /b 1
  )
)

echo [INFO] Building the Android release APK...
pushd app
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed.
  popd
  exit /b 1
)
call dart run flutter_launcher_icons
call flutter build apk --release
if errorlevel 1 (
  echo [ERROR] Android APK build failed.
  popd
  exit /b 1
)
popd

set "APK=%cd%\app\build\app\outputs\flutter-apk\app-release.apk"
if not exist "%APK%" (
  echo [ERROR] Release APK was not found: %APK%
  exit /b 1
)

set "DIST=%cd%\dist\News-android"
if not exist "%DIST%" mkdir "%DIST%"
copy /Y "%APK%" "%DIST%\app-release.apk" >nul

echo [OK] Android APK is ready.
echo     APK: dist\News-android\app-release.apk
exit /b 0
