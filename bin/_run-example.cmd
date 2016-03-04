@echo off
powershell -NoProfile -ExecutionPolicy RemoteSigned -command "%~dp0\run-example.ps1 %*; exit $lastexitcode"
