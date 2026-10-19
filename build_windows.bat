@echo off
setlocal
cd /d "%~dp0"
title A3N IPTV Player - Build

echo.
echo  ==========================================
echo     A3N IPTV Player  -  Windows build
echo  ==========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo  [!] Flutter is not installed or not in PATH.
  echo      Install it from https://docs.flutter.dev/get-started/install/windows
  goto :fail
)

if not exist "windows\runner" (
  echo  [1/4] Creating Windows project files...
  call flutter create --platforms=windows --org com.a3n --project-name a3n_iptv_player .
  if errorlevel 1 goto :fail
) else (
  echo  [1/4] Windows project files already exist.
)

if exist "assets\app_icon.ico" (
  copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
)

echo  [2/4] Downloading packages...
call flutter pub get
if errorlevel 1 goto :fail

echo  [3/4] Building release (first build takes a few minutes)...
call flutter build windows --release
if errorlevel 1 goto :fail

echo  [4/4] Done!
echo.
echo  Your app is in:  build\windows\x64\runner\Release
echo  Copy the WHOLE Release folder - the .exe needs the files next to it.
echo.
start "" "build\windows\x64\runner\Release"
pause
exit /b 0

:fail
echo.
echo  Build failed. Common fixes:
echo   - Turn on Developer Mode:  run  start ms-settings:developers
echo   - Install Visual Studio 2022 with "Desktop development with C++"
echo   - Run  flutter doctor  and fix anything marked with [X]
echo.
pause
exit /b 1
