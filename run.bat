@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter not found in PATH.
  exit /b 1
)

if not exist "app\pubspec.yaml" (
  echo [ERROR] Flutter app is missing.
  exit /b 1
)

if not exist "app\.dart_tool" (
  echo [INFO] Dependencies missing. Running install.bat...
  call "%~dp0install.bat"
  if errorlevel 1 exit /b 1
)

if exist "config\sources.yaml" copy /Y "config\sources.yaml" "app\assets\config\sources.yaml" >nul
if exist "data\snapshot.json" copy /Y "data\snapshot.json" "app\assets\data\snapshot.json" >nul

echo [INFO] Starting InkBrief (Windows)...
pushd app
call flutter run -d windows
if errorlevel 1 (
  echo [INFO] Windows device unavailable, using first available device...
  call flutter run
)
if errorlevel 1 ( echo [ERROR] flutter run failed. & popd & exit /b 1 )
popd
echo [OK] App exited.
exit /b 0
