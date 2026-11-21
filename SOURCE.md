# SOURCE.md — Steam players vs. Twitch viewers (*Stardew Valley*)

## i. Approved data source

| Property | Steam Web API | Twitch API (Helix) |
|---|---|---|
| Name | `ISteamUserStats/GetNumberOfCurrentPlayers` | `Get Streams` (plus `Get Games` for the game-ID lookup) |
| URL | `https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=413150` | `https://api.twitch.tv/helix/streams?game_id=490744&first=100` (lookup: `https://api.twitch.tv/helix/games?name=Stardew%20Valley`) |
| Data format | JSON | JSON (paginated, up to 100 streams per page) |
| Key / username required | No | Yes: a free Twitch developer application (Client ID + Client Secret) and an app access token (client-credentials flow). Credentials are stored outside the repository with `chmod 600`. |
| License / terms | [Steam Web API Terms of Use](https://steamcommunity.com/dev/apiterms); limited to 100,000 calls per day | [Twitch Developer Services Agreement](https://legal.twitch.com/legal/developer-agreement); rate-limited per minute ([Twitch API rate limits](https://dev.twitch.tv/docs/api/guide/#twitch-rate-limits)) |
| Collection frequency | Every 2 hours (12 collections per day) | Every 2 hours, in the same collection as Steam |

`413150` is the Steam app ID and `490744` is the Twitch game ID of *Stardew Valley*.

A collection makes 1 Steam request and 3 Twitch requests (game lookup + 2 stream pages in the current sample). At 12 collections per day, this is far below both rate limits.

## ii. What is collected

Each collection is saved as one JSON file under `raw/YYYY-mm-dd/HHMM.json` (UTC). The file contains:

- **Steam:** the number of players currently in *Stardew Valley* (`player_count`) and a result flag (`result`).
- **Twitch:** every live *Stardew Valley* stream at collection time, across all pages, with each stream's `viewer_count`.
- **Metadata added by our collection:** retrieval start/end time (UTC), game name, Steam app ID and Twitch game ID.

Example (`raw/2026-11-16/1610.json`): Steam reported 50,401 players; Twitch returned 87 live streams on 2 pages (the second page was empty), with 564 viewers in total.

**Limitations:**

- Steam players and Twitch viewers are different populations. We study how the two series move over time, not causation.
- The Twitch viewer total is a sum over streams fetched in sequential page requests. It is not an atomic snapshot and not a count of unique people. Streams can shift between pages, so duplicate stream IDs must be removed before summing.
- Steam may cache its responses, so the retrieval time is not guaranteed to be the exact measurement time.
- Both values are snapshots every 2 hours. Changes between collections are not observed.

## iii. Schema (`data/dataset.csv`)

One row per collection (per raw file). The first line is a header.

| Column | Content | Type / unit |
|---|---|---|
| `collected_at_utc` | Time the collection started | ISO 8601 timestamp, UTC (e.g. `2026-11-16T16:10:32+00:00`) |
| `game_name` | Game the row describes | Text (`Stardew Valley`) |
| `steam_player_count` | Players currently in the game on Steam | Integer, players. Empty if the Steam request failed or `result` ≠ 1 |
| `twitch_viewer_count` | Sum of `viewer_count` over unique live streams | Integer, viewers (summed per stream). Empty if the Twitch request failed |
| `twitch_stream_count` | Number of unique live streams | Integer, streams. `0` is a valid value (no live streams) |

Example row, produced from the sample above:

```csv
collected_at_utc,game_name,steam_player_count,twitch_viewer_count,twitch_stream_count
"2026-11-16T16:10:32+00:00","Stardew Valley",50401,564,87
```

## iv. Why these columns

**Included in dataset.csv:**

- `collected_at_utc` is the time axis. Every comparison between the series depends on it.
- `game_name` keeps each row self-describing. It also allows another game or source to be added later without changing the schema.
- `steam_player_count` and `twitch_viewer_count` are the two series the project compares.
- `twitch_stream_count` separates "more viewers per stream" from "more streams". It also makes zero-viewer rows easy to interpret.

**excluded in dataset.csv:**

- `retrieval_finished_utc`: a collection takes about 2 seconds, which is negligible against a 2-hour interval.
- `steam_app_id`, `twitch_game_id`, and the whole `twitch_game_lookup` object (`id`, `name`, `box_art_url`, `igdb_id`): constant for a single game. They are documented in section i instead.
- Steam `result`: a status flag used only to validate `player_count`.
- `pagination.cursor`: used only to request the next page.

**Fields still in debate pre automatic collection:**
- `type`, `game_id`, `game_name` per stream: constant (`live`, `490744`, `Stardew Valley`) because the request already filters by game.
- Per-stream fields (`user_id`, `user_login`, `user_name`, `title`, `tag_ids` (always empty),`is_mature`, `thumbnail_url`, `started_at`): they describe individual streamers, not game-level activity, and the research question does not need them. `id` is used only to remove duplicates before counting, where we'll keep only the first occurrence in page order.
- We propose keeping specific per-stream fields `tags` and `language` as they may contain extra information useful for twitch viewer segmentation during analysis. We'd rather collect the very lightweight information and have it yield no substantial results than regret not having collected it to begin with.

The complete responses (containing whichever fields we choose to retain) remain in `raw/`. Because `normalise.sh` rebuilds `dataset.csv` from all of `raw/`, a column can be added later without losing history.

## v. Source field → schema column

| Source field (path in raw JSON) | Schema column | Transformation |
|---|---|---|
| `retrieval_started_utc` (added by our collection) | `collected_at_utc` | Copied unchanged |
| `game_name` (added by our collection) | `game_name` | Copied unchanged |
| `steam.response.player_count` | `steam_player_count` | Copied if `steam.response.result` = 1, otherwise empty |
| `twitch_stream_pages[].data[].viewer_count` | `twitch_viewer_count` | Sum over all pages, after removing duplicate `id`s |
| `twitch_stream_pages[].data[].id` | `twitch_stream_count` | Count of unique `id`s over all pages |

## vi. Expected size after one semester

Assumptions: 13 weeks (91 days) × 12 collections per day = **1,092 collections**.

| Target | Measured per collection | Expected after a semester |
|---|---|---|
| `raw/` (uncompressed JSON) | 70,821 bytes (sample with 87 streams) | ≈ 77.3 MB |
| `raw/` (if gzip-compressed) | 11,884 bytes | ≈ 13.0 MB |
| `data/dataset.csv` | 58 bytes per row + 86-byte header | ≈ 63 KB |

Raw file size grows with the number of live streams: each stream adds about 0.8 KB. Even if every collection were twice the size of the sample, `raw/` would be about 155 MB, below the project's 500 MB limit. `dataset.csv` has one row per collection, so its size does not depend on the number of streams.
