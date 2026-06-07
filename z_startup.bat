set "LINK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\%~n0.lnk"
if not exist "%LINK%" (
    powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LINK%');$s.TargetPath='%~f0';$s.WorkingDirectory='%~dp0';$s.Save()"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f
)

cd %~dp0
start AutoHotkey64.exe keys.ahk
::start AutoHotkey64.exe StickyScreenshots.ahk

