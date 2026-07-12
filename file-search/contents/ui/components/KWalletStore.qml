import QtQuick
import org.kde.plasma.workspace.dbus as DBus

// Native session-bus KWallet bridge. Secrets remain QML/DBus values and are
// never embedded in a shell command, process argv, environment, or temp file.
QtObject {
    id: store

    readonly property string serviceName: "org.kde.kwalletd6"
    readonly property string objectPath: "/modules/kwalletd6"
    readonly property string interfaceName: "org.kde.KWallet"
    readonly property string applicationId: "com.mcc45tr.filesearch"
    readonly property string folderName: "com.mcc45tr.filesearch"

    property var operationQueue: []
    property bool operationActive: false

    function isSupportedEntry(entry) {
        return entry === "weatherApiKey" || entry === "weatherApiKey2"
    }

    function makeMessage(member, signature, args) {
        return {
            service: serviceName,
            path: objectPath,
            iface: interfaceName,
            member: member,
            signature: signature,
            arguments: args || []
        } as DBus.dbusMessage
    }

    function call(member, signature, args, callback) {
        var reply = DBus.SessionBus.asyncCall(makeMessage(member, signature, args))
        reply.finished.connect(function() {
            var ok = reply.isValid && !reply.isError
            var value = ok ? reply.value : null
            reply.destroy()
            callback(ok, value)
        })
    }

    function enqueue(action, entry, value, callback) {
        if (!isSupportedEntry(entry)) {
            if (callback) Qt.callLater(function() { callback(false, "") })
            return
        }
        var queue = operationQueue.slice()
        queue.push({ action: action, entry: entry, value: String(value || ""), callback: callback })
        operationQueue = queue
        pump()
    }

    function read(entry, callback) {
        enqueue("read", entry, "", callback)
    }

    function write(entry, value, callback) {
        enqueue("write", entry, value, callback)
    }

    function pump() {
        if (operationActive || operationQueue.length === 0)
            return
        operationActive = true
        var queue = operationQueue.slice()
        var request = queue.shift()
        operationQueue = queue
        openWallet(function(ok, handle) {
            if (!ok || Number(handle) < 0) {
                finish(request, false, "")
                return
            }
            ensureFolder(Number(handle), function(folderOk) {
                if (!folderOk) {
                    closeWallet(Number(handle), function() { finish(request, false, "") })
                    return
                }
                if (request.action === "read") {
                    call("readPassword", "isss", [Number(handle), folderName, request.entry, applicationId], function(readOk, secret) {
                        closeWallet(Number(handle), function() {
                            finish(request, readOk, readOk ? String(secret || "") : "")
                        })
                    })
                } else {
                    call("writePassword", "issss", [Number(handle), folderName, request.entry, request.value, applicationId], function(writeOk, result) {
                        closeWallet(Number(handle), function() {
                            finish(request, writeOk && Number(result) === 0, "")
                        })
                    })
                }
            })
        })
    }

    function openWallet(callback) {
        call("networkWallet", "", [], function(nameOk, walletName) {
            if (!nameOk || !walletName) {
                callback(false, -1)
                return
            }
            call("open", "sxs", [String(walletName), DBus.int64(0), applicationId], callback)
        })
    }

    function ensureFolder(handle, callback) {
        call("hasFolder", "iss", [handle, folderName, applicationId], function(ok, exists) {
            if (!ok) {
                callback(false)
            } else if (exists) {
                callback(true)
            } else {
                call("createFolder", "iss", [handle, folderName, applicationId], function(createOk, created) {
                    callback(createOk && !!created)
                })
            }
        })
    }

    function closeWallet(handle, callback) {
        call("close", "ibs", [handle, false, applicationId], function() {
            callback()
        })
    }

    function finish(request, ok, value) {
        operationActive = false
        if (request.callback)
            request.callback(ok, value)
        Qt.callLater(function() { pump() })
    }
}
