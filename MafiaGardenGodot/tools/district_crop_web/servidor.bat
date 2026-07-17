@echo off
cd /d "%~dp0"
echo Servidor local: http://localhost:8765
echo Abrí esa URL en el navegador si no se abre solo.
start "" "http://localhost:8765"
python -m http.server 8765
