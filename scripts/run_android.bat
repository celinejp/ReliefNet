@echo off
REM ReliefNet — run on Android from Windows (CMD). Forwards all args to run_android.ps1.
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_android.ps1" %*
