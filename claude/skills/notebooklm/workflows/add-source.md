# Add Source Workflow

Add any URL or local file to a NotebookLM notebook.

## Inputs

- **source**: URL or local file path to add
- **notebook-id** (optional): Target notebook. If not provided, use `notebooklm status` to get the active one, or ask user which notebook.

## Step 1: Determine Source Type

| Input looks like | Type | Command |
|-----------------|------|---------|
| `https://www.youtube.com/watch?v=...` | YouTube video | `add-url` |
| `https://youtu.be/...` | YouTube video | `add-url` |
| `https://...` (any other URL) | Webpage | `add-url` |
| `*.pdf` (local path) | PDF file | `add-file` |
| `*.png`, `*.jpg`, `*.jpeg`, `*.gif`, `*.webp` | Image file | `add-file` |
| Plain text (no URL, no file path) | Text | `add-text` |

## Step 2: Verify Auth

```bash
nlm auth status
```

If auth error, run [workflows/auth.md](auth.md).

## Step 3: Ensure Notebook is Set

```bash
# Check active notebook
notebooklm status

# If no active notebook or wrong one:
notebooklm use <notebook-id>
```

If user hasn't specified a notebook:
1. List available: `nlm notebook list`
2. Ask which one to use, or offer to create a new one

## Step 4: Add the Source

### URL (YouTube video, podcast, webpage, Google Docs/Slides)

```bash
notebooklm source add-url "<url>"
```

Or via nlm CLI:
```bash
nlm source add <notebook-id> --url "<url>"
```

### Local file (PDF, image)

```bash
notebooklm source add-file "<path>"
```

### Plain text

```bash
notebooklm source add-text "<text content>"
```

## Step 5: Verify

```bash
nlm source list <notebook-id> --json | python3 -c "
import json, sys
sources = json.load(sys.stdin)
if isinstance(sources, dict):
    sources = sources.get('sources', [])
print(f'{len(sources)} sources in notebook')
for s in sources[-3:]:
    title = s.get('title', 'Untitled')[:60]
    print(f'  - {title}')
"
```

Confirm the newly added source appears in the list.

## Step 6: Report

Tell the user:
- Source was added successfully
- Notebook ID and source count
- Note that NotebookLM may take a few minutes to finish indexing the source

## Adding Multiple URLs

If the user provides multiple URLs, add them sequentially:

```bash
for url in "<url1>" "<url2>" "<url3>"; do
  notebooklm source add-url "$url"
  echo "Added: $url"
done
```

Or for many URLs, use the notebooklm-py async API directly:

```python
import asyncio
from notebooklm import NotebookLMClient

async def add_urls(notebook_id, urls):
    client = await NotebookLMClient.from_storage()
    async with client:
        sem = asyncio.Semaphore(10)
        async def add(url):
            async with sem:
                try:
                    await client.sources.add_url(notebook_id, url)
                    print(f"OK: {url}")
                except Exception as e:
                    print(f"FAIL: {url} | {e}")
        await asyncio.gather(*[add(u) for u in urls])

asyncio.run(add_urls("<notebook-id>", ["<url1>", "<url2>", ...]))
```
