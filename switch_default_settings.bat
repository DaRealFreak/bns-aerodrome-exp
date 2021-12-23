@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:FileNameFromPath <resultVar> <pathVar>
(
    set "%~1=%~dp2"
    exit /b
)

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell.exe -noninteractive -command "Get-Process 'BnS-Multi-Tool' | Format-List Path"`) DO (
    SET ProcessPath=%%F
)
:: remove the "Path : " from the powershell output
set MultiToolFilePath=%ProcessPath:Path : =%
call :FileNameFromPath MultiToolDirectory %MultiToolFilePath%

:: kill multi tool for gcd settings
wmic process where name="BnS-Multi-Tool.exe" call terminate

:: copy gcd settings
copy /b/v/y "%cd%\settings\multitool_qol_default.xml" "%USERPROFILE%\Documents\BnS\multitool_qol.xml"

:: get installation path of BnS and check if path exists
setlocal EnableDelayedExpansion
set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\NCWest\BnS_UE4" 

for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set AppPath=%%~bBNSR\Binaries\Win64
if not exist "%AppPath%" (
	echo "%AppPath% does not exist or is empty"
	pause
	exit /b 3
)

:: copy binloader.ini for t pose
copy /b/v/y "%cd%\settings\binloader_farm.ini" "%AppPath%\plugins\binloader.ini"

if exist "%MultiToolFilePath%" if exist "%MultiToolDirectory%" (
	pushd %MultiToolDirectory% && start %MultiToolFilePath%
)
