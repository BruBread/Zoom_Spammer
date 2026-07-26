# Zoom_Spammer

A Windows batch script that opens a Zoom meeting link in **multiple, visually distinct Firefox containers** at once — one browser tab per "identity," each in its own isolated container. Useful for testing multi-participant scenarios, joining the same meeting from several accounts, or keeping Zoom sessions completely separate from your regular browsing profile.

The script forces the **web client** join flow (no Zoom desktop app launch) and creates brand-new containers on the fly, each with a distinct color and icon so they're easy to tell apart in the tab bar.

## How it works

1. Prompts for a Zoom meeting link.
2. Prompts for how many containers/tabs to open.
3. Rewrites the link from the app-launch format (`/j/...`) to the web-client format (`/wc/join/...`).
4. Locates `firefox.exe` (PATH or common install locations).
5. For each container, builds an `ext+container:` URL with a unique name, color, and icon, then opens it in Firefox with a short delay between launches.

Containers cycle through 8 color/icon combinations (blue/fingerprint, turquoise/briefcase, green/dollar, yellow/cart, orange/gift, red/vacation, pink/food, purple/fruit), repeating if you request more than 8.

## Requirements

- **Windows** with `cmd.exe` and PowerShell available (PowerShell is used internally for timestamps and URL-encoding).
- **Firefox**, installed on PATH or in a standard Program Files location.
- **[Open external links in a container](https://addons.mozilla.org/firefox/addon/open-url-in-container/)** Firefox extension.
  - This is required — the more commonly known **Multi-Account Containers** extension alone does *not* register the `ext+container:` URL scheme this script depends on. You need both installed, but it's specifically the "Open external links in a container" companion extension that makes this work.

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
Opening container TeamStandup-20260726-134512-1 (blue/fingerprint) via browser join...
Opening container TeamStandup-20260726-134512-2 (turquoise/briefcase) via browser join...
Opening container TeamStandup-20260726-134512-3 (green/dollar) via browser join...
```

## Safety checks built in

- **Empty input guard** — exits with an error if no link is provided.
- **Zoom URL sanity check** — warns (but doesn't block) if the link doesn't contain `zoom.us`, giving you a chance to abort.
- **Container count validation** — requires a whole number greater than 0.
- **Large-batch confirmation** — asks for confirmation before opening more than 20 containers/tabs at once.

## Notes and caveats

- **Unsigned link warning**: because this script sends unsigned links, the extension shows a one-time "are you sure?" confirmation popup before opening each one. This is expected clickjacking protection, not a bug.
- **Containers persist**: every run creates new containers that remain in Firefox's container list afterward — Firefox doesn't clean these up automatically. Periodically clear out old ones via Firefox's **Manage Containers** settings.
- If your link doesn't match the standard `/j/...` pattern, the script will note this and open the link as-is rather than failing.
