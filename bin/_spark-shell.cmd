@echo off
powershell -NoProfile -ExecutionPolicy RemoteSigned -command "%~dp0\spark-shell.ps1 %*; exit $lastexitcode"
