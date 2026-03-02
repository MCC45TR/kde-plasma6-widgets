import QtQuick
import Qt.labs.folderlistmodel 2.15

Item {
    id: fetcher
    
    // Inputs
    property string mprisArtUrl: ""
    property string trackUrl: ""
    property string artist: ""
    property string album: ""
    property string title: "" // Fallback if album is missing
    
    // Output
    property string effectiveArtUrl: ""
    
    // Internal state
    property string localArtUrl: ""
    property string onlineArtUrl: ""
    property string _cachedArtUrl: ""    // Last known good art URL
    property string _lastTrackKey: ""    // Dedup key for track changes
    property string _lastApiQuery: ""    // Dedup key for iTunes API
    
    // -------------------------------------------------------
    // URL Validation
    // -------------------------------------------------------
    function isValidArtUrl(url) {
        if (!url || url === "") return false
        if (url.indexOf("icon-") === 0) return false
        if (url === "file://") return false
        if (url === "file:///") return false
        // Accept file://, http://, https://, or absolute paths
        if (url.indexOf("file:///") === 0) return true
        if (url.indexOf("http://") === 0 || url.indexOf("https://") === 0) return true
        if (url.charAt(0) === "/") return true
        return false
    }
    
    // -------------------------------------------------------
    // Art URL Resolution (Priority Chain)
    // -------------------------------------------------------
    onMprisArtUrlChanged: evalEffectiveUrl()
    onLocalArtUrlChanged: evalEffectiveUrl()
    onOnlineArtUrlChanged: evalEffectiveUrl()
    
    function evalEffectiveUrl() {
        var newUrl = _resolveUrl()
        
        // Anti-flicker: if new URL is empty but we have a cached one,
        // keep showing the cached art during transition
        if (newUrl === "" && _cachedArtUrl !== "") {
            // Only keep cache for a brief window (transition safety)
            _cacheTimer.restart()
            effectiveArtUrl = _cachedArtUrl
            return
        }
        
        if (newUrl !== "") {
            _cachedArtUrl = newUrl
            _cacheTimer.stop()
        }
        effectiveArtUrl = newUrl
    }
    
    function _resolveUrl() {
        // 1. MPRIS (highest priority - direct from player)
        if (isValidArtUrl(mprisArtUrl)) {
            return mprisArtUrl
        }
        
        // 2. Local file (from track's directory)
        if (localArtUrl !== "") {
            return localArtUrl
        }
        
        // 3. Online (iTunes API fallback)
        if (onlineArtUrl !== "") {
            return onlineArtUrl
        }
        
        return ""
    }
    
    // Cache expiry timer - clear stale cache after 1.5 seconds
    Timer {
        id: _cacheTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (_resolveUrl() === "") {
                fetcher._cachedArtUrl = ""
                fetcher.effectiveArtUrl = ""
            }
        }
    }
    
    // Force re-evaluate (called on track change within same player)
    function refresh() {
        _cachedArtUrl = ""
        _cacheTimer.stop()
        evalEffectiveUrl()
    }
    
    // Full reset (called when player changes entirely)
    function clearAndRefresh() {
        _cachedArtUrl = ""
        _lastTrackKey = ""
        _lastApiQuery = ""
        onlineArtUrl = ""
        localArtUrl = ""
        _cacheTimer.stop()
        evalEffectiveUrl()
    }
    
    // -------------------------------------------------------
    // Local Art Fetching (file:// tracks only)
    // -------------------------------------------------------
    property string folderUrl: {
        if (!trackUrl || trackUrl.indexOf("file://") !== 0) return ""
        var path = trackUrl.toString()
        var lastSlash = path.lastIndexOf("/")
        if (lastSlash > 7) {
            return path.substring(0, lastSlash)
        }
        return ""
    }
    
    // Priority map for local file name matching
    // Lower number = higher priority
    readonly property var _localPriority: ({
        "cover": 1, "front": 2, "folder": 3,
        "album": 4, "artwork": 5, "thumb": 6
    })
    
    function _getFilePriority(fileName) {
        var lower = fileName.toLowerCase()
        for (var key in _localPriority) {
            if (lower.indexOf(key) !== -1) return _localPriority[key]
        }
        return 99 // Unknown image
    }
    
    FolderListModel {
        id: folderModel
        folder: fetcher.folderUrl
        nameFilters: [
            "cover.*", "Cover.*", "COVER.*",
            "front.*", "Front.*", "FRONT.*",
            "folder.*", "Folder.*", "FOLDER.*",
            "album.*", "Album.*", "ALBUM.*",
            "artwork.*", "Artwork.*", "ARTWORK.*",
            "thumb.*", "Thumb.*", "THUMB.*",
            "*.jpg", "*.jpeg", "*.png", "*.webp"
        ]
        showDirs: false
        showFiles: true
        
        onCountChanged: {
            if (folder == "" || count === 0) {
                fetcher.localArtUrl = ""
                return
            }
            
            var bestUrl = ""
            var bestPriority = 100
            var limit = Math.min(count, 20)
            
            for (var i = 0; i < limit; i++) {
                var name = get(i, "fileName")
                var url = get(i, "fileUrl")
                
                // Skip non-image files that might match glob
                var lower = name.toLowerCase()
                if (!lower.endsWith(".jpg") && !lower.endsWith(".jpeg") && 
                    !lower.endsWith(".png") && !lower.endsWith(".webp")) {
                    continue
                }
                
                var priority = fetcher._getFilePriority(name)
                if (priority < bestPriority) {
                    bestPriority = priority
                    bestUrl = url
                }
            }
            
            // If no priority match found but only one image exists, use it
            if (bestUrl === "" && count === 1) {
                var singleName = get(0, "fileName").toLowerCase()
                if (singleName.endsWith(".jpg") || singleName.endsWith(".jpeg") || 
                    singleName.endsWith(".png") || singleName.endsWith(".webp")) {
                    bestUrl = get(0, "fileUrl")
                }
            }
            
            fetcher.localArtUrl = bestUrl
        }
    }
    
    // -------------------------------------------------------
    // Online Art Fetching (iTunes API)
    // -------------------------------------------------------
    Timer {
        id: apiTimer
        interval: 1200
        repeat: false
        onTriggered: fetchOnlineArt()
    }
    
    onArtistChanged: {
        // Don't clear immediately - anti-flicker
        if (artist !== "") apiTimer.restart()
    }
    onAlbumChanged: {
        if (album !== "") apiTimer.restart()
    }
    
    // Clear online art only when track actually changes
    property string _trackIdentity: (artist || "") + "|" + (album || "") + "|" + (title || "")
    on_TrackIdentityChanged: {
        var newKey = _trackIdentity
        if (newKey !== _lastTrackKey) {
            _lastTrackKey = newKey
            // Only clear online if MPRIS doesn't provide art
            if (!isValidArtUrl(mprisArtUrl)) {
                onlineArtUrl = ""
                apiTimer.restart()
            }
        }
    }
    
    function fetchOnlineArt() {
        if (artist === "" || (album === "" && title === "")) return
        
        // Skip if MPRIS already provides valid art
        if (isValidArtUrl(mprisArtUrl)) return
        
        var term = artist + " " + (album || title)
        
        // Dedup: don't re-fetch same query
        if (term === _lastApiQuery && onlineArtUrl !== "") return
        _lastApiQuery = term
        
        var url = "https://itunes.apple.com/search?term=" + encodeURIComponent(term) + "&media=music&entity=album&limit=3"
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.timeout = 5000 // 5 second timeout
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        if (json.resultCount > 0) {
                            // Try to find best match by artist name
                            var bestResult = null
                            var artistLower = artist.toLowerCase()
                            
                            for (var i = 0; i < json.results.length; i++) {
                                var r = json.results[i]
                                if (r.artistName && r.artistName.toLowerCase().indexOf(artistLower) !== -1) {
                                    bestResult = r
                                    break
                                }
                            }
                            
                            // Fallback to first result
                            if (!bestResult) bestResult = json.results[0]
                            
                            var rawUrl = bestResult.artworkUrl100
                            if (rawUrl) {
                                fetcher.onlineArtUrl = rawUrl.replace("100x100bb", "600x600bb")
                            }
                        }
                    } catch (e) {
                        console.log("iTunes API Parse Error: " + e)
                    }
                }
            }
        }
        
        xhr.ontimeout = function() {
            console.log("iTunes API Timeout for: " + term)
        }
        
        xhr.send()
    }
}
