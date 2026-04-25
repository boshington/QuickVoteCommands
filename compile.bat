@echo off
setlocal

set "PACKAGE_NAME=QuickVoteCommands"
set "ZIP_FILE=%PACKAGE_NAME%.zip"
set "OP_FILE=%PACKAGE_NAME%.op"

if exist "%ZIP_FILE%" del "%ZIP_FILE%"
if exist "%OP_FILE%" del "%OP_FILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'info.toml','src' -DestinationPath '%ZIP_FILE%' -Force"
if errorlevel 1 (
    echo Compile failed.
    exit /b 1
)

ren "%ZIP_FILE%" "%OP_FILE%"
echo Built %OP_FILE%
