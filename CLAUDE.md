# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## What This Is

A SwiftBar/xbar plugin that displays current weather conditions in the macOS menu bar.

- **`weather.30m.sh`** — Bash script, the SwiftBar plugin (runs every 30 minutes). Fetches location via IP geolocation (ipinfo.io) or user-configured coordinates, then queries the Open-Meteo API for current conditions.

No build step required. No Python. No external package manager.

## Dependencies

- `curl` — HTTP requests
- `bc` — floating-point math (rounding, unit conversion)

Both are standard on macOS.

## Architecture Notes

- **Location**: resolved via `ipinfo.io/json` when coordinates are not set, with a 6-hour file cache at `/tmp/swiftbar_weather_location.cache` to avoid hammering the geo API.
- **Weather data**: `api.open-meteo.com` (free, no API key required).
- **JSON parsing**: done with `sed` (no `jq` dependency) — intentional, keep it that way.
- **Error handling**: always `exit 0` so SwiftBar shows the icon with an error indicator rather than disappearing.

## SwiftBar Output Protocol

- First `echo` line = menu bar text.
- `echo "---"` = separator between menu bar and dropdown.
- Subsequent lines = dropdown menu items.

## SwiftBar Plugin Variables

Configurable via SwiftBar's variable editor (`#<xbar.var>` comments):

| Variable | Default | Description |
|---|---|---|
| `VAR_LATITUDE` | `""` | Latitude (empty = auto-detect via IP) |
| `VAR_LONGITUDE` | `""` | Longitude (empty = auto-detect via IP) |
| `VAR_UNIT` | `"fahrenheit"` | `fahrenheit` or `celsius` |

## Lint

No linter configured. Shell script only — use `shellcheck weather.30m.sh` if desired.
