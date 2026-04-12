# Manage Notebooks Workflow

Create, list, and switch between NotebookLM notebooks.

## List All Notebooks

```bash
nlm notebook list
```

Returns notebook IDs, names, and source counts.

## Create a New Notebook

```bash
notebooklm create "<notebook name>"
```

Returns the new notebook ID. Save this for future operations.

## Switch Active Notebook

Some `notebooklm` commands operate on the "active" notebook:

```bash
notebooklm use <notebook-id>
```

Check which notebook is active:
```bash
notebooklm status
```

## List Sources in a Notebook

```bash
nlm source list <notebook-id> --json
```

For a summary:
```bash
nlm source list <notebook-id> --json | python3 -c "
import json, sys
sources = json.load(sys.stdin)
if isinstance(sources, dict):
    sources = sources.get('sources', [])
print(f'{len(sources)} sources:')
for s in sources:
    t = s.get('title', 'Untitled')[:60]
    st = s.get('type', 'unknown')
    print(f'  [{st}] {t}')
"
```

## Delete a Source

```bash
nlm source delete <notebook-id> <source-id>
```

## Notebook Naming Conventions

When creating notebooks for the user, suggest clear names:
- YouTube channel: `"{Channel Name}"` (e.g. `"Huberman Lab"`)
- Research topic: `"{Topic} Research"` (e.g. `"Sleep Optimization Research"`)
- Project: `"{Project} Reference"` (e.g. `"Migration Guide Reference"`)

## Multi-Notebook Strategy

For large content collections (300+ sources), split across notebooks:
- `"{Name} Part 1"`, `"{Name} Part 2"`, etc.
- Or by subtopic: `"{Channel} - Health"`, `"{Channel} - Productivity"`
