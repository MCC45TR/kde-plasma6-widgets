#!/bin/sh
# RSS Sync Script for File Search Widget
# Arka planda çalışarak arayüz donmalarını engeller.
# Kullanım: ./rss_sync.sh <cache_dir> <url> <name> <max_entries>

CACHE_DIR="$1"
URL="$2"
NAME="$3"
MAX_ENTRIES="$4"

[ -z "$MAX_ENTRIES" ] && MAX_ENTRIES=10

# Önbellek dizinini oluştur
mkdir -p "$CACHE_DIR"

# Python3 kontrolü
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 not found"
    exit 1
fi

# Python ile güvenli çekme ve ayrıştırma
python3 - "$CACHE_DIR" "$URL" "$NAME" "$MAX_ENTRIES" <<EOF
import sys, os, urllib.request, re, json, base64, html

cache_dir, url, name, max_entries = sys.argv[1:5]
max_entries = int(max_entries)

def unescape_html(text):
    return html.unescape(text)

def parse_rss(xml, source_name):
    entries = []
    item_pattern = re.compile(r'<(item|entry)>([\s\S]*?)</\1>', re.IGNORECASE)
    title_pattern = re.compile(r'<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</title>', re.IGNORECASE)
    link_pattern = re.compile(r'<(link|guid|id)(?:[^>]*href="([^"]+)")?>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</\1>', re.IGNORECASE)
    date_pattern = re.compile(r'<(pubDate|dc:date|updated|published)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</\1>', re.IGNORECASE)
    desc_pattern = re.compile(r'<(description|summary)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</\1>', re.IGNORECASE)
    content_pattern = re.compile(r'<(content:encoded|content)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</\1>', re.IGNORECASE)

    for match in item_pattern.finditer(xml):
        item_content = match.group(2)
        title_match = title_pattern.search(item_content)
        if title_match:
            try:
                title = unescape_html(re.sub(r'<[^>]*>?', '', title_match.group(1).strip()))
                link_match = link_pattern.search(item_content)
                link = ""
                if link_match:
                    link = link_match.group(2) or link_match.group(3) or ""
                    link = link.strip()
                date_match = date_pattern.search(item_content)
                date_str = date_match.group(2).strip() if date_match else ""
                desc_match = desc_pattern.search(item_content)
                desc = unescape_html(re.sub(r'<[^>]*>?', '', desc_match.group(2).strip())) if desc_match else ""
                full_match = content_pattern.search(item_content)
                full = unescape_html(re.sub(r'<[^>]*>?', '', full_match.group(2).strip())) if full_match else ""
                
                entries.append({
                    "display": title,
                    "decoration": "news-subscribe",
                    "category": "RSS",
                    "url": link,
                    "subtext": f"{source_name} | {date_str.replace(' +0000', '').replace('T', ' ').split('.')[0]}",
                    "description": desc[:300],
                    "indexedContent": f"{title} {desc} {full}",
                    "duplicateId": f"rss:{link}",
                    "rawDate": date_str,
                    "index": -1
                })
            except: continue
    return entries

def get_hash(url_str):
    h = 0
    for char in url_str:
        h = ((h << 5) - h) + ord(char)
        h &= 0xFFFFFFFF
    return abs(h)

try:
    print("FETCHING: START", flush=True)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) FileSearchWidget/1.0'})
    with urllib.request.urlopen(req, timeout=20) as response:
        xml = response.read().decode('utf-8', errors='ignore')
        print("FETCHING: OK", flush=True)
        
        print("PARSING: START", flush=True)
        entries = parse_rss(xml, name)[:max_entries]
        count = len(entries)
        print(f"PARSING: OK ({count} items)", flush=True)
        
        print("SAVING: START", flush=True)
        file_path = os.path.join(cache_dir, f"source_{get_hash(url)}.json")
        json_data = json.dumps(entries)
        encoded = base64.b64encode(json_data.encode('utf-8')).decode('utf-8')
        with open(file_path, 'w') as f:
            f.write(encoded)
        print(f"SAVING: {count} entries saved OK", flush=True)
        print("SUCCESS", flush=True)
except Exception as e:
    # Match the failure pattern for the UI to catch
    print(f"FAIL: {str(e)}", flush=True)
    sys.exit(1)
EOF


