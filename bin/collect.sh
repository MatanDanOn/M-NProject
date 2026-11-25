#!/bin/bash
set +x
set -e -o pipefail   # Stop if a command fails, including curl in a pipeline.
umask 077

# 1. Log in to Twitch using the private file made by the setup script.
credentials=${TWITCH_CREDENTIALS_FILE:-"/home/matan/project/IT Private Access/twitch-credentials.json"}
client=$(jq -er '.client_id' "$credentials")
token=$(jq -jr '"client_id=\(.client_id|@uri)&client_secret=\(.client_secret|@uri)&grant_type=client_credentials"' "$credentials" |
    curl -q -fsS -m 30 --data-binary @- https://id.twitch.tv/oauth2/token |
    jq -er '.access_token')

# 2. Get Steam's player count. Work in a temporary folder until everything succeeds.
work=$(mktemp -d .collect.XXXXXX)
trap 'rm -rf "$work"' EXIT
start=$(date -u +%Y-%m-%dT%H:%M:%SZ)
curl -q -fsS -m 30 'https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=413150' |
    jq -es 'first | select(.response.result == 1 and (.response.player_count | type == "number"))' > "$work/steam"

# 3. Get Twitch streams, one page at a time.
streams='https://api.twitch.tv/helix/streams?game_id=490744&first=100'
url=$streams
touch "$work/cursors"
while true; do
    printf 'Client-Id: %s\nAuthorization: Bearer %s\n' "$client" "$token" |
        curl -q -fsS -m 30 --header @- "$url" > "$work/page"

    jq -es 'first | select((.data | type == "array") and (.pagination | type == "object"))
        | select(all(.data[]; (.id | type == "string") and (.viewer_count | type == "number")
            and (.language | type == "string") and (.tags | type == "array")))
        | {data: [.data[] | {id, viewer_count, language, tags}]}' "$work/page" >> "$work/pages"

    cursor=$(jq -r '.pagination.cursor // empty | @uri' "$work/page")
    if [ -z "$cursor" ]; then break; fi
    if grep -Fxq -- "$cursor" "$work/cursors"; then echo 'Twitch repeated a page cursor.' >&2; exit 1; fi
    echo "$cursor" >> "$work/cursors"
    url="$streams&after=$cursor"
done

# 4. Combine the Steam response and Twitch pages into one JSON file.
jq -cn --arg start "$start" --arg end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --slurpfile steam "$work/steam" --slurpfile pages "$work/pages" \
    '{retrieval_started_utc: $start, retrieval_finished_utc: $end,
      game_name: "Stardew Valley", steam_app_id: 413150, twitch_game_id: "490744",
      steam: $steam[0], twitch_stream_pages: $pages}' > "$work/snapshot"

folder="raw/${start:0:10}"                 # YYYY-MM-DD from the start time
file="$folder/${start:11:2}${start:14:2}.json"  # HHMM.json from the same time
mkdir -p "$folder"
ln "$work/snapshot" "$file"               # Publish only if this filename is free.
echo "Saved $file"
