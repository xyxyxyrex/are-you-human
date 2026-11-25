@echo off
setlocal
set "GODOT_EXE=%GODOT_BIN%"
if "%GODOT_EXE%"=="" (
    where godot >nul 2>nul && set "GODOT_EXE=godot"
)
if "%GODOT_EXE%"=="" (
    set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe"
)

if "%~1"=="" (
    start "" "%GODOT_EXE%" --path "%~dp0."
) else (
    "%GODOT_EXE%" --path "%~dp0." %*
)
