# Ask Notebook Workflow

Ask a NotebookLM notebook a question and get a cited answer.

## Inputs

- **question**: The question to ask
- **notebook-id**: Full UUID of the notebook (from `nlm notebook list`)

## Step 1: Verify Auth

```bash
nlm auth status
```

If auth error, run `nlm auth login` (browser flow).

## Step 2: Get Sources (optional, for context)

```bash
nlm source list <notebook-id> --json > /tmp/nlm-sources.json
```

Use this to understand what content the notebook contains before querying.

## Step 3: Ask the Question

```bash
nlm notebook query <notebook-id> "<question>" --json > /tmp/qa-output.json
```

## Step 4: Parse and Present the Answer

Read the JSON output and present the answer to the user with citations:

```python
import json

with open("/tmp/qa-output.json") as f:
    data = json.load(f)

# Handle both formats
if "value" in data:
    qa = data["value"]
else:
    qa = data

answer = qa["answer"]
references = qa.get("references", [])

print("## Answer\n")
print(answer)
print(f"\n## Citations ({len(references)} references)\n")
for ref in references:
    cn = ref.get("citation_number", "?")
    source_id = ref.get("source_id", "")
    cited_text = ref.get("cited_text", "")[:200]
    print(f"[{cn}] {cited_text}...")
```

The answer contains `[N]` citation markers. Each marker corresponds to a reference with:
- `citation_number`: The `[N]` number
- `source_id`: Which source it came from
- `cited_text`: The exact passage being cited

## Step 5: Present to User

Format the answer clearly:
1. The main answer text with `[N]` citation markers intact
2. A citations section listing what each `[N]` refers to
3. Optionally, resolve source_ids to source titles using the sources list from Step 2

### Resolving Source Titles

```python
import json

sources = json.load(open("/tmp/nlm-sources.json"))
if isinstance(sources, dict):
    sources = sources.get("sources", sources.get("value", []))

source_titles = {s["id"]: s["title"] for s in sources}

# Now for each reference:
for ref in references:
    title = source_titles.get(ref["source_id"], "Unknown source")
    print(f"[{ref['citation_number']}] From: {title}")
    print(f"    \"{ref['cited_text'][:150]}...\"")
```

## Follow-up Questions

The user can ask follow-up questions. Just re-run Step 3 with the new question against the same notebook-id.

## Multi-Notebook Queries

If the user's question might span multiple notebooks, query each one and synthesize:

```bash
nlm notebook query <notebook-id-1> "<question>" --json > /tmp/qa-1.json
nlm notebook query <notebook-id-2> "<question>" --json > /tmp/qa-2.json
```

Then combine the answers and deduplicate citations.
