# YouTube Channel Loader Workflow

Bulk-load all videos from a YouTube channel into a NotebookLM notebook. No external dependencies for scraping. Uses InnerTube API for video discovery + notebooklm-py async API for parallel upload.

## Inputs

- **channel_url**: YouTube channel URL (e.g. `https://www.youtube.com/@LennysPodcast`)
- **notebook_name**: Name for the NotebookLM notebook (will create if needed)
- **count**: Number of most recent videos to load (default: 200, max: 300 per notebook)

## Step 1: Scrape Channel Videos

```bash
python3 ~/.claude/skills/notebooklm/scripts/load_channel.py scrape \
  --channel "https://www.youtube.com/@ChannelName" \
  --output /tmp/channel-videos.json
```

This:
1. Resolves the channel handle to a channel ID via page HTML
2. Uses InnerTube browse API to paginate through all videos
3. Follows continuation tokens until all videos are fetched
4. Saves JSON array: `[{id, title, length, views, published, url}, ...]`
5. Videos are ordered most recent first

No API key needed. No external dependencies. Pure stdlib.

## Step 2: Create Notebook

```bash
notebooklm create "{notebook_name}"
```

Note the notebook ID from the output.

## Step 3: Load Videos

```bash
python3 ~/.claude/skills/notebooklm/scripts/load_channel.py load \
  --videos /tmp/channel-videos.json \
  --notebook <notebook-id> \
  --count {count} \
  --concurrency 20
```

This:
1. Reads the video list JSON
2. Opens async NotebookLM client (uses `~/.notebooklm/storage_state.json`)
3. Fires `add_url` for each video with 20 concurrent requests
4. Reports progress and saves errors to `/tmp/channel-load-errors.json`

**Performance:** ~200 videos in ~75 seconds with concurrency=20.

## Step 4: Verify

```bash
nlm source list <notebook-id> --json | python3 -c "
import json, sys
sources = json.load(sys.stdin)
if isinstance(sources, dict):
    sources = sources.get('sources', [])
print(f'{len(sources)} sources loaded')
"
```

## Step 5: Report

Tell the user:
- How many videos were scraped from the channel
- How many were successfully loaded into NotebookLM
- The notebook ID (they'll need it for queries)
- Any failures (check `/tmp/channel-load-errors.json`)
- That NotebookLM needs a few minutes to index everything before queries work well

## Limits

- **300 sources per notebook.** For channels with 300+ videos, create multiple notebooks (e.g. `{channel}-part-1`, `{channel}-part-2`) and use `--skip` to offset:
  ```bash
  # First 300
  python3 ~/.claude/skills/notebooklm/scripts/load_channel.py load \
    --videos /tmp/channel-videos.json --notebook <id-1> --count 300

  # Next 300
  python3 ~/.claude/skills/notebooklm/scripts/load_channel.py load \
    --videos /tmp/channel-videos.json --notebook <id-2> --count 300 --skip 300
  ```
- **Some videos may fail** if they're private, deleted, or region-locked.
- **Processing time:** After upload, NotebookLM indexes each video server-side.

## Example: Full Pipeline

```bash
# 1. Scrape
python3 ~/.claude/skills/notebooklm/scripts/load_channel.py scrape \
  --channel "https://www.youtube.com/@LennysPodcast" \
  --output /tmp/lennys-videos.json

# 2. Create notebook
notebooklm create "Lenny's Podcast"
# -> 2a18a53d-be60-4951-af17-8b7303dc097e

# 3. Load 200 most recent
python3 ~/.claude/skills/notebooklm/scripts/load_channel.py load \
  --videos /tmp/lennys-videos.json \
  --notebook 2a18a53d-be60-4951-af17-8b7303dc097e \
  --count 200

# 4. Query
nlm notebook query 2a18a53d-be60-4951-af17-8b7303dc097e \
  "What are the top product management frameworks discussed?" --json
```
