# M-N Project
### Full Names:
  ##### Matan Dan On
  ##### Nitzan Gavish

#### Repository Link: https://github.com/MatanDanOn/M-NProject

This file is updated throughout the semester.

## 1. What we collect and why

We collect two live measurements of the game *Stardew Valley*. The planned sampling interval is every 2 hours:

- **Steam:** the number of players currently in the game.
- **Twitch:** every live stream of the game, with its viewer count, language and tags.

Research question: **How closely does Twitch live-stream viewership reflect Steam player activity?**

Both numbers change during the day and are not published as history, so a measurement that is not collected at the time is lost. Collecting both sources at the same time lets us compare how the two series move together over time. Full details of the sources, their limits and the size estimate are in [`SOURCE.md`](SOURCE.md).

## 2. Schema

Each collection is one JSON file in `raw/YYYY-mm-dd/HHMM.json` (UTC). `bin/normalise.sh` (week 6) will turn all of `raw/` into `data/dataset.csv`, one row per collection:

| Column | Content |
|---|---|
| `collected_at_utc` | Time the collection started (UTC) |
| `game_name` | `Stardew Valley` |
| `steam_player_count` | Steam players; empty if Steam failed |
| `twitch_viewer_count` | Sum of viewers over unique live streams; empty if Twitch failed |
| `twitch_stream_count` | Number of unique live streams; empty if Twitch failed |

An empty cell means the value was not measured. It is never `0` and never estimated. The full schema, the reason for each column and the mapping from the raw fields are in [`SOURCE.md`](SOURCE.md).

## 3. How to run

Requirements: `bash`, `curl`, `jq`, and a free Twitch developer application (Client ID and Client Secret).

1. Store the Twitch credentials outside the repository and make the file private:
   ```
   mkdir -p ~/.secrets
   # ~/.secrets/twitch-credentials.json contains {"client_id": "...", "client_secret": "..."}
   chmod 600 ~/.secrets/twitch-credentials.json
   ```
   A different location can be set with the `TWITCH_CREDENTIALS_FILE` environment variable.
2. Run one collection from the repository root:
   ```
   bin/collect.sh
   echo $?
   ```
   Exit codes: `0` = complete snapshot saved, `2` = partial snapshot saved (one source failed and is stored as `null`), `1` = no snapshot saved.
3. Collect automatically every 2 hours with `cron` (`crontab -e`):
   ```
   0 */2 * * * cd /path/to/M-NProject && bin/collect.sh >> collect.log 2>&1
   ```
   `cron` starts in the home folder, so the line changes to the repository root first. `collect.log` keeps every error message and is ignored by git.

The other pipeline steps (`normalise.sh`, `analyse.sh`, `build.sh`, `run.sh`) will be added in the coming weeks.

## 4. Findings

No findings yet. Analysis starts with `bin/analyse.sh` (week 8), after enough collections have been gathered.

## 5. What broke and how we handled it

**2026-11-18: a raw file named in local time instead of UTC**
- *What we saw:* the first manual sample was saved as `raw/2026-11-16/1810.json`, but its own `retrieval_started_utc` was `2026-11-16T16:10:32+00:00`.
- *Diagnosis and cause:* the file name used Israel local time (UTC+2) instead of UTC, which the contract requires.
- *Fix:* the file was renamed to `1610.json` (commit `c9d84ff`). This happened before automatic collection existed. `bin/collect.sh` now builds the folder and file name from `date -u`, the same timestamp stored inside the file, so this cannot happen again.
- *Why this fix:* the file content was correct; only its name broke the naming rule, and every later step relies on the name matching the UTC time.

**2026-11-25: Twitch login request in the first Bash collector**
- While moving from our Python reference scripts to `bin/collect.sh`, the Twitch login request contained a trailing newline. It was fixed before the first live collection with the Bash script.

**2026-11-28: one failed source discarded the whole collection**
- *What we saw (code review):* in the first version of `bin/collect.sh`, a failure of Steam or Twitch stopped the script, so the measurement from the source that worked was lost too. A single stream with `tags: null` would also have failed the whole collection.
- *Fix:* each source is now collected independently. A failed source is saved as `null`, an incomplete Twitch pagination is discarded, and each file records `collection_status` and `source_status`. `curl` retries temporary errors.
- *Why this fix:* a measurement that is not saved cannot be downloaded later. A partial file that is clearly marked keeps the real measurement, and it cannot be mistaken for a complete paired observation, because the paired comparison uses only rows where both values exist.

## 6. What we would do differently

To be completed during the semester. So far: name raw files in UTC from the very first sample.
