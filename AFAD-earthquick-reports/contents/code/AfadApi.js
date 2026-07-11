.pragma library

var API_ENDPOINT = "https://deprem.afad.gov.tr/apiv2/event/filter";

function fetchEarthquakes(callback, options) {
    var xhr = new XMLHttpRequest();
    var params = [];

    // Default to last 24 hours if no start date provided
    var endDate = new Date();
    var startDate = new Date();
    startDate.setHours(endDate.getHours() - 24);

    if (options && options.hours) {
        startDate = new Date();
        startDate.setHours(endDate.getHours() - options.hours);
    }

    // Format dates to YYYY-MM-DDThh:mm:ss
    function formatTime(date) {
        var y = date.getFullYear();
        var m = ('0' + (date.getMonth() + 1)).slice(-2);
        var d = ('0' + date.getDate()).slice(-2);
        var h = ('0' + date.getHours()).slice(-2);
        var min = ('0' + date.getMinutes()).slice(-2);
        var s = ('0' + date.getSeconds()).slice(-2);
        return y + "-" + m + "-" + d + "T" + h + ":" + min + ":" + s;
    }

    params.push("start=" + formatTime(startDate));
    params.push("end=" + formatTime(endDate));

    if (options && options.minMag) {
        params.push("minmag=" + options.minMag);
    }

    var limit = (options && options.limit) ? options.limit : 50;
    params.push("limit=" + limit);

    var url = API_ENDPOINT + "?" + params.join("&");

    console.log("Fetching AFAD data from: " + url);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var jsonResponse = JSON.parse(xhr.responseText);
                    callback(null, jsonResponse);
                } catch (e) {
                    callback("JSON Parse Error: " + e.message, null);
                }
            } else {
                callback("HTTP Error: " + xhr.status + " " + xhr.statusText, null);
            }
        }
    };

    xhr.open("GET", url);
    xhr.send();
}
