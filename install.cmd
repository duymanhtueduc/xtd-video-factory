@echo off
chcp 65001 >nul
title Cai dat MausBot Video Factory - Truong Xanh Tue Duc
echo ==============================================================
echo    DANG CHAY TRINH CAI DAT MAUSBOT VIDEO FACTORY CHO GIAO VIEN
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo Nhan phim bat ky de ket thuc...
pause >nul
