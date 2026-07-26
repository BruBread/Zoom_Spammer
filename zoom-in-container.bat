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
:: Note on the extension: this script can't actually detect whether it's
:: installed - there's no reliable way to check that from outside the
:: browser. If it's missing, Firefox opens each link as a SEARCH QUERY
:: instead of navigating to it (you'll see search results for something
:: like "ext+container:name=..." instead of Zoom). If that happens,
:: install the extension linked above and try again.
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

goto :main

:fail
echo.
echo ============================================================
echo  STOPPED: %~1
echo ============================================================
echo.
pause
exit /b 1

:main

set "BASE_NAME=%~1"
if "%BASE_NAME%"=="" set "BASE_NAME=Zoom"

:: --- Check PowerShell is available (used for encoding + timestamps) ---
where powershell >nul 2>nul
if errorlevel 1 (
    call :fail "PowerShell isn't available on this machine. This script uses it to URL-encode the link and generate timestamps. It ships with Windows by default - if it's missing, something unusual has been done to this system."
)

set /p "ZOOM_LINK=Enter the Zoom meeting link: "

if "%ZOOM_LINK%"=="" (
    call :fail "No link was entered. Re-run the script and paste a Zoom meeting link when prompted."
)

:: Light sanity check - warn (don't block) if it doesn't look like a Zoom URL
echo %ZOOM_LINK% | findstr /I "zoom.us" >nul
if errorlevel 1 (
    set /p "CONFIRM=That doesn't look like a typical zoom.us link. Continue anyway? [y/N] "
    if /i not "!CONFIRM!"=="y" (
        echo.
        echo Cancelled - no link matched a zoom.us domain and you chose not to continue.
        pause
        exit /b 0
    )
)

set /p "COUNT=How many containers do you want to join from? "

echo %COUNT%| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 (
    call :fail "'%COUNT%' isn't a whole number greater than 0. Enter a plain number like 1, 3, or 10."
)

if %COUNT% GTR 20 (
    set /p "CONFIRM2=That will open !COUNT! containers/tabs at once - continue? [y/N] "
    if /i not "!CONFIRM2!"=="y" (
        echo.
        echo Cancelled - you chose not to open !COUNT! containers at once.
        pause
        exit /b 0
    )
)

:: Force the web client (browser) join page instead of the app-launch page.
:: Standard invite links look like https://xxxx.zoom.us/j/1234567890?pwd=...
:: The web client equivalent is https://xxxx.zoom.us/wc/join/1234567890?pwd=...
set "WEB_LINK=%ZOOM_LINK:/j/=/wc/join/%"
if "%WEB_LINK%"=="%ZOOM_LINK%" (
    echo Note: link didn't match the standard /j/ pattern, opening it as-is.
)

:: --- Locate firefox.exe ---
set "FIREFOX_EXE="
where firefox >nul 2>nul
if not errorlevel 1 (
    set "FIREFOX_EXE=firefox"
) else if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" (
    set "FIREFOX_EXE=%ProgramFiles%\Mozilla Firefox\firefox.exe"
) else if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" (
    set "FIREFOX_EXE=%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"
)

if "%FIREFOX_EXE%"=="" (
    call :fail "Firefox wasn't found on PATH or in the usual Program Files locations. Either Firefox isn't installed (get it from https://www.mozilla.org/firefox/), or it's installed somewhere non-standard - if so, edit this script's FIREFOX_EXE detection to point at your firefox.exe directly."
)

:: --- URL-encode the link via PowerShell (same for every container) ---
set "ENCODED_URL="
for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "[uri]::EscapeDataString('%WEB_LINK%')"`) do set "ENCODED_URL=%%E"

if "%ENCODED_URL%"=="" (
    call :fail "PowerShell didn't return anything while encoding the link. Try running this manually to see the actual error: powershell -Command \"[uri]::EscapeDataString('%WEB_LINK%')\""
)

:: --- Timestamp shared across this run's containers ---
set "TIMESTAMP="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"`) do set "TIMESTAMP=%%T"

if "%TIMESTAMP%"=="" (
    call :fail "PowerShell didn't return a timestamp. Try running this manually to see the actual error: powershell -Command \"Get-Date -Format 'yyyyMMdd-HHmmss'\""
)

echo.
echo About to open !COUNT! container(s) in Firefox.
echo Reminder: if a search-results page opens instead of the Zoom meeting,
echo the "Open external links in a container" extension isn't installed.
echo Get it from: https://addons.mozilla.org/firefox/addon/open-url-in-container/
echo.

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

echo.
echo Done. If any tab shows search results instead of Zoom, see the
echo reminder above about the required Firefox extension.
echo.

endlocal
