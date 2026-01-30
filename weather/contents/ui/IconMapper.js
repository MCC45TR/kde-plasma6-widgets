.pragma library

function mapOpenWeatherIcon(code, iconCode, isDarkTheme) {
    var isNight = isDarkTheme || (iconCode && iconCode.endsWith("n"))

    if (code >= 200 && code < 300) {
        if (code <= 202) return "isolated_thunderstorms.svg"
        if (code <= 221) return isNight ? "isolated_scattered_thunderstorms_night.svg" : "isolated_scattered_thunderstorms_day.svg"
        return "strong_thunderstorms.svg"
    }

    if (code >= 300 && code < 400) {
        return "drizzle.svg"
    }

    if (code >= 500 && code < 600) {
        if (code === 500) return isNight ? "scattered_showers_night.svg" : "scattered_showers_day.svg"
        if (code === 501) return "showers_rain.svg"
        if (code >= 502) return "heavy_rain.svg"
        if (code === 511) return "sleet_hail.svg"
        if (code >= 520) return isNight ? "scattered_showers_night.svg" : "scattered_showers_day.svg"
    }

    if (code >= 600 && code < 700) {
        if (code === 600) return isNight ? "scattered_snow_showers_night.svg" : "scattered_snow_showers_day.svg"
        if (code === 601) return "showers_snow.svg"
        if (code === 602) return "heavy_snow.svg"
        if (code === 611 || code === 612 || code === 613) return "sleet_hail.svg"
        if (code === 615 || code === 616) return "mixed_rain_snow.svg"
        if (code === 620 || code === 621) return isNight ? "scattered_snow_showers_night.svg" : "scattered_snow_showers_day.svg"
        if (code === 622) return "heavy_snow.svg"
    }

    if (code >= 700 && code < 800) {
        if (code === 701 || code === 741) return "haze_fog_dust_smoke.svg"
        if (code === 711) return "haze_fog_dust_smoke.svg"
        if (code === 721) return "haze_fog_dust_smoke.svg"
        if (code === 731 || code === 751 || code === 761) return "haze_fog_dust_smoke.svg"
        if (code === 762) return "haze_fog_dust_smoke.svg"
        if (code === 771) return "windy.svg"
        if (code === 781) return "tornado.svg"
    }

    if (code === 800) {
        return isNight ? "clear_night.svg" : "clear_day.svg"
    }

    if (code >= 801 && code <= 804) {
        if (code === 801) return isNight ? "mostly_clear_night.svg" : "mostly_clear_day.svg"
        if (code === 802) return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg"
        if (code === 803) return isNight ? "mostly_cloudy_night.svg" : "mostly_cloudy_day.svg"
        if (code === 804) return "cloudy.svg"
    }

    return isNight ? "clear_night.svg" : "clear_day.svg"
}

function mapWeatherAPIIcon(code, isDarkTheme) {
    var suffix = isDarkTheme ? "_day.svg" : "_day.svg"

    if (code === 1000) return "clear_day.svg"
    if (code === 1003) return "partly_cloudy_day.svg"
    if (code === 1006) return "cloudy.svg"
    if (code === 1009) return "cloudy.svg"
    if (code === 1030) return "haze_fog_dust_smoke.svg"
    if (code === 1063) return "scattered_showers_day.svg"
    if (code === 1066) return "scattered_snow_showers_day.svg"
    if (code === 1069) return "sleet_hail.svg"
    if (code === 1072) return "drizzle.svg"
    if (code === 1087) return "isolated_thunderstorms.svg"
    if (code === 1114 || code === 1117) return "blowing_snow.svg"
    if (code === 1135 || code === 1147) return "haze_fog_dust_smoke.svg"
    if (code === 1150 || code === 1153) return "drizzle.svg"
    if (code === 1168 || code === 1171) return "drizzle.svg"
    if (code === 1180 || code === 1183) return "scattered_showers_day.svg"
    if (code === 1186 || code === 1189) return "showers_rain.svg"
    if (code === 1192 || code === 1195) return "heavy_rain.svg"
    if (code === 1198 || code === 1201) return "sleet_hail.svg"
    if (code === 1204 || code === 1207) return "sleet_hail.svg"
    if (code === 1210 || code === 1213) return "scattered_snow_showers_day.svg"
    if (code === 1216 || code === 1219) return "showers_snow.svg"
    if (code === 1222 || code === 1225) return "heavy_snow.svg"
    if (code === 1237) return "sleet_hail.svg"
    if (code === 1240 || code === 1243) return "showers_rain.svg"
    if (code === 1246) return "heavy_rain.svg"
    if (code === 1249 || code === 1252) return "sleet_hail.svg"
    if (code === 1255 || code === 1258) return "showers_snow.svg"
    if (code === 1261 || code === 1264) return "sleet_hail.svg"
    if (code === 1273 || code === 1276) return "isolated_scattered_thunderstorms_day.svg"
    if (code === 1279 || code === 1282) return "strong_thunderstorms.svg"

    return "clear_day.svg"
}

function mapOpenMeteoIcon(code, isDarkTheme) {
    var isNight = isDarkTheme

    if (code === 0) return isNight ? "clear_night.svg" : "clear_day.svg"
    if (code === 1) return isNight ? "mostly_clear_night.svg" : "mostly_clear_day.svg"
    if (code === 2) return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg"
    if (code === 3) return "cloudy.svg"
    if (code === 45 || code === 48) return "haze_fog_dust_smoke.svg"
    if (code === 51 || code === 53 || code === 55) return "drizzle.svg"
    if (code === 56 || code === 57) return "drizzle.svg"
    if (code === 61) return "scattered_showers_day.svg"
    if (code === 63) return "showers_rain.svg"
    if (code === 65) return "heavy_rain.svg"
    if (code === 66 || code === 67) return "sleet_hail.svg"
    if (code === 71) return "scattered_snow_showers_day.svg"
    if (code === 73) return "showers_snow.svg"
    if (code === 75) return "heavy_snow.svg"
    if (code === 77) return "sleet_hail.svg"
    if (code === 80 || code === 81 || code === 82) return "showers_rain.svg"
    if (code === 85 || code === 86) return "showers_snow.svg"
    if (code === 95) return "isolated_thunderstorms.svg"
    if (code === 96 || code === 99) return "strong_thunderstorms.svg"

    return "clear_day.svg"
}

function getWeatherIcon(code, iconCode, provider, isDarkTheme) {
    if (provider === "weatherapi") {
        return mapWeatherAPIIcon(code, isDarkTheme)
    } else if (provider === "openmeteo") {
        return mapOpenMeteoIcon(code, isDarkTheme)
    } else {
        return mapOpenWeatherIcon(code, iconCode, isDarkTheme)
    }
}

function mapToV1(filename) {
    if (filename === "heavy_rain.svg") return "rain_heavy.png"
    if (filename === "heavy_snow.svg") return "snow_heavy.png"
    if (filename === "partly_cloudy_day.svg") return "sunny_s_cloudy.png"
    if (filename === "partly_cloudy_night.svg") return "cloudy.png"
    if (filename === "scattered_showers_day.svg") return "rain_s_sunny.png"
    if (filename === "scattered_showers_night.svg") return "rain_light.png"
    if (filename === "clear_day.svg") return "sunny.png"
    if (filename === "clear_night.svg") return "sunny.png"
    if (filename.startsWith("isolated_scattered_thunderstorms")) return "thunderstorms.png"
    if (filename === "cloudy.svg") return "cloudy.png"
    if (filename === "drizzle.svg") return "rain_light.png"

    return filename.replace(".svg", ".png").replace("haze_fog_dust_smoke", "fog")
}

function mapToV3(filename) {
    if (filename === "clear_day.svg") return "sunny.svg"
    if (filename === "clear_night.svg") return "clear.svg"

    if (filename === "partly_cloudy_day.svg") return "partly_cloudy.svg"
    if (filename === "partly_cloudy_night.svg") return "partly_clear.svg"

    if (filename === "mostly_clear_day.svg") return "mostly_sunny.svg"
    if (filename === "mostly_clear_night.svg") return "mostly_clear.svg"
    if (filename === "mostly_cloudy_day.svg") return "mostly_cloudy.svg"
    if (filename === "mostly_cloudy_night.svg") return "mostly_cloudy_night.svg"

    if (filename === "scattered_showers_day.svg" || filename === "scattered_showers_night.svg") return "scattered_showers.svg"
    if (filename === "showers_rain.svg") return "showers.svg"
    if (filename === "heavy_rain.svg") return "showers.svg"

    if (filename === "scattered_snow_showers_day.svg" || filename === "scattered_snow_showers_night.svg") return "scattered_snow.svg"
    if (filename === "showers_snow.svg") return "snow_showers.svg"
    if (filename === "blowing_snow.svg") return "blowing_snow.svg"
    if (filename === "heavy_snow.svg") return "heavy_snow.svg"

    if (filename === "sleet_hail.svg") return "sleet_hail.svg"
    if (filename === "mixed_rain_snow.svg") return "wintry_mix.svg"

    if (filename === "haze_fog_dust_smoke.svg") return "fog.svg"

    if (filename === "isolated_thunderstorms.svg") return "isolated_tstorms.svg"
    if (filename.startsWith("isolated_scattered_thunderstorms")) return "isolated_tstorms.svg"
    if (filename === "strong_thunderstorms.svg") return "strong_tstorms.svg"

    if (filename === "windy.svg") return "wind.svg"
    if (filename === "tornado.svg") return "tornado.svg"
    if (filename === "cloudy.svg") return "cloudy.svg"
    if (filename === "drizzle.svg") return "drizzle.svg"

    return filename
}

function mapToSystem(filename) {
    if (filename === "clear_day.svg") return "weather-clear"
    if (filename === "clear_night.svg") return "weather-clear-night"

    if (filename === "partly_cloudy_day.svg") return "weather-few-clouds"
    if (filename === "partly_cloudy_night.svg") return "weather-few-clouds-night"

    if (filename === "mostly_cloudy_day.svg") return "weather-clouds"
    if (filename === "mostly_cloudy_night.svg") return "weather-clouds-night"

    if (filename === "cloudy.svg") return "weather-overcast"

    if (filename === "haze_fog_dust_smoke.svg") return "weather-fog"

    if (filename === "scattered_showers_day.svg") return "weather-showers-scattered"
    if (filename === "scattered_showers_night.svg") return "weather-showers-scattered-night"

    if (filename === "showers_rain.svg") return "weather-showers"
    if (filename === "heavy_rain.svg") return "weather-storm"

    if (filename === "drizzle.svg") return "weather-showers-scattered"

    if (filename === "sleet_hail.svg") return "weather-snow-rain"

    if (filename === "scattered_snow_showers_day.svg") return "weather-snow-scattered"
    if (filename === "scattered_snow_showers_night.svg") return "weather-snow-scattered-night"
    if (filename === "showers_snow.svg") return "weather-snow"
    if (filename === "heavy_snow.svg") return "weather-snow"

    if (filename === "isolated_thunderstorms.svg" || filename.startsWith("isolated_scattered_thunderstorms")) return "weather-storm"
    if (filename === "strong_thunderstorms.svg") return "weather-storm"

    if (filename === "windy.svg") return "weather-windy"
    if (filename === "tornado.svg") return "weather-tornado"

    return "weather-clear"
}

function getIconPath(code, iconCode, provider, isDarkTheme, iconPack) {
    var iconFile = getWeatherIcon(code, iconCode, provider, isDarkTheme)

    if (!iconPack || iconPack === "default") {
        return "../images/" + iconFile
    }

    if (iconPack === "system") {
        return mapToSystem(iconFile)
    }

    if (iconPack === "google_v3") {
        var v3File = mapToV3(iconFile)
        return "../images/google_v3/" + v3File
    }

    if (iconPack === "google_v2") {
        return "../images/google_v2/" + iconFile.replace(".svg", ".png")
    }

    if (iconPack === "google_v1") {
        var v1File = mapToV1(iconFile)
        return "../images/google_v1/" + v1File
    }

    return "../images/" + iconFile
}
