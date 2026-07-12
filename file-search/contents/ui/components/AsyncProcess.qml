import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

// Plasma 6 asynchronous process bridge backed by the plasma5support
// "executable" engine, the mechanism Plasma itself ships for widget process
// execution. The previous KRunner/Milou relay matched results by localized
// category names, so on non-English systems every command silently failed
// with exit code -1. This bridge is locale-independent, runs jobs
// concurrently, bounds output, and applies a watchdog timeout.
QtObject {
    id: runner

    property var jobs: ({})
    property int serial: 0
    property int timeoutMs: 60000
    property int maximumOutputChars: 262144

    function run(command, callback) {
        if (!command)
            return "";

        serial++;
        var token = "job_" + serial + "_" + Date.now();
        // The engine coalesces identical source strings into one process; a
        // trailing comment line keeps every job unique and individually
        // disconnectable without changing what the shell executes.
        var source = String(command) + "\n# " + token;
        jobs[token] = {
            "callback": callback || null,
            "source": source,
            "startedAt": Date.now()
        };
        executor.connectSource(source);
        if (!watchdogTimer.running)
            watchdogTimer.start();

        return token;
    }

    function runDetached(command) {
        run(command, null);
    }

    function finish(token, output, exitCode) {
        var job = jobs[token];
        if (!job)
            return;

        delete jobs[token];
        executor.disconnectSource(job.source);
        if (Object.keys(jobs).length === 0)
            watchdogTimer.stop();

        if (job.callback)
            job.callback(String(output || "").slice(0, maximumOutputChars), true, exitCode);

    }

    function cancelAll() {
        var tokens = Object.keys(jobs);
        for (var i = 0; i < tokens.length; i++) {
            executor.disconnectSource(jobs[tokens[i]].source);
        }
        jobs = ({});
        watchdogTimer.stop();
    }

    property Plasma5Support.DataSource executor: Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var tokens = Object.keys(runner.jobs);
            var token = "";
            for (var i = 0; i < tokens.length; i++) {
                if (runner.jobs[tokens[i]].source === sourceName) {
                    token = tokens[i];
                    break;
                }
            }
            if (!token) {
                disconnectSource(sourceName);
                return;
            }
            var exitCode = Number(data["exit code"]);
            if (!isFinite(exitCode))
                exitCode = -1;

            var output = String(data["stdout"] || "");
            if (!output && exitCode !== 0)
                output = String(data["stderr"] || "");

            runner.finish(token, output, exitCode);
        }
    }

    property Timer watchdogTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: {
            var now = Date.now();
            var tokens = Object.keys(runner.jobs);
            for (var i = 0; i < tokens.length; i++) {
                if (now - runner.jobs[tokens[i]].startedAt > runner.timeoutMs)
                    runner.finish(tokens[i], "", -2);

            }
        }
    }
}
