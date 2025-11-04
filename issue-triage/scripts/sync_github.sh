#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PENDING_DIR="$ROOT_DIR/pending_issues"
mkdir -p "$PENDING_DIR"

# Fetch open issues
if ! gh issue list --state open --limit 200 --json number,title,author,labels,createdAt,updatedAt,body,url,assignees \
  | jq '.' > "$PENDING_DIR/open_issues.json"; then
  echo "Failed to fetch open issues" >&2
  exit 1
fi

echo "Wrote $(jq 'length' "$PENDING_DIR/open_issues.json") open issues to $PENDING_DIR/open_issues.json"

# Fetch open pull requests
if ! gh pr list --state open --limit 200 --json number,title,author,labels,createdAt,updatedAt,body,url,headRefName,baseRefName \
  | jq '.' > "$PENDING_DIR/open_prs.json"; then
  echo "Failed to fetch open pull requests" >&2
  exit 1
fi

echo "Wrote $(jq 'length' "$PENDING_DIR/open_prs.json") open pull requests to $PENDING_DIR/open_prs.json"
