@echo off
cd /d "%~dp0.."
python tools\district_crop_tool.py %*
pause
