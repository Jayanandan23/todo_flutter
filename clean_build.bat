@echo off
echo ==================================================
echo   Flutter Windows Build Unlocker ^& Cleaner Utility
echo ==================================================
echo.
echo [1/4] Stopping Gradle background daemons...
if exist android (
    cd android
    call gradlew.bat --stop
    cd ..
)
echo.
echo [2/4] Terminating locked Java ^& Dart VM processes...
taskkill /F /IM java.exe /T 2>nul
taskkill /F /IM dart.exe /T 2>nul
taskkill /F /IM dartvm.exe /T 2>nul
echo.
echo [3/4] Purging build directories bypassing MAX_PATH limits...
rmdir /s /q "\\?\%~dp0build" 2>nul
rmdir /s /q "\\?\%~dp0.dart_tool" 2>nul
rmdir /s /q "\\?\%~dp0windows\flutter\ephemeral" 2>nul
rmdir /s /q "\\?\%~dp0ios\Flutter\ephemeral" 2>nul
echo.
echo [4/4] Fetching Flutter dependencies...
call flutter pub get
echo.
echo ==================================================
echo   Clean up finished! You can now run 'flutter run'
echo ==================================================
pause
