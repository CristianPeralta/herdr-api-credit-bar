#!/bin/bash
# ponytail: fixed anchor pane via label (pane_id is ephemeral across restarts)
set -euo pipefail
LABEL="api-credit-bar-alibaba"
PANE_ID=$(herdr pane list | jq -r ".result.panes[] | select(.label==\"$LABEL\") | .pane_id" | head -1)
if [ -z "$PANE_ID" ]; then
  PANE_ID=$(herdr pane split --current --direction down --ratio 0.85 --no-focus | jq -r '.result.pane.pane_id')
  herdr pane rename "$PANE_ID" "$LABEL" >/dev/null
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
herdr pane run "$PANE_ID" "bash $SCRIPT_DIR/providers/alibaba.sh"
