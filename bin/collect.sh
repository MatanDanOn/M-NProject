#!/bin/bash
set -e -o pipefail   # Stop if a command fails, including curl in a pipeline.
umask 077

# Exit codes:
#   0 = complete snapshot saved (Steam and Twitch both succeeded)
#   2 = partial snapshot saved (one source failed and is stored as null)
#   1 = no snapshot saved (both sources failed, or the file could not be published)

credentials=${TWITCH_CREDENTIALS_FILE:-"$HOME/.secrets/twitch-credentials.json"}

# curl retries temporary errors (timeouts, HTTP 429/5xx) up to 3 times, 5 seconds apart.
# No new retry starts after 60 seconds; each single attempt is limited to 30 seconds (-m 30).

# Work in a temporary folder. Nothing reaches raw/ until the snapshot is finished.
work=$(mktemp -d .collect.XXXXXX)
trap 'rm -rf "$work"' EXIT
start=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Each source runs in its own subshell with "set -e", so any failure stops only that source.
# "set +e" around it lets the main script read the result instead of stopping.

# 1. Steam: current player count.
set +e
(
    set -e -o pipefail
    curl -q -fsS -m 30 --retry 3 --retry-delay 5 --retry-max-time 60 'https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=413150' |
        jq -es 'first | select(.response.result == 1 and (.response.player_count | type == "number"))' > "$work/steam"
)
steam_rc=$?
set -e
if [ "$steam_rc" -eq 0 ]; then
    steam_status=ok
else
    steam_status=failed
    echo 'Steam failed; saving steam as null.' >&2
    echo null > "$work/steam"
fi

# 2. Twitch: log in, then get all live streams, one page at a time.
# If any step fails, even halfway through the pages, all Twitch pages are discarded.
set +e
(
    set -e -o pipefail
    client=$(jq -er '.client_id' "$credentials")
    token=$(jq -jr '"client_id=\(.client_id|@uri)&client_secret=\(.client_secret|@uri)&grant_type=client_credentials"' "$credentials" |
        curl -q -fsS -m 30 --retry 3 --retry-delay 5 --retry-max-time 60 --data-binary @- https://id.twitch.tv/oauth2/token |
        jq -er '.access_token')

    streams='https://api.twitch.tv/helix/streams?game_id=490744&first=100'
    url=$streams
    touch "$work/cursors"
    while true; do
            printf 'Client-Id: %s\nAuthorization: Bearer %s\n' "$client" "$token" |
            curl -q -fsS -m 30 --retry 3 --retry-delay 5 --retry-max-time 60 --header @- "$url" > "$work/page"

        jq -es 'first | select((.data | type == "array") and (.pagination | type == "object"))
            | select(all(.data[]; (.id | type == "string") and (.viewer_count | type == "number")
                and (.language | type == "string") and (.tags | type == "array" or type == "null")))
            | {data: [.data[] | {id, viewer_count, language, tags}]}' "$work/page" >> "$work/pages"

        cursor=$(jq -r '.pagination.cursor // empty | @uri' "$work/page")
        if [ -z "$cursor" ]; then break; fi
        if grep -Fxq -- "$cursor" "$work/cursors"; then echo 'Twitch repeated a page cursor.' >&2; exit 1; fi
        echo "$cursor" >> "$work/cursors"
        url="$streams&after=$cursor"
    done

    jq -s '.' "$work/pages" > "$work/twitch"   # All pages as one JSON array.
)
twitch_rc=$?
set -e
if [ "$twitch_rc" -eq 0 ]; then
    twitch_status=ok
else
    twitch_status=failed
    echo 'Twitch failed; discarding any Twitch pages and saving twitch as null.' >&2
    echo null > "$work/twitch"
fi

# 3. Decide the collection status.
if [ "$steam_status" = ok ] && [ "$twitch_status" = ok ]; then
    collection_status=complete
elif [ "$steam_status" = ok ] || [ "$twitch_status" = ok ]; then
    collection_status=partial
else
    echo "$start: both Steam and Twitch failed; no snapshot saved." >&2
    exit 1
fi

# 4. Combine everything into one JSON snapshot.
jq -cn --arg start "$start" --arg end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$collection_status" --arg steam_status "$steam_status" --arg twitch_status "$twitch_status" \
    --slurpfile steam "$work/steam" --slurpfile twitch "$work/twitch" \
    '{retrieval_started_utc: $start, retrieval_finished_utc: $end,
      collection_status: $status,
      source_status: {steam: $steam_status, twitch: $twitch_status},
      game_name: "Stardew Valley", steam_app_id: 413150, twitch_game_id: "490744",
      steam: $steam[0], twitch_stream_pages: $twitch[0]}' > "$work/snapshot"

# 5. Publish to raw/YYYY-MM-DD/HHMM.json (UTC), only if this filename is free.
folder="raw/${start:0:10}"
file="$folder/${start:11:2}${start:14:2}.json"
mkdir -p "$folder"
ln "$work/snapshot" "$file"

if [ "$collection_status" = complete ]; then
    echo "Saved $file"
else
    echo "Saved partial $file (steam: $steam_status, twitch: $twitch_status)" >&2
    exit 2
fi
