#!/bin/bash
set -e
rsync -avz --progress mks@10.13.37.151:~/printer_data/config/ ./config/
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "sync: config update $(date +%Y-%m-%d)"
  git push
fi
