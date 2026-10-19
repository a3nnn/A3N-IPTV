@echo off
setlocal
cd /d "%~dp0"
title A3N IPTV Player - Make Setup

echo.
echo  ==========================================
echo     A3N IPTV Player  -  Make Setup.exe
echo  ==========================================
echo.

rem ---------- 1. Find Inno Setup (install it if missing) ----------
set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if exist "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe" set "ISCC=%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"

if not defined ISCC (
  echo  [1/4] Inno Setup not found - installing it...
  winget install --id JRSoftware.InnoSetup -e --accept-source-agreements --accept-package-agreements
  if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
  if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
  if exist "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe" set "ISCC=%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"
)
if not defined ISCC (
  echo.
  echo  [!] Could not install Inno Setup automatically.
  echo      Download it from https://jrsoftware.org/isdl.php , install it, then run this file again.
  goto :fail
)
echo  [1/4] Inno Setup found.

rem ---------- 2. Build the latest release ----------
echo  [2/4] Building the app (release)...
if exist "assets\app_icon.ico" copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
call flutter pub get
if errorlevel 1 goto :fail
call flutter build windows --release
if errorlevel 1 goto :fail

rem ---------- 3. Add Visual C++ runtime so it works on any PC ----------
echo  [3/4] Adding Visual C++ runtime files...
set "REL=build\windows\x64\runner\Release"
for %%F in (msvcp140.dll vcruntime140.dll vcruntime140_1.dll) do (
  if exist "%SystemRoot%\System32\%%F" copy /Y "%SystemRoot%\System32\%%F" "%REL%\" >nul
)

rem ---------- 4. Make Setup.exe ----------
echo  [4/4] Creating Setup.exe...
"%ISCC%" /Q installer.iss
if errorlevel 1 goto :fail

echo.
echo  Done! Your installer is in the "installer" folder.
echo  Send that one file to any Windows PC.
echo.
start "" "installer"
pause
exit /b 0

:fail
echo.
echo  Failed. Take a screenshot of this window and send it.
echo.
pause
exit /b 1
