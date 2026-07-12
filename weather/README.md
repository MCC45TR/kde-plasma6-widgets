# MWeather

MWeather is a Plasma 6 weather widget supporting Open-Meteo, OpenWeatherMap and WeatherAPI.com.

## Privacy and credentials

- Automatic location detection is opt-in and contacts `ipinfo.io`, which receives the user's public IP address and returns a city. Manual location is the first-run default.
- OpenWeatherMap and WeatherAPI.com keys are stored as plain text in the Plasma widget configuration. Other processes running as the same user can read them, and configuration backups may include them.
- Weather requests are sent directly to the selected provider. API keys are required in provider query strings and are never written to widget logs.

Runtime forecast cache and notification cooldown state are stored separately from the Plasma configuration dialog state so applying settings cannot overwrite them.
