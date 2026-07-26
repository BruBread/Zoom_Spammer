@echo off
setlocal EnableDelayedExpansion

:: zoom-in-container.bat
:: Prompts for a Zoom meeting link and how many separate Firefox
:: "containers" to join it from. Forces browser (web client) joins
:: instead of launching the Zoom desktop app, and opens each copy in a
:: BRAND-NEW, visually distinct container (via the "Open external links
:: in a container" extension's ext+container: URL scheme, which supports
:: creating containers on the fly).
::
:: Requirements:
::   - Firefox with the "Open external links in a container" extension
::     installed (https://addons.mozilla.org/firefox/addon/open-url-in-container/)
::     - Multi-Account Containers alone is NOT enough; this companion
::       extension is what actually registers the ext+container: URL scheme.
::   - PowerShell available (used for the timestamp and URL-encoding)
::   - Since this script sends unsigned links, the extension will show a
::     one-time "are you sure?" confirmation popup before opening each
::     one. That's expected behavior (a clickjacking protection), not a bug.
::
:: Note: every run creates new containers that stay in Firefox's
:: container list afterward (Firefox doesn't auto-delete them). Worth
:: clearing out old ones now and then via "Manage Containers".
::
:: Usage:
::   zoom-in-container.bat [base_container_name]
::
::   If base_container_name is omitted, defaults to "Zoom". Each
::   container is named e.g. "Zoom-20260726-134512-1", "...-2", etc.,
::   and cycles through 8 distinct colors/icons so they're easy to
::   tell apart in the tab bar.

set "BASE_NAME=%~1"
if "%BASE_NAME%"=="" set "BASE_NAME=Zoom"

set /p "ZOOM_LINK=Enter the Zoom meeting link: "

if "%ZOOM_LINK%"=="" (
    echo Error: no link provided.
    exit /b 1
)

:: Light sanity check - warn (don't block) if it doesn't look like a Zoom URL
echo %ZOOM_LINK% | findstr /I "zoom.us" >nul
if errorlevel 1 (
    set /p "CONFIRM=That doesn't look like a typical zoom.us link. Continue anyway? [y/N] "
    if /i not "!CONFIRM!"=="y" (
        echo Aborted.
        exit /b 1
    )
)

set /p "COUNT=How many containers do you want to join from? "

echo %COUNT%| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 (
    echo Error: enter a whole number greater than 0.
    exit /b 1
)

if %COUNT% GTR 20 (
    set /p "CONFIRM2=That will open !COUNT! containers/tabs at once - continue? [y/N] "
    if /i not "!CONFIRM2!"=="y" (
        echo Aborted.
        exit /b 1
    )
)

:: Force the web client (browser) join page instead of the app-launch page.
:: Standard invite links look like https://xxxx.zoom.us/j/1234567890?pwd=...
:: The web client equivalent is https://xxxx.zoom.us/wc/join/1234567890?pwd=...
set "WEB_LINK=%ZOOM_LINK:/j/=/wc/join/%"
if "%WEB_LINK%"=="%ZOOM_LINK%" (
    echo Note: link didn't match the standard /j/ pattern, opening it as-is.
)

:: Locate firefox.exe
where firefox >nul 2>nul
if not errorlevel 1 (
    set "FIREFOX_EXE=firefox"
) else if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" (
    set "FIREFOX_EXE=%ProgramFiles%\Mozilla Firefox\firefox.exe"
) else if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" (
    set "FIREFOX_EXE=%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"
) else (
    echo Error: firefox.exe not found on PATH or in common install locations.
    exit /b 1
)

:: URL-encode the link via PowerShell (same for every container, so only once)
for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "[uri]::EscapeDataString('%WEB_LINK%')"`) do set "ENCODED_URL=%%E"

:: Timestamp shared across this run's containers; the loop index makes each
:: one unique even when the whole batch fires within the same second.
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"`) do set "TIMESTAMP=%%T"

for /L %%i in (1,1,%COUNT%) do (
    set "CONTAINER_NAME=%BASE_NAME%-!TIMESTAMP!-%%i"

    set /a "IDX=(%%i-1) %% 8"
    if !IDX! EQU 0 (set "THISCOLOR=blue"      & set "THISICON=fingerprint")
    if !IDX! EQU 1 (set "THISCOLOR=turquoise" & set "THISICON=briefcase")
    if !IDX! EQU 2 (set "THISCOLOR=green"     & set "THISICON=dollar")
    if !IDX! EQU 3 (set "THISCOLOR=yellow"    & set "THISICON=cart")
    if !IDX! EQU 4 (set "THISCOLOR=orange"    & set "THISICON=gift")
    if !IDX! EQU 5 (set "THISCOLOR=red"       & set "THISICON=vacation")
    if !IDX! EQU 6 (set "THISCOLOR=pink"      & set "THISICON=food")
    if !IDX! EQU 7 (set "THISCOLOR=purple"    & set "THISICON=fruit")

    set "CONTAINER_URL=ext+container:name=!CONTAINER_NAME!&color=!THISCOLOR!&icon=!THISICON!&url=!ENCODED_URL!"
    echo Opening container !CONTAINER_NAME! ^(!THISCOLOR!/!THISICON!^) via browser join...
    start "" "%FIREFOX_EXE%" "!CONTAINER_URL!"

    :: Brief stagger so Firefox has time to register each new container
    :: before the next request comes in.
    ping -n 2 127.0.0.1 >nul
)

endlocal
