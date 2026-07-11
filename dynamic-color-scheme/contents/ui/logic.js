// Sun calculations based on https://en.wikipedia.org/wiki/Sunrise_equation
function getSunTimes(date, lat, lng) {
    const radian = Math.PI / 180;
    const dayOfYear = Math.floor((date - new Date(date.getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
    
    // Solar Noon
    const n = dayOfYear;
    const jDate = n - lng / 360;
    const l = (280.460 + 0.9856474 * jDate) % 360;
    const g = (357.528 + 0.9856003 * jDate) % 360;
    const lambda = (l + 1.915 * Math.sin(g * radian) + 0.020 * Math.sin(2 * g * radian)) % 360;
    const epsilon = 23.439 - 0.0000004 * jDate;
    const alpha = Math.atan2(Math.cos(epsilon * radian) * Math.sin(lambda * radian), Math.cos(lambda * radian)) / radian;
    
    const solarNoon = 12 + (lng - alpha) / 15; // Rough UTC noon
    
    // Declination
    const delta = Math.asin(Math.sin(epsilon * radian) * Math.sin(lambda * radian)) / radian;
    
    // Hour angle for sunset/sunrise (-0.833 is standard refraction)
    const cosH = (Math.sin(-0.833 * radian) - Math.sin(lat * radian) * Math.sin(delta * radian)) / (Math.cos(lat * radian) * Math.cos(delta * radian));
    
    if (cosH > 1) return { sunrise: null, sunset: null, noon: solarNoon }; // Always night
    if (cosH < -1) return { sunrise: null, sunset: null, noon: solarNoon }; // Always day
    
    const H = Math.acos(cosH) / radian;
    const sunrise = solarNoon - H / 15;
    const sunset = solarNoon + H / 15;
    
    return {
        sunrise: sunrise,
        sunset: sunset,
        noon: solarNoon
    };
}

function formatTime(decimalHours) {
    if (decimalHours === null) return "--:--";
    let h = Math.floor(decimalHours % 24);
    if (h < 0) h += 24;
    const m = Math.floor((decimalHours * 60) % 60);
    return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
}

function parseManualTime(timeStr) {
    const parts = timeStr.split(':');
    if (parts.length !== 2) return 0;
    return parseInt(parts[0]) + parseInt(parts[1]) / 60;
}
