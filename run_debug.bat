@echo off
cd /d "%~dp0"
if not exist "windows\runner" call flutter create --platforms=windows --org com.a3n --project-name a3n_iptv_player .
if exist "assets\app_icon.ico" copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
call flutter pub get
call flutter run -d windows
pause
