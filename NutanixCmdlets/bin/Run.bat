:: Copyright (c) 2014 Nutanix Inc. All rights reserved.
::
:: Author : isha.singhal@nutanix.com
::
:: Description: Batch file to invoke the powershell script with appropriate
:: parameters.

:: Check if powershell is not installed in the system
:: If powershell is not installed, give an error message and exit the script
@echo off
if not exist "%systemroot%\system32\WindowsPowerShell\v1.0\powershell.exe" (
    echo "Powershell is not installed on the system."
    echo "Install powershell and try again."
    echo "Exiting script..."
    exit
)
:: Call the first Script buildAndImport.ps1 after setting the Execution Policy
:: as Unrestricted
SET powershell_script= %CD%\..\powershell\import_modules\PreReqCheckAndImport.ps1
PowerShell -ExecutionPolicy Unrestricted -Command "& '%powershell_script%'"
