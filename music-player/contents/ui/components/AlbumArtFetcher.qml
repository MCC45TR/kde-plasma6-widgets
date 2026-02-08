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
    
    // internal
    property string localArtUrl: ""
    property string onlineArtUrl: ""
    
    onMprisArtUrlChanged: evalEffectiveUrl()
    onLocalArtUrlChanged: evalEffectiveUrl()
    onOnlineArtUrlChanged: evalEffectiveUrl()
    
    function evalEffectiveUrl() {
        // 1. MPRIS (if valid and not a generic icon)
        if (mprisArtUrl && mprisArtUrl !== "" && mprisArtUrl.indexOf("icon-") !== 0) {
            effectiveArtUrl = mprisArtUrl
            return
        }
        
        // 2. Local File
        if (localArtUrl !== "") {
            effectiveArtUrl = localArtUrl
            return
        }
        
        // 3. Online
        if (onlineArtUrl !== "") {
            effectiveArtUrl = onlineArtUrl
            return
        }
        
        // 4. Fallback/None
        effectiveArtUrl = ""
    }
    
    // --- Local Fetching Logic ---
    // Only works if trackUrl is a file:// URL
    property string folderUrl: {
        if (!trackUrl || trackUrl.indexOf("file://") !== 0) return ""
        var path = trackUrl.toString()
        var lastSlash = path.lastIndexOf("/")
        if (lastSlash > 7) {
            return path.substring(0, lastSlash)
        }
        return ""
    }
    
    FolderListModel {
        id: folderModel
        folder: fetcher.folderUrl
        nameFilters: ["Cover.jpg", "cover.jpg", "Folder.jpg", "folder.jpg", "Album.jpg", "album.jpg", "Front.jpg", "front.jpg", "*.png", "*.jpg", "*.jpeg"]
        showDirs: false
        showFiles: true

        
        onCountChanged: {
            if (folder == "") {
                fetcher.localArtUrl = ""
                return
            }
            
            if (count > 0) {
                // Priority Check
                var found = ""
                // Simple iteration - FolderListModel is async but count change signals readiness usually
                // Note: FolderListModel doesn't give direct index access easily in QML without Repeater, 
                // but we can use get(i, "fileUrl") if available or fallback. 
                // Actually FolderListModel methods are limited. 
                // Better approach: Just pick the first match effectively?
                // Let's rely on nameFilters priority? No, nameFilters is OR.
                // We'll check the first few files.
                
                for (var i = 0; i < Math.min(count, 10); i++) {
                    var name = get(i, "fileName")
                    var url = get(i, "fileUrl")
                    
                    if (name.toLowerCase().indexOf("cover") !== -1 || name.toLowerCase().indexOf("folder") !== -1 || name.toLowerCase().indexOf("front") !== -1) {
                         fetcher.localArtUrl = url
                         return
                    }
                }
                
                // If specific names not found, but we have images, take the first one?
                // Maybe risky if it's "Back.jpg". Let's be conservative.
                // If only 1 image exists, take it.
                if (count == 1) {
                     fetcher.localArtUrl = get(0, "fileUrl")
                     return
                }
            }
            fetcher.localArtUrl = ""
        }
    }
    
    // --- Online Fetching Logic (iTunes API) ---
    // Debounce to avoid spamming while scrolling/skipping
    Timer {
        id: apiTimer
        interval: 1000
        repeat: false
        onTriggered: fetchOnlineArt()
    }
    
    onArtistChanged: {
        onlineArtUrl = ""
        if (artist !== "") apiTimer.restart()
    }
    onAlbumChanged: {
        onlineArtUrl = ""
        if (album !== "") apiTimer.restart()
    }
    
    function fetchOnlineArt() {
        if (artist === "" || (album === "" && title === "")) return
        
        var term = artist + " " + (album || title)
        var url = "https://itunes.apple.com/search?term=" + encodeURIComponent(term) + "&media=music&entity=album&limit=1"
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        if (json.resultCount > 0) {
                            var result = json.results[0]
                            // get high res (600x600)
                            var rawUrl = result.artworkUrl100
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
        xhr.send()
    }
}
