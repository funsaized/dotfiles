---
name: notebooklm
description: "Import content into Google NotebookLM and query it with cited answers. Supports YouTube channels (bulk load 300 episodes), individual YouTube videos, podcasts, webpages, PDFs, and images. Use when user says \"notebooklm\", \"load channel\", \"add to notebook\", \"notebooklm ask\", \"import into notebooklm\", or wants to add any link/file to NotebookLM."
---

# NotebookLM Bridge

Import any content into Google NotebookLM from Claude. YouTube channels, individual videos, podcasts, webpages, PDFs, images. Query notebooks and get cited answers back.

## What This Does

1. **Bulk-load YouTube channels.** One command. Up to 300 episodes into a single notebook.
2. **Add any URL.** YouTube video, podcast episode, webpage, Google Doc/Slides — anything NotebookLM accepts.
3. **Add local files.** PDFs and images via the notebooklm-py API.
4. **Query with citations.** Ask questions, get answers with `[N]` citation markers traced to exact source passages.
5. **Manage notebooks.** Create, list, switch active notebooks.

## Prerequisites

### 1. Install nlm CLI

```bash
uv tool install notebooklm-mcp-cli
```

Gives you the `nlm` command. See [notebooklm-mcp-cli](https://github.com/jacob-bd/notebooklm-mcp-cli) for details.

### 2. Install notebooklm-py (for notebook creation and bulk loading)

```bash
pip install "notebooklm-py[browser]"
playwright install chromium
```

### 3. Authenticate

```bash
# nlm CLI auth (for queries and source listing)
nlm auth login

# notebooklm-py auth (for notebook creation and loading)
notebooklm login
```

Both open a browser window for Google login. `nlm` saves to its own config, `notebooklm-py` saves cookies to `~/.notebooklm/storage_state.json`.

## Quick Start

```bash
# List your notebooks
nlm notebook list

# Ask a question with citations
nlm notebook query <notebook-id> "What does the expert say about X?" --json

# List sources in a notebook
nlm source list <notebook-id> --json
```

## Workflow Routing

| User says | Workflow |
|-----------|----------|
| "load channel", "youtube channel", "bulk load" | [workflows/youtube-channel.md](workflows/youtube-channel.md) |
| "add video", "add webpage", "add pdf", "add url", "import link" | [workflows/add-source.md](workflows/add-source.md) |
| "ask notebook", "query", "notebooklm ask" | [workflows/ask.md](workflows/ask.md) |
| "notebooklm auth", "notebooklm login" | [workflows/auth.md](workflows/auth.md) |
| "list notebooks", "create notebook", "switch notebook" | [workflows/manage.md](workflows/manage.md) |

## Supported Source Types

| Type | How to add | Notes |
|------|-----------|-------|
| YouTube channel | `load_channel.py scrape` + `load` | Bulk: up to 300 videos per notebook |
| YouTube video | `notebooklm source add-url <url>` | Single video by URL |
| Podcast episode | `notebooklm source add-url <url>` | Any URL NotebookLM can index |
| Webpage | `notebooklm source add-url <url>` | Articles, docs, blog posts |
| PDF | `notebooklm source add-file <path>` | Local file upload |
| Image | `notebooklm source add-file <path>` | Local file upload |
| Google Docs | `notebooklm source add-url <url>` | Shared Google Doc link |
| Google Slides | `notebooklm source add-url <url>` | Shared Google Slides link |
| Plain text | `notebooklm source add-text "<text>"` | Inline text content |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/load_channel.py` | Scrape YouTube channel + bulk-load into NotebookLM |

## Limits

- **300 sources per notebook.** For channels with 300+ videos, create multiple notebooks.
- **Processing time.** After upload, NotebookLM indexes each source server-side. Takes a few minutes. Sources may show as "processing" initially.
- **Auth expiry.** Google cookies last weeks. Re-run login when commands start failing.

## License

MIT (based on [ArtemXTech/personal-os-skills](https://github.com/ArtemXTech/personal-os-skills))
