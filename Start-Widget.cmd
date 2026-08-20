@echo off
chcp 65001 >nul
title Countdown Widget
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CountdownWidget.ps1"
