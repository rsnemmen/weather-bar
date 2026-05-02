# Weather — SwiftBar / xbar Plugin

A lightweight SwiftBar/xbar plugin that displays current weather conditions in the macOS menu bar.

```
⛅ 68°F
---
📍 San Francisco
Conditions: Partly cloudy
Humidity: 72%
Wind: 12 mph
---
Updated: 14:30
```

## Features

- Shows temperature with a weather emoji in the menu bar
- Dropdown with city name, conditions, humidity, and wind speed
- Auto-detects location via IP geolocation — no configuration required
- Supports manual coordinates for pinpoint accuracy
- Fahrenheit or Celsius
- No API key needed — uses the free [Open-Meteo](https://open-meteo.com) API
- No external dependencies beyond standard macOS tools (`curl`, `bc`)

## Installation

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar) (or [xbar](https://github.com/matryer/xbar)).
2. Copy `weather.30m.sh` to your SwiftBar plugins directory.
3. Make it executable:
   ```sh
   chmod +x weather.30m.sh
   ```
4. SwiftBar will pick it up automatically and refresh every 30 minutes.

## Configuration

Open the plugin's variable editor in SwiftBar to set:

| Variable | Default | Description |
|---|---|---|
| `VAR_LATITUDE` | *(empty)* | Latitude — leave blank to auto-detect via IP |
| `VAR_LONGITUDE` | *(empty)* | Longitude — leave blank to auto-detect via IP |
| `VAR_UNIT` | `fahrenheit` | `fahrenheit` or `celsius` |

When coordinates are left blank, the plugin resolves your location from `ipinfo.io` and caches the result for 6 hours to avoid repeated lookups.

## How It Works

1. **Location** — resolves via `ipinfo.io/json` (IP-based geolocation) or user-supplied coordinates. Results are cached at `/tmp/swiftbar_weather_location.cache` for 6 hours.
2. **Weather data** — fetches current conditions from `api.open-meteo.com` using the WMO weather code, temperature, humidity, and wind speed fields.
3. **JSON parsing** — done with `sed` only; no `jq` required.
4. **Output** — formats the menu bar line and dropdown according to the SwiftBar plugin protocol.

## Dependencies

- `curl` — HTTP requests
- `bc` — floating-point math

Both ship with macOS.

## More SwiftBar plugins by the author

Small, glanceable menu bar utilities that stay out of the way until you need them:

- **[claude_code](https://github.com/rsnemmen/claude-code-xbar)** — Claude Code usage limits (5h, 7d windows) at a glance.
- **[codex_usage](https://github.com/rsnemmen/codex-usage-swiftbar)** — Codex/OpenAI usage limits (5h, 7d windows) at a glance.
- **[copilot-usage-tracker](https://github.com/rsnemmen/copilot-usage-tracker)** — GitHub Copilot premium request usage and monthly pacing.
- **[poe_balance](https://github.com/rsnemmen/poe-balance-xbar)** — Poe API balance, percentage, and spending pace vs. the billing cycle.
- **[weather](https://github.com/rsnemmen/weather-bar)** — Current conditions, temperature, humidity, and wind — no API key required.