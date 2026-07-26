# Zoom_Spammer

A Windows batch script that opens a Zoom meeting link in **multiple, visually distinct Firefox containers** at once — one browser tab per "identity," each in its own isolated container. Useful for testing multi-participant scenarios, joining the same meeting from several accounts, or keeping Zoom sessions completely separate from your regular browsing profile.

The script forces the **web client** join flow (no Zoom desktop app launch) and creates brand-new containers on the fly, each with a distinct color and icon so they're easy to tell apart in the tab bar. It also checks its own prerequisites up front and explains exactly what's wrong if something's missing, rather than failing silently.

## How it works

1. Checks that PowerShell is available (used internally for encoding and timestamps).
2. Prompts for a Zoom meeting link.
3. Prompts for how many containers/tabs to open.
4. Rewrites the link from the app-launch format (`/j/...`) to the web-client format (`/wc/join/...`).
5. Locates `firefox.exe` (PATH or common install locations).
6. URL-encodes the link and generates a shared timestamp, verifying PowerShell actually returned something usable for both.
7. Prints a reminder about the required Firefox extension (see below) before opening anything.
8. For each container, builds an `ext+container:` URL with a unique name, color, and icon, then opens it in Firefox with a short delay between launches.

Containers cycle through 8 color/icon combinations (blue/fingerprint, turquoise/briefcase, green/dollar, yellow/cart, orange/gift, red/vacation, pink/food, purple/fruit), repeating if you request more than 8.

## Requirements

- **Windows** with `cmd.exe` and PowerShell available (PowerShell is used internally for timestamps and URL-encoding).
- **Firefox**, installed on PATH or in a standard Program Files location.
- **[Open external links in a container](https://addons.mozilla.org/firefox/addon/open-url-in-container/)** Firefox extension.
  - This is required — the more commonly known **Multi-Account Containers** extension alone does *not* register the `ext+container:` URL scheme this script depends on. You need both installed, but it's specifically the "Open external links in a container" companion extension that makes this work.
  - **Note:** the script cannot verify this extension is installed — there's no way to check that from outside the browser. If it's missing, Firefox will open each link as a *search query* instead of navigating to it (you'll see search results for something like `ext+container:name=...` instead of Zoom). The script prints a reminder about this every run, but can't detect the failure itself.

## Usage

```bat
zoom-in-container.bat [base_container_name]
```

- `base_container_name` is optional and defaults to `Zoom`.
- You'll be prompted interactively for:
  - The Zoom meeting link
  - How many containers to join from

Each container is named using the pattern:

```
<base_container_name>-<timestamp>-<index>
```

For example: `Zoom-20260726-134512-1`, `Zoom-20260726-134512-2`, etc.

### Example

```bat
> zoom-in-container.bat TeamStandup
Enter the Zoom meeting link: https://us02web.zoom.us/j/1234567890?pwd=abcdef
How many containers do you want to join from? 3

About to open 3 container(s) in Firefox.
Reminder: if a search-results page opens instead of the Zoom meeting,
the "Open external links in a container" extension isn't installed.
Get it from: https://addons.mozilla.org/firefox/addon/open-url-in-container/

Opening container TeamStandup-20260726-134512-1 (blue/fingerprint) via browser join...
Opening container TeamStandup-20260726-134512-2 (turquoise/briefcase) via browser join...
Opening container TeamStandup-20260726-134512-3 (green/dollar) via browser join...

Done. If any tab shows search results instead of Zoom, see the
reminder above about the required Firefox extension.
```

## Safety checks built in

- **PowerShell availability check** — stops immediately, with an explanation, if PowerShell can't be found (it's needed for encoding and timestamps).
- **Empty input guard** — stops with an explanation if no link is provided.
- **Zoom URL sanity check** — warns (but doesn't block) if the link doesn't contain `zoom.us`, giving you a chance to abort.
- **Container count validation** — requires a whole number greater than 0, and explains what was actually typed if it doesn't qualify.
- **Large-batch confirmation** — asks for confirmation before opening more than 20 containers/tabs at once.
- **Firefox detection** — checks PATH and both standard Program Files locations; if all three fail, explains that Firefox may not be installed (with a download link) or may be in a non-standard location.
- **Encoding/timestamp verification** — after each PowerShell call, checks that something was actually returned before proceeding, rather than silently building a broken URL.
- **Readable stop messages** — every stop point (errors and cancellations alike) prints a clear explanation and **pauses** before the window closes, so double-clicking the script directly won't cause the window to flash and vanish before you can read what happened.

## Notes and caveats

- **Unsigned link warning**: because this script sends unsigned links, the extension shows a one-time "are you sure?" confirmation popup before opening each one. This is expected clickjacking protection, not a bug.
- **Containers persist**: every run creates new containers that remain in Firefox's container list afterward — Firefox doesn't clean these up automatically. Periodically clear out old ones via Firefox's **Manage Containers** settings.
- If your link doesn't match the standard `/j/...` pattern, the script will note this and open the link as-is rather than failing.
- The script has no visibility into what happens inside Firefox after a tab opens — it can't confirm the extension is installed, that a container actually opened correctly, or that a meeting join succeeded. Anything past "the link was handed to Firefox" is outside what this script can see or report on.
