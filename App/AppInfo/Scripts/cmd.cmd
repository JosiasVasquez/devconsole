@echo off
setlocal
call "%~dp0path.cmd" "%~dp0..\.."
set "CMD_EXE=%SystemRoot%\System32\cmd.exe"
if exist "%SystemRoot%\Sysnative\cmd.exe" set "CMD_EXE=%SystemRoot%\Sysnative\cmd.exe"
start "CMD - Dev Console Portable" "%CMD_EXE%"
exit