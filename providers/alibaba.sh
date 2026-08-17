#!/bin/bash
# ponytail: credit constants (nominal $200, start 2026-06) are a fact of THIS
# account's Alibaba coupon, not generic config. If a second credit source
# shows up, move to plugins/config/api-credit-bar/config.toml then.
# no -e: aliyun failures (missing CLI, no auth) are handled explicitly below,
# not left to crash the pane silently.
set -uo pipefail
CREDIT_NOMINAL=200
CREDIT_START_YEAR=2026
CREDIT_START_MONTH=6
SIDE_PAD=2

term_width() { tput cols 2>/dev/null || echo 40; }

# center a line within (terminal width - side padding), stripping ANSI codes
# from the width calc so colored text still centers correctly
center_line() {
  local raw="$1" visible width inner pad_total pad_left
  visible=$(sed -E 's/\x1b\[[0-9;]*m//g' <<<"$raw")
  width=$(term_width)
  inner=$((width - SIDE_PAD * 2))
  ((inner < ${#visible})) && inner=${#visible}
  pad_total=$((inner - ${#visible}))
  pad_left=$((pad_total / 2))
  printf "%*s%*s%b\n" "$SIDE_PAD" "" "$pad_left" "" "$raw"
}

# evenly space 3 items across (terminal width - side padding).
# used for a 3-part footer (time / q quit / r refresh), not just a left+right block
justify_three() {
  local a="$1" b="$2" c="$3" va vb vc width inner total gap1 gap2
  va=$(sed -E 's/\x1b\[[0-9;]*m//g' <<<"$a")
  vb=$(sed -E 's/\x1b\[[0-9;]*m//g' <<<"$b")
  vc=$(sed -E 's/\x1b\[[0-9;]*m//g' <<<"$c")
  width=$(term_width)
  inner=$((width - SIDE_PAD * 2))
  total=$((inner - ${#va} - ${#vb} - ${#vc}))
  ((total < 2)) && total=2
  gap1=$((total / 2))
  gap2=$((total - gap1))
  printf "%*s%b%*s%b%*s%b\n" "$SIDE_PAD" "" "$a" "$gap1" "" "$b" "$gap2" "" "$c"
}

# ponytail: only the credit line gets a bar. it has a real cap ($CREDIT_NOMINAL).
# "gross" is pay-as-you-go with no ceiling, a bar would misrepresent it as bounded.
# Bar color is Alibaba's brand orange (256-color 208), dimmed a notch (SGR 2).
render_bar() {
  local label=$1 pct=$2 width=14 filled color="\e[2;38;5;208m" dim="\e[2m" reset="\e[0m" out=""
  ((pct < 0)) && pct=0
  ((pct > 100)) && pct=100
  filled=$((pct * width / 100))
  out+=$(printf "%-7s " "$label")
  out+=$(printf "%b" "$color")
  for ((i = 0; i < filled; i++)); do out+="█"; done
  out+=$(printf "%b" "$dim")
  for ((i = filled; i < width; i++)); do out+="░"; done
  out+=$(printf "%b %d%% left" "$reset" "$pct")
  center_line "$out"
}

while true; do
  clear
  now_year=$(date -u +%Y)
  now_month=$((10#$(date -u +%m)))
  months=$(((now_year - CREDIT_START_YEAR) * 12 + now_month - CREDIT_START_MONTH))
  ((months < 0)) && months=0
  ((months > 3)) && months=3

  # credit is a whole-account shared pool, sum deductions across ALL products
  # (not just model inference), otherwise "remaining" would be inflated.
  used=0
  error=""
  for offset in $(seq 0 "$months"); do
    cycle=$(date -u -d "${CREDIT_START_YEAR}-0${CREDIT_START_MONTH}-01 +${offset} month" +%Y-%m)
    resp=$(aliyun bssopenapi QueryBillOverview --BillingCycle "$cycle" 2>&1)
    if [ $? -ne 0 ]; then
      error=$(sed -n '1p' <<<"$resp")
      break
    fi
    d=$(jq -r '[.Data.Items.Item[]?.DeductedByCoupons] | add // 0' <<<"$resp" 2>/dev/null)
    used=$(echo "$used + ${d:-0}" | bc)
  done

  printf "%*sAlibaba · Model Studio\n" "$SIDE_PAD" ""
  echo
  if [ -n "$error" ]; then
    center_line "$(printf '\e[2mnot authenticated: %s\e[0m' "$error")"
  else
    remaining=$(echo "$CREDIT_NOMINAL - $used" | bc)
    pct=$(echo "scale=0; ($remaining * 100) / $CREDIT_NOMINAL / 1" | bc)
    render_bar "credits" "$pct"
  fi
  echo
  justify_three \
    "$(printf '\e[2m%s\e[0m' "$(date -u +%H:%M)")" \
    "$(printf '\e[2mq quit\e[0m')" \
    "$(printf '\e[2mr refresh\e[0m')"

  # ponytail: poll for q/r instead of a blind 30min sleep, so the footer's
  # "q quit · r refresh" is real, not decorative.
  elapsed=0
  while ((elapsed < 1800)); do
    if read -rsn1 -t 1 key; then
      [[ "$key" == "q" ]] && exit 0
      [[ "$key" == "r" ]] && break
    fi
    elapsed=$((elapsed + 1))
  done
done
