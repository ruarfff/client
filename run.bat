@ECHO OFF
setlocal enabledelayedexpansion enableextensions

:: Script needs to run in admin mode.
:: Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If error flag set, we do not have admin privileges.
if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else (
    call:GotAdmin
)

:: Properties

set WORKING_DIR=%~dp0

set ZIP=%WORKING_DIR%lib\7za920\7za.exe

set FSUTILS_DIR=%WORKING_DIR%fsUtils
set LOG_DIR=%WORKING_DIR%logs
set REPORT_DIR=%FSUTILS_DIR%\reports
set OUTPUT_DIR=%WORKING_DIR%fsUtils\output

set FSSCAN=%FSUTILS_DIR%\bin\fsScan.exe
set FSREPORT=%FSUTILS_DIR%\bin\fsReport.exe
set REPORT_CONFIG=%WORKING_DIR%config\report\CIFS.cfg

:: Parameter Variables
set ACTION=all
set LOCATION=C:\
set CONFIG=%WORKING_DIR%config\scan\scan-win.cfg
set DTL=%WORKING_DIR%DTLs\fsScan.dtl
set TAG=FSMA_RPT
set LOG=%LOG_DIR%\fsScan.log
set ERR=%LOG_DIR%\fsErrScan.log
set OUTPUT=%WORKING_DIR%fsReport.zip
set TEMP=%WORKING_DIR%tmp

:: Fetch command line arguments
:loop
if NOT "%1"=="" (
    if "%1"=="-h" (
        call :ShowHelp
        goto :end
    )
    if "%1"=="--help" (
        call :ShowHelp
        goto :end
    )
    if "%1"=="--action" (
        set ACTION=%2
        SHIFT
    )
    if "%1"=="-a" (
        set ACTION=%2
        SHIFT
    )
    if "%1"=="--location" (
        set LOCATION=%2
        SHIFT
    )
    if "%1"=="-l" (
        set LOCATION=%2
        SHIFT
    )
    if "%1"=="-cfg" (
        set CONFIG=%2
        SHIFT
    )
    if "%1"=="-dtl" (
        set DTL=%2
        SHIFT
    )
    if "%1"=="-tag" (
        set TAG=%2
        SHIFT
    )
    if "%1"=="-log" (
        set LOG=%2
        SHIFT
    )
    if "%1"=="-err" (
        set ERR=%2
        SHIFT
    )
    if "%1"=="--output" (
        set OUTPUT=%2
        SHIFT
    )
    if "%1"=="-o" (
        set OUTPUT=%2
        SHIFT
    )
    if "%1"=="-temp" (
        set TEMP=%2
        SHIFT
    )
    SHIFT
    goto :loop
)


echo WORKING_DIR = %WORKING_DIR%
echo FSUTILS_DIR = %FSUTILS_DIR%
echo LOG_DIR = %LOG_DIR%
echo REPORT_DIR = %REPORT_DIR%
echo FSSCAN = %FSSCAN%
echo fsReport= %FSREPORT%
echo REPORT_CONFIG = %REPORT_CONFIG%
echo ACTION = %ACTION%
echo LOCATION = %LOCATION%
echo CONFIG = %CONFIG%
echo DTL = %DTL%
echo TAG = %TAG%
echo LOG = %LOG%
echo ERR = %ERR%
echo OUTPUT = %OUTPUT%
echo TEMP = %TEMP%

:: Create any required directories if they don't exist
call :FileNameFromPath FINAL_LOG_DIR %LOG%
if not exist %FINAL_LOG_DIR% mkdir %FINAL_LOG_DIR%
call :FileNameFromPath FINAL_ERR_DIR %ERR%
if not exist %FINAL_ERR_DIR% mkdir %FINAL_ERR_DIR%
call :FileNameFromPath FINAL_DTL_DIR %DTL%
if not exist %FINAL_DTL_DIR% mkdir %FINAL_DTL_DIR%
if not exist %TEMP% mkdir %TEMP%


if %ACTION% == all (
    call :RunScan
    call :RunReport
    goto :end
)
if %ACTION% == scan (
    call :RunScan
    goto :end
)
if %ACTION% == report (
    call :RunReport
    goto :end
)
:: None of the above
echo Invalid action provided. Valid actions are scan, report or all.



:: End of execution
goto :end


:: Functions

:ShowHelp
(
    echo ***********************************************************************************
    echo *
    echo * FSMA Client - EMC FSMA Client File System Scanning and Reporting Utility
    echo *
    echo * FSMA Client [options] application [arguments]
    echo *
    echo * Options
    echo * --------
    echo * --action or -a : scan - report - all, default to all which is a scan and report
    echo * --location or -l : folder to scan, defaults to root file system
    echo * --output or -o : archive containing report output, defaults to \fsReport.zip
    echo * -cfg : location of scan config file, default to \scan.cfg
    echo * -dtl : path to DTL files, defaults to \DTLs\fsScan.dtl
    echo * -tag : tag to pass to scan, defaults to FSMA_RPT
    echo * -log : log files, default to \logs\fsScan.log
    echo * -err : error logs, default to \logs\fsErrScan.log
    echo * -temp : folder for temporary working files, defaults to \tmp
    echo *
    echo ***********************************************************************************
    goto :EOF
)

:FileNameFromPath <result> <filePath>
(
    set "%~1=%~dp2"
    goto :EOF
)

:RunScan
(
    if exist %FSSCAN% (
        echo Running command:
        echo %FSSCAN% %LOCATION% -dtl %DTL% -tag %TAG% -log %LOG% -err %ERR% -cfg %CONFIG%
        echo Please wait.......
        %FSSCAN% %LOCATION% -dtl %DTL% -tag %TAG% -log %LOG% -err %ERR% -cfg %CONFIG%
        echo Scan finished
    ) else (
        echo Error! Could not find fsScan executable
    )
    goto :EOF
)

:RunReport
(
    if exist %FSREPORT% (        

        echo Running command:
        echo %FSREPORT% -dtl %DTL% -cfg %REPORT_CONFIG%
        echo Please wait.......

        %FSREPORT% -dtl %DTL% -cfg %REPORT_CONFIG% -rdir %REPORT_DIR%

        echo Creating output file: %OUTPUT%

        rd /s /q %OUTPUT_DIR%
        mkdir %OUTPUT_DIR%

        xcopy /s /y %REPORT_DIR% %OUTPUT_DIR%
        xcopy /y %LOG% %OUTPUT_DIR%
        xcopy /y %ERR% %OUTPUT_DIR%

        echo %ZIP%
        pause

        %ZIP%  a %OUTPUT% %OUTPUT_DIR%

        rd /s /q fsUtils\output
        rd /s /q %REPORT_DIR%

        echo Reporting finished
        echo Outputs written to %OUTPUT%

    ) else (
        echo Error! Could not find fsReport executable
    )
    goto :EOF
)

:UACPrompt
(
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "%~s0", "%params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /b
)

:GotAdmin
(
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    cd /D "%~dp0"
    goto :EOF
)

:end
pause