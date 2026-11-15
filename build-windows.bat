@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter was not found in PATH.
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
  echo [ERROR] Failed to apply the snapshot repo.
  exit /b 1
)

if not exist "app\assets\config" mkdir "app\assets\config"
if not exist "app\assets\data" mkdir "app\assets\data"
copy /Y "config\sources.yaml" "app\assets\config\sources.yaml" >nul
if exist "data\snapshot.json" (
  copy /Y "data\snapshot.json" "app\assets\data\snapshot.json" >nul
) else (
  echo [WARN] data\snapshot.json is missing. The exe will start without a bundled overseas snapshot.
)
copy /Y "resources\app_icon.ico" "app\windows\runner\resources\app_icon.ico" >nul

echo [INFO] Building the Windows release exe...
pushd app
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed.
  popd
  exit /b 1
)
call dart run flutter_launcher_icons
call flutter build windows --release
if errorlevel 1 (
  echo [ERROR] Windows build failed.
  popd
  exit /b 1
)
popd

set "WIN_OUT=%cd%\app\build\windows\x64\runner\Release"
if not exist "%WIN_OUT%\News.exe" (
  echo [ERROR] Release exe was not found: %WIN_OUT%\News.exe
  exit /b 1
)

echo [INFO] Copying the Visual C++ release runtime next to the exe...
call :bundle_vcruntime "%WIN_OUT%"
if errorlevel 1 (
  echo [WARN] Could not copy the VC++ runtime DLLs. The exe may ask for the Microsoft Visual C++ redistributable.
)

set "DIST=%cd%\dist\News-windows"
if exist "%DIST%" rmdir /s /q "%DIST%"
mkdir "%DIST%"
xcopy /E /I /Y "%WIN_OUT%" "%DIST%" >nul

echo [OK] Windows exe is ready.
echo     Folder: dist\News-windows\
echo     Exe:    dist\News-windows\News.exe
exit /b 0

:bundle_vcruntime
set "DEST=%~1"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" exit /b 1
set "CRT_LIST=%TEMP%\news-crt-path.txt"
"%VSWHERE%" -latest -find "VC\Redist\MSVC\*\x64\Microsoft.VC14*.CRT\msvcp140.dll" > "%CRT_LIST%"
set "CRT_DLL="
set /p CRT_DLL=<"%CRT_LIST%"
if not defined CRT_DLL exit /b 1
for %%i in ("%CRT_DLL%") do set "CRT_DIR=%%~dpi"
copy /Y "%CRT_DIR%msvcp140.dll" "%DEST%\" >nul
copy /Y "%CRT_DIR%vcruntime140.dll" "%DEST%\" >nul
if exist "%CRT_DIR%vcruntime140_1.dll" copy /Y "%CRT_DIR%vcruntime140_1.dll" "%DEST%\" >nul
if exist "%CRT_DIR%msvcp140_1.dll" copy /Y "%CRT_DIR%msvcp140_1.dll" "%DEST%\" >nul
if exist "%CRT_DIR%msvcp140_2.dll" copy /Y "%CRT_DIR%msvcp140_2.dll" "%DEST%\" >nul
exit /b 0
