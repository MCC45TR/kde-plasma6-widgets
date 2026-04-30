#!/bin/sh
# RSS Sync Script for File Search Widget
# Arka planda çalışarak arayüz donmalarını engeller.
# Kullanım: ./rss_sync.sh <cache_dir> <url> <name> <max_entries>

# Clean file:// prefix from cache dir path
CACHE_DIR=$(echo "$1" | sed -E 's|^file:/*|/|')
URL="$2"
NAME="$3"
MAX_ENTRIES="$4"

[ -z "$MAX_ENTRIES" ] && MAX_ENTRIES=10

# Önbellek dizinini oluştur
mkdir -p "$CACHE_DIR"

# Python3 kontrolü
if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL: python3 not found"
    exit 1
fi

# Python ile güvenli çekme ve ayrıştırma
python3 -c '
import sys, os, urllib.request, re, json, base64, html, datetime, xml.etree.ElementTree as ET

def clean_html(raw_html):
    if not raw_html: return ""
    # Remove junk markers often found in news feeds
    junk = ["Devamını oku", "Haberin devamı", "Tıklayın", "İşte detaylar", "Read more", "Full story"]
    clean_text = raw_html
    for j in junk:
        clean_text = re.sub(r"(?i)" + j + r".*", "", clean_text)
    
    # Remove HTML tags and keep text
    cleanr = re.compile("<.*?>|&([a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});")
    cleantext = re.sub(cleanr, " ", clean_text)
    return html.unescape(cleantext).strip()

def normalize_date(date_str):
    if not date_str: return ""
    # Try common formats
    formats = [
        "%a, %d %b %Y %H:%M:%S %z",
        "%a, %d %b %Y %H:%M:%S %Z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%d %H:%M:%S",
        "%d.%m.%Y %H:%M:%S",
        "%Y/%m/%d %H:%M:%S"
    ]
    for fmt in formats:
        try:
            dt = datetime.datetime.strptime(date_str, fmt)
            return dt.strftime("%Y-%m-%d %H:%M")
        except:
            continue
    # Fallback cleaning
    return date_str.replace(" +0000", "").replace("T", " ").split(".")[0]

def get_favicon(url):
    try:
        from urllib.parse import urlparse
        domain = urlparse(url).netloc
        if domain:
            return f"https://www.google.com/s2/favicons?domain={domain}&sz=64"
    except:
        pass
    return ""

def find_node_recursive(node, tag_names):
    # Search for a tag ignoring namespace
    tag_names_lower = [t.lower() for t in tag_names]
    for child in node.iter():
        local_tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
        if local_tag.lower() in tag_names_lower:
            return child
    return None

def get_deep_text(node, tag_names):
    # Find tag and return text or CDATA content
    found = find_node_recursive(node, tag_names)
    if found is not None:
        text = (found.text or "").strip()
        if not text and len(found) > 0:
            # Fallback: get all inner text
            text = "".join(found.itertext()).strip()
        return text
    return ""

def get_attr_recursive(node, tag_names, attr_name):
    tag_names_lower = [t.lower() for t in tag_names]
    for child in node.iter():
        local_tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
        if local_tag.lower() in tag_names_lower:
            val = child.get(attr_name)
            if val: return val
    return ""

def parse_rss(xml, source_name, source_url):
    entries = []
    source_favicon = get_favicon(source_url)
    try:
        # XML cleaning for common Turkish news site errors (unescaped &)
        xml_cleaned = re.sub(r"&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[a-fA-F0-9]+);)", "&amp;", xml)
        root = ET.fromstring(xml_cleaned)
        
        # Support both RSS <item> and Atom <entry>
        item_nodes = root.findall(".//item") or root.findall(".//{http://www.w3.org/2005/Atom}entry") or root.findall(".//entry")
        
        for node in item_nodes:
            # 1. Title
            title = clean_html(get_deep_text(node, ["title"]))
            
            # 2. Link
            link = get_deep_text(node, ["link", "guid"]) or ""
            if not link:
                # Try Atom style link attribute
                for child in node.iter():
                    if child.tag.endswith("link"):
                        link = child.get("href") or ""
                        if link: break
            
            # 3. Date
            date_str = get_deep_text(node, ["pubDate", "updated", "published", "date", "dc:date"]) or ""
            date_norm = normalize_date(date_str)
            
            # 4. Content
            desc_raw = get_deep_text(node, ["description", "summary"]) or ""
            full_raw = get_deep_text(node, ["content:encoded", "encoded", "content"]) or ""
            
            desc = clean_html(desc_raw)
            full = clean_html(full_raw)
            
            # Fallback title if missing
            if not title:
                title = (desc[:50] + "...") if len(desc) > 50 else (desc or "Haber")
            
            # 5. Image extraction (media:content, enclosure, media:thumbnail, or <img> in content)
            image_url = get_attr_recursive(node, ["media:content", "enclosure", "media:thumbnail", "image"], "url")
            if not image_url:
                # Parse <img> tags from content
                img_match = re.search(r"<img[^>]*src=\"([^\"]+)\"[^>]*>", desc_raw + full_raw, re.IGNORECASE)
                if img_match: image_url = img_match.group(1)
            
            if title:
                entries.append({
                    "display": title,
                    "decoration": "news-subscribe",
                    "category": "RSS",
                    "url": link,
                    "subtext": f"{source_name} | {date_norm}",
                    "description": desc[:300] + "..." if len(desc) > 300 else desc,
                    "fullContent": full or desc,
                    "imageUrl": image_url or "",
                    "sourceIcon": source_favicon,
                    "indexedContent": f"{title} {desc} {full}",
                    "duplicateId": f"rss:{link}",
                    "rawDate": date_str,
                    "index": -1
                })
    except Exception as e:
        print(f"DEBUG: XML Parse error: {str(e)}", flush=True)
        return []
        
    return entries

def get_hash(s):
    h = 0
    for char in s:
        h = ((h << 5) - h) + ord(char)
        h &= 0xFFFFFFFF
    if h > 0x7FFFFFFF:
        h -= 0x100000000
    return abs(h)

if len(sys.argv) < 5:
    sys.exit(1)

cache_dir, url, name, max_entries = sys.argv[1:5]
max_entries = int(max_entries)

try:
    print("FETCHING: START", flush=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) FileSearchWidget/1.0"})
    with urllib.request.urlopen(req, timeout=25) as response:
        charset = response.info().get_content_charset() or "utf-8"
        xml_bytes = response.read()
        try:
            xml = xml_bytes.decode(charset)
        except:
            xml = xml_bytes.decode("utf-8", errors="ignore")
        
        print("FETCHING: OK", flush=True)
        print("PARSING: START", flush=True)
        
        entries = parse_rss(xml, name, url)[:max_entries]
        count = len(entries)
        print(f"PARSING: OK ({count} items)", flush=True)
        
        print("SAVING: START", flush=True)
        file_path = os.path.join(cache_dir, f"source_{get_hash(url)}.json")
        json_data = json.dumps(entries)
        encoded = base64.b64encode(json_data.encode("utf-8")).decode("utf-8")
        with open(file_path, "w") as f:
            f.write(encoded)
        print(f"SAVING: {count} entries saved OK", flush=True)
        print("SUCCESS", flush=True)
except Exception as e:
    print(f"FAIL: {str(e)}", flush=True)
    sys.exit(1)
' "$CACHE_DIR" "$URL" "$NAME" "$MAX_ENTRIES"
