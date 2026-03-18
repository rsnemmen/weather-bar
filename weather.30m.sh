#!/usr/bin/env bash
#<xbar.title>Weather</xbar.title>
#<xbar.version>1.0</xbar.version>
#<xbar.author>Rodrigo Nemmen da Silva</xbar.author>
#<xbar.desc>Display current weather conditions in the menu bar</xbar.desc>
#<xbar.dependencies>curl,bc</xbar.dependencies>

# User variables
#<xbar.var>string(VAR_LATITUDE=""): Latitude (empty = auto-detect via IP)</xbar.var>
#<xbar.var>string(VAR_LONGITUDE=""): Longitude (empty = auto-detect via IP)</xbar.var>
#<xbar.var>string(VAR_UNIT="fahrenheit"): Temperature unit (fahrenheit or celsius)</xbar.var>

LATITUDE="${VAR_LATITUDE:-}"
LONGITUDE="${VAR_LONGITUDE:-}"
UNIT="${VAR_UNIT:-fahrenheit}"

LOCATION_CACHE="/tmp/swiftbar_weather_location.cache"
CACHE_TTL=21600  # 6 hours in seconds

# === Helper functions ===

round() {
  printf "%.0f" "$(echo "scale=10; $1" | bc)"
}

weather_emoji() {
  local code="$1"
  case "$code" in
    0)            echo "☀️" ;;
    1)            echo "🌤️" ;;
    2)            echo "⛅" ;;
    3)            echo "☁️" ;;
    45|48)        echo "🌫️" ;;
    51|53|55)     echo "🌦️" ;;
    56|57)        echo "🌨️" ;;
    61|63|65)     echo "🌧️" ;;
    66|67)        echo "🌨️" ;;
    71|73|75|77)  echo "❄️" ;;
    80|81|82)     echo "🌧️" ;;
    85|86)        echo "🌨️" ;;
    95)           echo "⛈️" ;;
    96|99)        echo "⛈️" ;;
    *)            echo "🌡️" ;;
  esac
}

weather_description() {
  local code="$1"
  case "$code" in
    0)   echo "Clear sky" ;;
    1)   echo "Mainly clear" ;;
    2)   echo "Partly cloudy" ;;
    3)   echo "Overcast" ;;
    45)  echo "Foggy" ;;
    48)  echo "Icy fog" ;;
    51)  echo "Light drizzle" ;;
    53)  echo "Moderate drizzle" ;;
    55)  echo "Dense drizzle" ;;
    56)  echo "Light freezing drizzle" ;;
    57)  echo "Heavy freezing drizzle" ;;
    61)  echo "Slight rain" ;;
    63)  echo "Moderate rain" ;;
    65)  echo "Heavy rain" ;;
    66)  echo "Light freezing rain" ;;
    67)  echo "Heavy freezing rain" ;;
    71)  echo "Slight snow" ;;
    73)  echo "Moderate snow" ;;
    75)  echo "Heavy snow" ;;
    77)  echo "Snow grains" ;;
    80)  echo "Slight showers" ;;
    81)  echo "Moderate showers" ;;
    82)  echo "Violent showers" ;;
    85)  echo "Slight snow showers" ;;
    86)  echo "Heavy snow showers" ;;
    95)  echo "Thunderstorm" ;;
    96)  echo "Thunderstorm w/ hail" ;;
    99)  echo "Thunderstorm w/ heavy hail" ;;
    *)   echo "Unknown" ;;
  esac
}

show_error() {
  local indicator="$1"
  local message="$2"
  echo "${indicator} Weather"
  echo "---"
  echo "$message"
  exit 0
}

# === Location resolution ===

if [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
  CITY=""
else
  # Check cache
  USE_CACHE=false
  if [ -f "$LOCATION_CACHE" ]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$LOCATION_CACHE") ))
    if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
      USE_CACHE=true
    fi
  fi

  if [ "$USE_CACHE" = "true" ]; then
    LATITUDE=$(sed -n '1p' "$LOCATION_CACHE")
    LONGITUDE=$(sed -n '2p' "$LOCATION_CACHE")
    CITY=$(sed -n '3p' "$LOCATION_CACHE")
  else
    # Fetch from ipinfo.io
    GEO_RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 "https://ipinfo.io/json")
    if [ -z "$GEO_RESPONSE" ]; then
      show_error "?" "Could not determine location (no internet)"
    fi

    LOC=$(printf '%s\n' "$GEO_RESPONSE" | sed -n 's/.*"loc"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    CITY=$(printf '%s\n' "$GEO_RESPONSE" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "$LOC" ]; then
      show_error "?" "Could not parse location from ipinfo.io"
    fi

    LATITUDE="${LOC%%,*}"
    LONGITUDE="${LOC##*,}"

    # Write cache: lat, lon, city
    printf '%s\n%s\n%s\n' "$LATITUDE" "$LONGITUDE" "$CITY" > "$LOCATION_CACHE"
  fi
fi

if [ -z "$LATITUDE" ] || [ -z "$LONGITUDE" ]; then
  show_error "?" "No location available"
fi

# === Fetch weather ===

WEATHER_RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 \
  -w "\n%{http_code}" \
  "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&temperature_unit=${UNIT}&wind_speed_unit=kmh")

HTTP_CODE=$(printf '%s\n' "$WEATHER_RESPONSE" | tail -n 1)
BODY=$(printf '%s\n' "$WEATHER_RESPONSE" | sed '$d')

if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" = "000" ]; then
  show_error "?" "No internet connection"
elif [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  show_error "!" "API error: HTTP $HTTP_CODE"
fi

# Parse fields from JSON
TEMP=$(printf '%s\n' "$BODY" | sed -n 's/.*"temperature_2m"[[:space:]]*:[[:space:]]*\([0-9.-][0-9.-]*\).*/\1/p')
HUMIDITY=$(printf '%s\n' "$BODY" | sed -n 's/.*"relative_humidity_2m"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
WEATHER_CODE=$(printf '%s\n' "$BODY" | sed -n 's/.*"weather_code"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
WIND_KMH=$(printf '%s\n' "$BODY" | sed -n 's/.*"wind_speed_10m"[[:space:]]*:[[:space:]]*\([0-9.][0-9.]*\).*/\1/p')

if [ -z "$TEMP" ] || [ -z "$HUMIDITY" ] || [ -z "$WEATHER_CODE" ] || [ -z "$WIND_KMH" ]; then
  show_error "!" "Parse error: missing fields in API response"
fi

# Round temperature to integer
TEMP_INT=$(round "$TEMP")

# Wind speed: convert km/h → mph for fahrenheit (imperial)
if [ "$UNIT" = "fahrenheit" ]; then
  WIND=$(round "$(echo "scale=10; $WIND_KMH * 0.621371" | bc)")
  WIND_UNIT="mph"
else
  WIND=$(round "$WIND_KMH")
  WIND_UNIT="km/h"
fi

EMOJI=$(weather_emoji "$WEATHER_CODE")
DESCRIPTION=$(weather_description "$WEATHER_CODE")

# Unit symbol
if [ "$UNIT" = "fahrenheit" ]; then
  UNIT_CHAR="F"
else
  UNIT_CHAR="C"
fi

# === Menu bar output ===
echo "${EMOJI} ${TEMP_INT}°${UNIT_CHAR}"

# === Dropdown menu ===
echo "---"

if [ -n "$CITY" ]; then
  echo "📍 ${CITY}"
else
  echo "📍 ${LATITUDE}, ${LONGITUDE}"
fi

echo "Conditions: ${DESCRIPTION}"
echo "Humidity: ${HUMIDITY}%"
echo "Wind: ${WIND} ${WIND_UNIT}"
echo "---"
echo "Updated: $(date +%H:%M)"
