@echo off
setlocal

REM Navigate to the directory containing this script (build/docker)
cd /d "%~dp0"

echo Building and running in Docker...
docker-compose up --build builder

if %ERRORLEVEL% NEQ 0 (
    echo Docker build failed.
    exit /b %ERRORLEVEL%
)

echo Docker build complete.
endlocal
