# PAIR.md — Division of work

**Pair:** Matan Dan On, Nitzan Gavish

Each week lists what each of us did, based on the commits in this repository. This file is updated every week.

## Week 2: create the project, propose data sources (HW1)

| | Matan Dan On | Nitzan Gavish |
|---|---|---|
| Work | Created the repository and `README.md` (2026-11-03). Wrote the source proposals in `SOURCE.md`: Steam vs. Twitch, and supermarket protein promotions (2026-11-06). Registered a Twitch developer application, tested authenticated requests and measured sample sizes (2026-11-06). Added both names to `README.md` (2026-11-06, 2026-11-08). | No commits this week. |

## Week 3: source approval, first raw data, schema (HW3)

| | Matan Dan On | Nitzan Gavish |
|---|---|---|
| Work | Saved the all four manual samples into the raw directory (Steam + Twitch, *Stardew Valley*), made a light edit to SOURCE.md regarding data fields collected during the manual sampling, which may not be needed during automatic sampling | Wrote `SOURCE.md` for HW3 question 9(c): source table, collected content, `dataset.csv` schema, column rationale, field mapping and expected size (2026-11-18). Added `PAIR.md`. Opened issues for open items: missing samples, file-name time zone, Twitch storage terms. |
| AI tools | Used Codex to write manual collection python script | Claude (AI assistant) was used to draft the wording of `SOURCE.md` and `PAIR.md`, check the schema with `jq` and calculate the size estimate. |

## Week 5: automatic collection with `bin/collect.sh` (HW4)

| | Matan Dan On | Nitzan Gavish |
|---|---|---|
| Work | Wrote `bin/collect.sh` in Bash (`curl`, `jq`, redirection) based on our Python reference scripts: fetches Steam once, follows every Twitch page cursor, keeps `id`, `viewer_count`, `language` and `tags` per stream, and publishes one complete UTC snapshot to `raw/YYYY-mm-dd/HHMM.json` without overwriting. Fixed the credentials path for his VM and verified a live collection (2026-11-25). | Reviewed `collect.sh` against the project contract and changed it to keep partial snapshots: each source is collected independently, a failed source is saved as `null`, an incomplete Twitch pagination is discarded, and each snapshot records `collection_status` and `source_status` (exit codes 0/2/1). Added `curl` retries, accepted `tags: null`, moved the credentials default outside the repository, made the script executable in git, added `.gitignore`, and documented all of this in `SOURCE.md` (2026-11-28). |
| AI tools | ChatGPT reviewed and helped revise the Bash collector, and tested pagination and failure handling against saved responses. | Claude (AI assistant) reviewed the collector against the contract, wrote the changes and tested them against mocked responses in a temporary copy. A second AI assistant reviewed the partial-snapshot design. |
