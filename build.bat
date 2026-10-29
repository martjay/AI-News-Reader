@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter not found in PATH.
  exit /b 1
)

if not exist "resources\app_icon.ico" (
  echo [ERROR] Missing resources\app_icon.ico. Generate the icon first.
  exit /b 1
)
if not exist "app\assets\icons\app_icon.png" (
  echo [ERROR] Missing app\assets\icons\app_icon.png.
  exit /b 1
)

echo [INFO] Applying snapshot repo if config\snapshot.repo exists...
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\apply_snapshot_repo.ps1"
if errorlevel 1 (
  echo [ERROR] snapshot repo apply failed.
  exit /b 1
)

echo [INFO] Refreshing overseas snapshot for the phone bundle...
pushd tools\aggregator
call dart pub get
if errorlevel 1 (
  echo [WARN] aggregator pub get failed; keeping existing data\snapshot.json
) else (
  call dart run bin\aggregator.dart
  if errorlevel 1 echo [WARN] Snapshot fetch failed; keeping existing data\snapshot.json
)
popd

if not exist "app\assets\config" mkdir "app\assets\config"
if not exist "app\assets\data" mkdir "app\assets\data"
copy /Y "config\sources.yaml" "app\assets\config\sources.yaml" >nul
copy /Y "data\snapshot.json" "app\assets\data\snapshot.json" >nul
copy /Y "resources\app_icon.ico" "app\windows\runner\resources\app_icon.ico" >nul

echo [INFO] Building Windows release with project icon...
pushd app
call flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed. & popd & exit /b 1 )
call dart run flutter_launcher_icons
call flutter build windows --release
if errorlevel 1 ( echo [ERROR] Windows build failed. & popd & exit /b 1 )
popd

set "WIN_OUT=%cd%\app\build\windows\x64\runner\Release"
if not exist "%WIN_OUT%\News.exe" (
  echo [ERROR] Release exe not found: %WIN_OUT%\News.exe
  exit /b 1
)

echo [INFO] Bundling Visual C++ Release runtime next to the exe...
call :bundle_vcruntime "%WIN_OUT%"
if errorlevel 1 (
  echo [WARN] Could not copy VC++ runtime DLLs. Users may need vc_redist.x64.exe from Microsoft.
)

set "DIST=%cd%\dist\News-windows"
if exist "%DIST%" rmdir /s /q "%DIST%"
mkdir "%DIST%"
xcopy /E /I /Y "%WIN_OUT%" "%DIST%" >nul
echo [INFO] Distributable copy: %DIST%
echo [WARN] Do not ship app\build\windows\x64\runner\Debug — that build needs MSVCP140D and will fail on user PCs.

if not exist "app\android\key.properties" (
  echo [INFO] Creating an upload keystore for release signing...
  powershell -NoProfile -ExecutionPolicy Bypass -File "tools\new_upload_keystore.ps1"
  if errorlevel 1 (
    echo [ERROR] Could not create the upload keystore. APK was not built.
    exit /b 1
  )
)

echo [INFO] Building Android APK...
pushd app
call flutter build apk --release
if errorlevel 1 ( echo [WARN] Android APK build failed. Windows build is still available. )
popd

echo [OK] Build complete.
echo     Windows: dist\News-windows\
echo     APK:     app\build\app\outputs\flutter-apk\app-release.apk
exit /b 0

:bundle_vcruntime
set "DEST=%~1"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" exit /b 1
set "CRT_DLL="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -find "VC\Redist\MSVC\*\x64\Microsoft.VC14*.CRT\msvcp140.dll"`) do set "CRT_DLL=%%i"
if not defined CRT_DLL exit /b 1
for %%i in ("%CRT_DLL%") do set "CRT_DIR=%%~dpi"
copy /Y "%CRT_DIR%msvcp140.dll" "%DEST%\" >nul
copy /Y "%CRT_DIR%vcruntime140.dll" "%DEST%\" >nul
if exist "%CRT_DIR%vcruntime140_1.dll" copy /Y "%CRT_DIR%vcruntime140_1.dll" "%DEST%\" >nul
if exist "%CRT_DIR%msvcp140_1.dll" copy /Y "%CRT_DIR%msvcp140_1.dll" "%DEST%\" >nul
if exist "%CRT_DIR%msvcp140_2.dll" copy /Y "%CRT_DIR%msvcp140_2.dll" "%DEST%\" >nul
exit /b 0
