// IconMapper.js - Maps weather condition codes to Google Weather icon filenames
.pragma library

// OpenWeatherMap condition codes to icon mapping
function mapOpenWeatherIcon(code, iconCode, isDarkTheme) {
    // iconCode format: "01d", "01n" (d=day, n=night)
    // In dark theme, use night icons for better visibility
    var isNight = isDarkTheme || (iconCode && iconCode.endsWith("n"))

    // Thunderstorm (200-232)
    if (code >= 200 && code < 300) {
        if (code <= 202) return "isolated_thunderstorms.svg"
        if (code <= 221) return isNight ? "isolated_scattered_thunderstorms_night.svg" : "isolated_scattered_thunderstorms_day.svg"
        return "strong_thunderstorms.svg"
    }

    // Drizzle (300-321)
    if (code >= 300 && code < 400) {
        return "drizzle.svg"
    }

    // Rain (500-531)
    if (code >= 500 && code < 600) {
        if (code === 500) return isNight ? "scattered_showers_night.svg" : "scattered_showers_day.svg"
        if (code === 501) return "showers_rain.svg"
        if (code >= 502) return "heavy_rain.svg"
        if (code === 511) return "sleet_hail.svg" // Freezing rain
        if (code >= 520) return isNight ? "scattered_showers_night.svg" : "scattered_showers_day.svg"
    }

    // Snow (600-622)
    if (code >= 600 && code < 700) {
        if (code === 600) return isNight ? "scattered_snow_showers_night.svg" : "scattered_snow_showers_day.svg"
        if (code === 601) return "showers_snow.svg"
        if (code === 602) return "heavy_snow.svg"
        if (code === 611 || code === 612 || code === 613) return "sleet_hail.svg"
        if (code === 615 || code === 616) return "mixed_rain_snow.svg"
        if (code === 620 || code === 621) return isNight ? "scattered_snow_showers_night.svg" : "scattered_snow_showers_day.svg"
        if (code === 622) return "heavy_snow.svg"
    }

    // Atmosphere (700-781)
    if (code >= 700 && code < 800) {
        if (code === 701 || code === 741) return "haze_fog_dust_smoke.svg"
        if (code === 711) return "haze_fog_dust_smoke.svg" // Smoke
        if (code === 721) return "haze_fog_dust_smoke.svg" // Haze
        if (code === 731 || code === 751 || code === 761) return "haze_fog_dust_smoke.svg" // Dust
        if (code === 762) return "haze_fog_dust_smoke.svg" // Volcanic ash
        if (code === 771) return "windy.svg" // Squalls
        if (code === 781) return "tornado.svg"
    }

    // Clear (800)
    if (code === 800) {
        return isNight ? "clear_night.svg" : "clear_day.svg"
    }

    // Clouds (801-804)
    if (code >= 801 && code <= 804) {
        if (code === 801) return isNight ? "mostly_clear_night.svg" : "mostly_clear_day.svg"
        if (code === 802) return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg"
        if (code === 803) return isNight ? "mostly_cloudy_night.svg" : "mostly_cloudy_day.svg"
        if (code === 804) return "cloudy.svg"
    }

    // Default fallback
    return isNight ? "clear_night.svg" : "clear_day.svg"
}

// WeatherAPI.com condition codes to icon mapping
function mapWeatherAPIIcon(code, isDarkTheme) {
    // Note: WeatherAPI has different codes
    // Reference: https://www.weatherapi.com/docs/weather_conditions.json
    // In dark theme, use day icons (lighter)
    var suffix = isDarkTheme ? "_day.svg" : "_day.svg" // Both use day for now

    if (code === 1000) return "clear_day.svg" // Sunny
    if (code === 1003) return "partly_cloudy_day.svg" // Partly cloudy
    if (code === 1006) return "cloudy.svg" // Cloudy
    if (code === 1009) return "cloudy.svg" // Overcast
    if (code === 1030) return "haze_fog_dust_smoke.svg" // Mist
    if (code === 1063) return "scattered_showers_day.svg" // Patchy rain
    if (code === 1066) return "scattered_snow_showers_day.svg" // Patchy snow
    if (code === 1069) return "sleet_hail.svg" // Patchy sleet
    if (code === 1072) return "drizzle.svg" // Patchy freezing drizzle
    if (code === 1087) return "isolated_thunderstorms.svg" // Thundery outbreaks
    if (code === 1114 || code === 1117) return "blowing_snow.svg" // Blowing snow
    if (code === 1135 || code === 1147) return "haze_fog_dust_smoke.svg" // Fog
    if (code === 1150 || code === 1153) return "drizzle.svg" // Drizzle
    if (code === 1168 || code === 1171) return "drizzle.svg" // Freezing drizzle
    if (code === 1180 || code === 1183) return "scattered_showers_day.svg" // Patchy light rain
    if (code === 1186 || code === 1189) return "showers_rain.svg" // Moderate rain
    if (code === 1192 || code === 1195) return "heavy_rain.svg" // Heavy rain
    if (code === 1198 || code === 1201) return "sleet_hail.svg" // Light/Heavy freezing rain
    if (code === 1204 || code === 1207) return "sleet_hail.svg" // Light/Heavy sleet
    if (code === 1210 || code === 1213) return "scattered_snow_showers_day.svg" // Patchy light snow
    if (code === 1216 || code === 1219) return "showers_snow.svg" // Moderate snow
    if (code === 1222 || code === 1225) return "heavy_snow.svg" // Heavy snow
    if (code === 1237) return "sleet_hail.svg" // Ice pellets
    if (code === 1240 || code === 1243) return "showers_rain.svg" // Light/Moderate rain shower
    if (code === 1246) return "heavy_rain.svg" // Torrential rain shower
    if (code === 1249 || code === 1252) return "sleet_hail.svg" // Light/Moderate sleet showers
    if (code === 1255 || code === 1258) return "showers_snow.svg" // Light/Moderate snow showers
    if (code === 1261 || code === 1264) return "sleet_hail.svg" // Light/Heavy ice pellet showers
    if (code === 1273 || code === 1276) return "isolated_scattered_thunderstorms_day.svg" // Patchy/Moderate thunder
    if (code === 1279 || code === 1282) return "strong_thunderstorms.svg" // Patchy/Moderate snow with thunder

    return "clear_day.svg" // Default
}

// Open-Meteo WMO Weather codes to icon mapping
function mapOpenMeteoIcon(code, isDarkTheme) {
    // WMO Weather interpretation codes (0-99)
    // Reference: https://open-meteo.com/en/docs
    // In dark theme, use night/dark variants for better contrast
    var isNight = isDarkTheme

    if (code === 0) return isNight ? "clear_night.svg" : "clear_day.svg" // Clear sky
    if (code === 1) return isNight ? "mostly_clear_night.svg" : "mostly_clear_day.svg" // Mainly clear
    if (code === 2) return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg" // Partly cloudy
    if (code === 3) return "cloudy.svg" // Overcast
    if (code === 45 || code === 48) return "haze_fog_dust_smoke.svg" // Fog
    if (code === 51 || code === 53 || code === 55) return "drizzle.svg" // Drizzle
    if (code === 56 || code === 57) return "drizzle.svg" // Freezing drizzle
    if (code === 61) return "scattered_showers_day.svg" // Slight rain
    if (code === 63) return "showers_rain.svg" // Moderate rain
    if (code === 65) return "heavy_rain.svg" // Heavy rain
    if (code === 66 || code === 67) return "sleet_hail.svg" // Freezing rain
    if (code === 71) return "scattered_snow_showers_day.svg" // Slight snow
    if (code === 73) return "showers_snow.svg" // Moderate snow
    if (code === 75) return "heavy_snow.svg" // Heavy snow
    if (code === 77) return "sleet_hail.svg" // Snow grains
    if (code === 80 || code === 81 || code === 82) return "showers_rain.svg" // Rain showers
    if (code === 85 || code === 86) return "showers_snow.svg" // Snow showers
    if (code === 95) return "isolated_thunderstorms.svg" // Thunderstorm
    if (code === 96 || code === 99) return "strong_thunderstorms.svg" // Thunderstorm with hail

    return "clear_day.svg" // Default
}

// Main mapping function
function getWeatherIcon(code, iconCode, provider, isDarkTheme) {
    if (provider === "weatherapi") {
        return mapWeatherAPIIcon(code, isDarkTheme)
    } else if (provider === "openmeteo") {
        return mapOpenMeteoIcon(code, isDarkTheme)
    } else {
        // Default to OpenWeatherMap mapping
        return mapOpenWeatherIcon(code, iconCode, isDarkTheme)
    }
}

// Get icon path
function getIconPath(code, iconCode, provider, isDarkTheme) {
    var iconFile = getWeatherIcon(code, iconCode, provider, isDarkTheme)
    return "../images/" + iconFile
}
