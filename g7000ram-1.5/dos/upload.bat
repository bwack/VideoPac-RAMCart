@echo off
rem upload a file to the G7000RAM
rem usage: upload.bat file.rom baudrate filesize
rem You have to enter the filesize manually, I have not found a way to do it
rem automatically, sorry.

rem insert serial port here
set port=COM2

if "%2"=="19200" goto set19200
if "%2"=="9600" goto set9600
echo "Unknown Baudrate"
goto end

:set9600
mode %port%:9600,n,8,1 >NUL
goto label1

:set19200
mode %port%:19200,n,8,2 >NUL

:label1
if not exist %1 goto errnofile
if "%3"=="3072" goto send4
if "%3"=="6144" goto send2
if "%3"=="12288" goto send1
echo "Wrong filesize"
goto end

:send1
copy /b %1 %port%
goto end

:send2
copy /b %1+%1 %port%
goto end

:send4
copy /b %1+%1+%1+%1 %port%
goto end

:errnofile
echo "File not found"
:end
