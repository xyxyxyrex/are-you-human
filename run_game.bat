@echo off
setlocal
set "GODOT_EXE=%GODOT_BIN%"
if "%GODOT_EXE%"=="" (
    if exist "%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe"
)
if "%GODOT_EXE%"=="" (
    if exist "%~dp0.tools\godot\Godot_v4.7.2-stable_windows_arm64.exe" set "GODOT_EXE=%~dp0.tools\godot\Godot_v4.7.2-stable_windows_arm64.exe"
)
if "%GODOT_EXE%"=="" (
    where godot >nul 2>nul && set "GODOT_EXE=godot"
)
if "%GODOT_EXE%"=="" (
    if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe"
)
if "%GODOT_EXE%"=="" (
    echo Godot 4.7.2 not found locally. Running first-time setup...
    powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -SkipVerify
    set "GODOT_EXE=%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe"
)

if "%~1"=="" (
    start "" "%GODOT_EXE%" --path "%~dp0."
) else (
    "%GODOT_EXE%" --path "%~dp0." %*
)
