# Auth Workflow

Authenticate with NotebookLM services. There are two auth systems — both are needed for full functionality.

## When Needed

Any `nlm` or `notebooklm` command returns auth errors or redirects to accounts.google.com.

## Auth 1: nlm CLI (queries, source listing)

```bash
nlm auth login
```

Opens a browser for Google login. Tokens saved to nlm's config directory.

Verify:
```bash
nlm auth status
```

## Auth 2: notebooklm-py (notebook creation, bulk loading, file uploads)

**User must run this themselves** (requires interactive browser).

```bash
notebooklm login
```

Flow:
1. Browser opens to Google login
2. User completes login + 2FA
3. Waits until NotebookLM homepage loads
4. User presses Enter in terminal
5. Cookies saved to `~/.notebooklm/storage_state.json`

Verify:
```bash
notebooklm list
```

Should show notebook list without errors.

## Troubleshooting

**Browser doesn't open:** Playwright chromium may not be installed:
```bash
playwright install chromium
```

**Wrong Google account:** Login opens a fresh browser profile at `~/.notebooklm/browser_profile`. Delete this folder to re-login with a different account.

**Auth expires:** Google cookies typically last weeks. Re-run the relevant login command when operations start failing.

**Which auth do I need?**
| Operation | Auth needed |
|-----------|------------|
| `nlm notebook query` | nlm CLI |
| `nlm source list` | nlm CLI |
| `notebooklm create` | notebooklm-py |
| `notebooklm source add-url` | notebooklm-py |
| `notebooklm source add-file` | notebooklm-py |
| `load_channel.py load` | notebooklm-py |
