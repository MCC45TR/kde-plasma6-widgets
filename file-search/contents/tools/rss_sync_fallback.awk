# Bounded RSS/Atom-to-JSON parser and JSON-object splitter used by the POSIX
# shell fallback. It deliberately does not interpret DTDs or custom entities.

function json_escape(value,    result, i, char) {
    result = ""
    for (i = 1; i <= length(value); i++) {
        char = substr(value, i, 1)
        if (char == "\\") result = result "\\\\"
        else if (char == "\"") result = result "\\\""
        else if (char == "\b") result = result "\\b"
        else if (char == "\f") result = result "\\f"
        else if (char == "\r") result = result "\\r"
        else if (char == "\n") result = result "\\n"
        else if (char == "\t") result = result "\\t"
        else result = result char
    }
    return result
}

function clean_text(value,    lower, marker, pos, i, markers) {
    gsub(/<!\[CDATA\[/, "", value)
    gsub(/\]\]>/, "", value)
    gsub(/<[^>]*>/, " ", value)
    gsub(/&lt;/, "<", value); gsub(/&gt;/, ">", value)
    gsub(/&quot;/, "\"", value); gsub(/&apos;/, "\047", value)
    gsub(/&amp;/, "\\&", value)
    gsub(/[[:space:]]+/, " ", value)
    sub(/^ /, "", value); sub(/ $/, "", value)
    markers = "Devamını oku|Haberin devamı|Tıklayın|İşte detaylar|Read more|Full story"
    lower = tolower(value)
    split(markers, marker_list, "|")
    pos = 0
    for (i in marker_list) {
        marker = index(lower, tolower(marker_list[i]))
        if (marker && (!pos || marker < pos)) pos = marker
    }
    if (pos) value = substr(value, 1, pos - 1)
    sub(/[[:space:]]+$/, "", value)
    return value
}

function find_open(block, name, start,    lower, needle, rest, relative, after) {
    lower = tolower(block)
    needle = "<" tolower(name)
    while (start <= length(block)) {
        rest = substr(lower, start)
        relative = index(rest, needle)
        if (!relative) return 0
        start += relative - 1
        after = substr(lower, start + length(needle), 1)
        if (after ~ /[[:space:]>\/]/) return start
        start++
    }
    return 0
}

function tag_text(block, name,    start, open_end, close_start, lower, close_tag) {
    start = find_open(block, name, 1)
    if (!start) return ""
    open_end = index(substr(block, start), ">")
    if (!open_end) return ""
    open_end += start - 1
    lower = tolower(block)
    close_tag = "</" tolower(name) ">"
    close_start = index(substr(lower, open_end + 1), close_tag)
    if (!close_start) return ""
    close_start += open_end
    return substr(block, open_end + 1, close_start - open_end - 1)
}

function opening_tag(block, name,    start, ending) {
    start = find_open(block, name, 1)
    if (!start) return ""
    ending = index(substr(block, start), ">")
    if (!ending) return ""
    return substr(block, start, ending)
}

function attribute(tag, name,    lower, pattern, offset, relative, start, rest, quote, ending) {
    lower = tolower(tag)
    pattern = tolower(name)
    offset = 1
    while ((relative = index(substr(lower, offset), pattern)) > 0) {
        start = offset + relative - 1
        if (start == 1 || substr(lower, start - 1, 1) ~ /[[:space:]<]/) {
            rest = substr(tag, start + length(pattern))
            sub(/^[[:space:]]*/, "", rest)
            if (substr(rest, 1, 1) == "=") {
                rest = substr(rest, 2); sub(/^[[:space:]]*/, "", rest)
                quote = substr(rest, 1, 1)
                if (quote == "\"" || quote == "\047") {
                    rest = substr(rest, 2); ending = index(rest, quote)
                    if (ending) return substr(rest, 1, ending - 1)
                }
            }
        }
        offset = start + length(pattern)
    }
    return ""
}

function tag_attribute(block, tag_name, attribute_name) {
    return attribute(opening_tag(block, tag_name), attribute_name)
}

function authority_host(url,    authority, closing, suffix) {
    if (tolower(substr(url, 1, 8)) != "https://") return ""
    authority = substr(url, 9)
    sub(/[\/?#].*$/, "", authority)
    if (authority ~ /@/) return ""
    if (substr(authority, 1, 1) == "[") {
        closing = index(authority, "]")
        if (!closing) return ""
        suffix = substr(authority, closing + 1)
        if (suffix != "" && suffix != ":443") return ""
        authority = substr(authority, 2, closing - 2)
    } else {
        if (authority ~ /:/ && authority !~ /:443$/) return ""
        sub(/:443$/, "", authority)
    }
    return tolower(authority)
}

function safe_url(url, same_origin,    host) {
    url = clean_text(url)
    if (length(url) > 2048 || tolower(substr(url, 1, 8)) != "https://") return ""
    host = authority_host(url)
    if (host == "") return ""
    if (same_origin && host != source_host) return ""
    return url
}

function normalized_date(value) {
    value = substr(clean_text(value), 1, 128)
    sub(/ \+0000$/, "", value)
    gsub(/T/, " ", value)
    sub(/\.[0-9]+Z?$/, "", value)
    return value
}

function emit_entry(block,    title, link, raw_date, shown_date, description_raw, content_raw, description, full_content, image, indexed, duplicate, object) {
    title = substr(clean_text(tag_text(block, "title")), 1, 300)
    link = clean_text(tag_text(block, "link"))
    if (link == "") link = attribute(opening_tag(block, "link"), "href")
    if (link == "") link = clean_text(tag_text(block, "guid"))
    link = safe_url(link, 0)

    raw_date = tag_text(block, "pubdate")
    if (raw_date == "") raw_date = tag_text(block, "updated")
    if (raw_date == "") raw_date = tag_text(block, "published")
    if (raw_date == "") raw_date = tag_text(block, "date")
    raw_date = substr(clean_text(raw_date), 1, 128)
    shown_date = normalized_date(raw_date)

    description_raw = tag_text(block, "description")
    if (description_raw == "") description_raw = tag_text(block, "summary")
    content_raw = tag_text(block, "content:encoded")
    if (content_raw == "") content_raw = tag_text(block, "content")
    description = substr(clean_text(substr(description_raw, 1, 20000)), 1, 1000)
    full_content = substr(clean_text(substr(content_raw, 1, 20000)), 1, 20000)
    if (full_content == "") full_content = description
    if (title == "") title = substr(description, 1, 50)
    if (title == "") return 0

    image = tag_attribute(block, "media:content", "url")
    if (image == "") image = tag_attribute(block, "enclosure", "url")
    if (image == "") image = tag_attribute(block, "media:thumbnail", "url")
    if (image == "") image = tag_attribute(block, "image", "url")
    image = safe_url(image, 1)
    indexed = substr(title " " description " " full_content, 1, 25000)
    duplicate = link
    if (duplicate == "") duplicate = title "|" raw_date

    object = "{\"display\":\"" json_escape(title) "\",\"decoration\":\"news-subscribe\",\"category\":\"RSS\",\"url\":\"" json_escape(link) "\",\"subtext\":\"" json_escape(source_name " | " shown_date) "\",\"description\":\"" json_escape(description) "\",\"fullContent\":\"" json_escape(full_content) "\",\"imageUrl\":\"" json_escape(image) "\",\"sourceIcon\":\"\",\"indexedContent\":\"" json_escape(indexed) "\",\"duplicateId\":\"rss:" json_escape(duplicate) "\",\"rawDate\":\"" json_escape(raw_date) "\",\"index\":-1}"
    if (entry_count++) printf ","
    printf "%s", object
    return 1
}

function parse_feed(xml,    lower, cursor, item_at, entry_at, start, tag, close_tag, relative_end, block) {
    lower = tolower(xml)
    if (lower ~ /<![[:space:]]*(doctype|entity)[[:space:]]/) return 0
    cursor = 1
    printf "["
    while (cursor <= length(xml) && entry_count < max_entries) {
        item_at = find_open(xml, "item", cursor)
        entry_at = find_open(xml, "entry", cursor)
        if (!item_at) start = entry_at
        else if (!entry_at) start = item_at
        else start = item_at < entry_at ? item_at : entry_at
        if (!start) break
        tag = start == item_at ? "item" : "entry"
        close_tag = "</" tag ">"
        relative_end = index(substr(lower, start), close_tag)
        if (!relative_end) return 0
        block = substr(xml, start, relative_end + length(close_tag) - 1)
        emit_entry(block)
        cursor = start + relative_end + length(close_tag) - 1
    }
    print "]"
    return 1
}

function json_field(object, field,    needle, start, i, char, escaped, result) {
    needle = "\"" field "\":\""
    start = index(object, needle)
    if (!start) return ""
    start += length(needle)
    for (i = start; i <= length(object); i++) {
        char = substr(object, i, 1)
        if (!escaped && char == "\"") return result
        result = result char
        if (escaped) escaped = 0
        else if (char == "\\") escaped = 1
    }
    return ""
}

function split_objects(json,    i, char, in_string, escaped, depth, start, object, date, duplicate) {
    for (i = 1; i <= length(json); i++) {
        char = substr(json, i, 1)
        if (in_string) {
            if (escaped) escaped = 0
            else if (char == "\\") escaped = 1
            else if (char == "\"") in_string = 0
            continue
        }
        if (char == "\"") { in_string = 1; continue }
        if (char == "{") {
            if (depth == 0) start = i
            depth++
        } else if (char == "}") {
            depth--
            if (depth < 0) return 0
            if (depth == 0 && start) {
                object = substr(json, start, i - start + 1)
                date = json_field(object, "rawDate")
                duplicate = json_field(object, "duplicateId")
                print date "\t" duplicate "\t" object
                start = 0
            }
        }
    }
    return depth == 0 && !in_string
}

BEGIN {
    mode = ENVIRON["RSS_FALLBACK_MODE"]
    source_name = substr(ENVIRON["RSS_SOURCE_NAME"], 1, 128)
    source_host = authority_host(ENVIRON["RSS_SOURCE_URL"])
    max_entries = ENVIRON["RSS_MAX_ENTRIES"] + 0
    if (max_entries < 1) max_entries = 1
    if (max_entries > 50) max_entries = 50
}

{ input = input $0 "\n" }

END {
    if (mode == "parse") {
        if (!parse_feed(input)) exit 2
        if (ENVIRON["RSS_COUNT_FILE"] != "") print entry_count > ENVIRON["RSS_COUNT_FILE"]
    } else if (mode == "objects") {
        if (!split_objects(input)) exit 2
    } else exit 2
}
