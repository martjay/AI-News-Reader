@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter not found in PATH. Install Flutter and retry.
  exit /b 1
)
where dart >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Dart not found in PATH.
  exit /b 1
)

echo [INFO] Copying feed config into the Flutter app...
if not exist "app\assets\config" mkdir "app\assets\config"
if not exist "app\assets\data" mkdir "app\assets\data"
if not exist "app\assets\icons" mkdir "app\assets\icons"
copy /Y "config\sources.yaml" "app\assets\config\sources.yaml" >nul
copy /Y "data\snapshot.json" "app\assets\data\snapshot.json" >nul

echo [INFO] Installing news_core...
pushd packages\news_core
call dart pub get
if errorlevel 1 ( echo [ERROR] news_core pub get failed. & popd & exit /b 1 )
popd

echo [INFO] Installing aggregator...
pushd tools\aggregator
call dart pub get
if errorlevel 1 ( echo [ERROR] aggregator pub get failed. & popd & exit /b 1 )
popd

echo [INFO] Installing Flutter app...
pushd app
call flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed. & popd & exit /b 1 )
popd

echo [OK] Dependencies installed.
exit /b 0
