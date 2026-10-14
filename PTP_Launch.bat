@echo off
rem Protect the President launcher.
rem Place this file in the Quake 4\ABRACADABRA folder (or run it from anywhere with a default Steam install).
rem Only +set arguments: any other startup command (e.g. +disconnect, +map) makes the Steam build ask for a CD key.
set "Q4=%~dp0.."
if not exist "%Q4%\Quake4.exe" set "Q4=%ProgramFiles(x86)%\Steam\steamapps\common\Quake 4"
if not exist "%Q4%\Quake4.exe" (echo Quake4.exe not found. Put this file in the Quake 4\ABRACADABRA folder. & pause & exit /b 1)
cd /d "%Q4%"
start "" "Quake4.exe" +set fs_game ABRACADABRA
