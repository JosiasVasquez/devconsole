@echo off
setlocal
call "%~dp0path.cmd" "%~dp0..\.."
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
start "PowerShell - Dev Console Portable" "%PS_EXE%" -NoLogo -ExecutionPolicy Bypass -NoExit -Command "$Host.UI.RawUI.WindowTitle = 'PowerShell - Dev Console Portable'"
exit