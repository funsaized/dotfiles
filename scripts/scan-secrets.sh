#!/usr/bin/env bash
#
#  Credential scanner for this repo.
#
#  This repo publishes editor configs that have API-key FIELDS in them. The
#  fields are supposed to hold "YOUR KEY HERE". One careless `cp` from a live
#  machine and they hold a real token instead — in a public repo.
#
#    ./scripts/scan-secrets.sh            scan the working tree
#    ./scripts/scan-secrets.sh --staged   scan only what's staged (hook mode)
#    ./scripts/scan-secrets.sh --install  install as a pre-commit hook
#
#  Exit 0 = clean, 1 = something that looks like a live credential.
#
set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Patterns are deliberately anchored to real token shapes, not the word
# "token", so that documentation and placeholders don't trip them.
PATTERNS=(
  'ghp_[A-Za-z0-9]{30,}'                 # GitHub personal access token
  'gho_[A-Za-z0-9]{30,}'                 # GitHub OAuth token
  'github_pat_[A-Za-z0-9_]{50,}'         # GitHub fine-grained PAT
  'ctx7sk-[a-f0-9]{8}-[a-f0-9]{4}'       # Context7 API key
  'sk-[A-Za-z0-9]{32,}'                  # OpenAI-style key
  'sk-ant-[A-Za-z0-9_-]{20,}'            # Anthropic key
  'AKIA[0-9A-Z]{16}'                     # AWS access key id
  'xox[baprs]-[A-Za-z0-9-]{10,}'         # Slack token
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'   # private key material
)
RE=$(IFS='|'; echo "${PATTERNS[*]}")

case "${1:-}" in
  --install)
    hook=.git/hooks/pre-commit
    printf '#!/usr/bin/env bash\nexec ./scripts/scan-secrets.sh --staged\n' > "$hook"
    chmod +x "$hook"
    echo "✓ installed pre-commit hook -> $hook"
    exit 0
    ;;
  --staged)
    # Scan the staged blob content, not the working tree — the working tree
    # may be clean while the index is not.
    files=$(git diff --cached --name-only --diff-filter=ACM)
    [[ -z $files ]] && { echo "✓ nothing staged"; exit 0; }
    hits=""
    while IFS= read -r f; do
      [[ -z $f ]] && continue
      m=$(git show ":$f" 2>/dev/null | grep -nEo "$RE" | head -3)
      [[ -n $m ]] && hits+=$'\n'"  $f: $m"
    done <<< "$files"
    ;;
  *)
    hits=$(grep -rInE "$RE" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null)
    ;;
esac

if [[ -n ${hits// } ]]; then
  printf '\033[31m✗ possible live credential detected\033[0m\n%s\n\n' "$hits"
  echo "If this is a real key: rotate it now, then replace with a placeholder."
  echo "If it is a false positive: refine PATTERNS in scripts/scan-secrets.sh."
  exit 1
fi

echo "✓ no credentials detected"
exit 0
