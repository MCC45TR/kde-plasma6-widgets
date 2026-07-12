import QtCore
import QtQuick
import org.kde.milou as Milou

// Plasma 6-native asynchronous process bridge. The existing KRunner shell
// runner starts one queued command at a time; bounded output is returned via a
// private cache file, avoiding the Plasma 5 data-engine compatibility module.
QtObject {
    id: runner

    readonly property string cacheDirectory: normalizePath(StandardPaths.writableLocation(StandardPaths.CacheLocation))
        + "/com.mcc45tr.filesearch/processes"
    property var jobs: ({})
    property var queue: []
    property string activeToken: ""
    property int serial: 0
    property int timeoutMs: 60000
    property int maximumOutputChars: 262144

    function normalizePath(path) {
        return String(path || "").replace(/^file:\/\/\/?/, "/")
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function run(command, callback) {
        if (!command)
            return ""
        serial++
        var token = Date.now() + "_" + serial + "_" + Math.floor(Math.random() * 1000000000)
        var outputPath = cacheDirectory + "/" + token + ".out"
        var statusPath = cacheDirectory + "/" + token + ".status"
        var wrapper = "umask 077; mkdir -p " + shellQuote(cacheDirectory)
            + "; ( " + command + " ) >" + shellQuote(outputPath) + " 2>&1"
            + "; code=$?; printf '%s' \"$code\" >" + shellQuote(statusPath)
            + "; (sleep 5; rm -f " + shellQuote(outputPath) + " " + shellQuote(statusPath) + ") >/dev/null 2>&1 &"

        var nextJobs = Object.assign({}, jobs)
        nextJobs[token] = {
            callback: callback,
            outputPath: outputPath,
            statusPath: statusPath,
            query: "/bin/sh -c " + shellQuote(wrapper),
            startedAt: 0
        }
        jobs = nextJobs
        var nextQueue = queue.slice()
        nextQueue.push(token)
        queue = nextQueue
        pump()
        return token
    }

    function runDetached(command) {
        run(command, null)
    }

    function pump() {
        if (activeToken || queue.length === 0)
            return
        var nextQueue = queue.slice()
        activeToken = nextQueue.shift()
        queue = nextQueue
        var job = jobs[activeToken]
        if (!job) {
            activeToken = ""
            Qt.callLater(pump)
            return
        }
        job.startedAt = Date.now()
        shellModel.queryString = job.query
        launchTimer.restart()
    }

    function launchActive() {
        var token = activeToken
        var job = jobs[token]
        if (!job)
            return
        var selected = -1
        for (var row = 0; row < shellModel.rowCount(); row++) {
            var index = shellModel.index(row, 0)
            var decoration = String(shellModel.data(index, Qt.DecorationRole) || "")
            var category = String(shellModel.data(index, shellModel.CategoryRole) || "").toLowerCase()
            if (decoration.indexOf("terminal") !== -1 || category.indexOf("command") !== -1 || category.indexOf("shell") !== -1) {
                selected = row
                break
            }
        }
        if (selected < 0) {
            if (Date.now() - job.startedAt < 2000) {
                launchTimer.restart()
                return
            }
            finish(token, "", -1)
            return
        }
        shellModel.run(shellModel.index(selected, 0))
        shellModel.queryString = ""
        activeToken = ""
        if (!pollTimer.running)
            pollTimer.start()
        Qt.callLater(pump)
    }

    function readFile(path, callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE)
                callback(xhr.status === 200 || xhr.status === 0 ? xhr.responseText : null)
        }
        try {
            xhr.open("GET", "file://" + path + "?t=" + Date.now())
            xhr.send()
        } catch (error) {
            callback(null)
        }
    }

    function inspect(token) {
        var job = jobs[token]
        if (!job || token === activeToken || job.startedAt <= 0)
            return
        if (Date.now() - job.startedAt > timeoutMs) {
            finish(token, "", -2)
            return
        }
        readFile(job.statusPath, function(statusText) {
            if (statusText === null || !jobs[token])
                return
            var exitCode = Number(String(statusText).trim())
            if (!isFinite(exitCode))
                exitCode = -1
            readFile(job.outputPath, function(output) {
                finish(token, String(output || "").slice(0, maximumOutputChars), exitCode)
            })
        })
    }

    function finish(token, output, exitCode) {
        var job = jobs[token]
        if (!job)
            return
        var nextJobs = Object.assign({}, jobs)
        delete nextJobs[token]
        jobs = nextJobs
        if (token === activeToken) {
            shellModel.queryString = ""
            activeToken = ""
            Qt.callLater(pump)
        }
        if (job.callback)
            job.callback(output, true, exitCode)
        if (Object.keys(jobs).length === 0)
            pollTimer.stop()
    }

    function cancelAll() {
        jobs = ({})
        queue = []
        activeToken = ""
        shellModel.queryString = ""
        launchTimer.stop()
        pollTimer.stop()
    }

    property Milou.ResultsModel shellModel: Milou.ResultsModel {
        limit: 10
    }

    property Timer launchTimer: Timer {
        interval: 50
        repeat: false
        onTriggered: runner.launchActive()
    }

    property Timer pollTimer: Timer {
        interval: 150
        repeat: true
        onTriggered: {
            var tokens = Object.keys(runner.jobs)
            for (var i = 0; i < tokens.length; i++)
                runner.inspect(tokens[i])
        }
    }
}
