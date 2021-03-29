@ECHO OFF
CLS

for /f "tokens=*" %%f in ('wmic os get Caption /value ^| find "="') do set "%%f"
for /f "tokens=*" %%f in ('wmic os get CSDVersion /value ^| find "="') do set "%%f"
for /f "tokens=*" %%f in ('wmic os get SerialNumber /value ^| find "="') do set "%%f"

IF "%CSDVersion%"=="" SET CSDVersion=N/A

echo ^<^<^<windows_os_info:sep^(44^)^>^>^>
ECHO %Caption%,%CSDVersion%,%SerialNumber%