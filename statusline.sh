#!/usr/bin/env bash

# Claude Code statusLine script: renders project/git context, model/context-window
# usage, session duration, and rate limits.
# https://github.com/k8adev/claude-code-statusline

input=$(cat)

# Project & workspace
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PROJECT="${DIR##*/}"

# Worktree / Branch
WORKTREE=$(echo "$input" | jq -r '.worktree.name // empty')
if [ -n "$WORKTREE" ]; then
  BRANCH=$(echo "$input" | jq -r '.worktree.branch // empty')
  GIT_INFO="${WORKTREE}/${BRANCH}"
else
  GIT_INFO=$(git -C "$DIR" branch --show-current 2>/dev/null)
fi

# LOC (lines added/removed this session)
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Model
MODEL=$(echo "$input" | jq -r '.model.display_name')

# Context window
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Rate limits
FIVE_HR=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SEVEN_DAY=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
FIVE_HR_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' | cut -d. -f1)
SEVEN_DAY_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' | cut -d. -f1)

# Persist rate limits so tmux (ai-limits.sh) can show them outside this session
RL_CACHE="${CLAUDE_STATUSLINE_RL_CACHE:-$HOME/.claude/cache/rate-limits.json}"
if [ -n "$FIVE_HR$SEVEN_DAY" ]; then
  mkdir -p "$(dirname "$RL_CACHE")"
  echo "$input" | jq -c --argjson ts "$(date +%s)" '{ts:$ts, five_hour:.rate_limits.five_hour, seven_day:.rate_limits.seven_day}' > "$RL_CACHE.tmp" 2>/dev/null && mv "$RL_CACHE.tmp" "$RL_CACHE"
fi

# Duration
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
HOURS=$((DURATION_MS / 3600000))
MINS=$(((DURATION_MS % 3600000) / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# Colors — Anthropic brand palette (Clay / Kraft / Sky / Olive / Fig / Deep)
rgb() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
ACCENT=$(rgb D97757)        # Clay — project name
FG=$(rgb B0AEA5)            # text secondary
COMMENT=$(rgb 5E5D59)       # text muted — separators
GREEN=$(rgb 788C5D)         # Olive
YELLOW=$(rgb D4A27F)        # Kraft
RED=$(rgb C6613F)           # Deep
MAGENTA=$(rgb C46686)       # Fig
DIM='\033[2m'
RESET='\033[0m'
GRAY="$FG"; TERRA="$YELLOW"; TERRA_LIGHT="$ACCENT"

# Icons — Nerd Font Material glyphs, each overridable via CLAUDE_STATUSLINE_ICON_*
# (mirrors tmux-vitals' @vitals_icon_* option pattern).
ICON_DIR="${CLAUDE_STATUSLINE_ICON_DIR:-󰉋}"
ICON_CLOCK="${CLAUDE_STATUSLINE_ICON_CLOCK:-󰥔}"
ICON_RESET="${CLAUDE_STATUSLINE_ICON_RESET:-󰑐}"

# Usage-limit thresholds: green up to LIMIT_WARN, yellow above it, red above LIMIT_CRIT
# (50-30-20 split by default; tmux-vitals uses 60/85 via @vitals_warn/@vitals_crit).
LIMIT_WARN="${CLAUDE_STATUSLINE_LIMIT_WARN:-50}"
LIMIT_CRIT="${CLAUDE_STATUSLINE_LIMIT_CRIT:-80}"
# Context-window thresholds: earlier than the limits — Anthropic's own guidance is that
# performance degrades as the window fills, and used_percentage counts input tokens only.
CTX_WARN="${CLAUDE_STATUSLINE_CTX_WARN:-30}"
CTX_CRIT="${CLAUDE_STATUSLINE_CTX_CRIT:-60}"

# level_color <percent> -> GREEN/YELLOW/RED
level_color() {
  local percent="${1:-0}"
  if ((percent > LIMIT_CRIT)); then
    echo "$RED"
  elif ((percent > LIMIT_WARN)); then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

# until_epoch <epoch> -> "4d 3h" | "4h26" (mirrors tmux-vitals' scripts/vitals.sh until_epoch)
until_epoch() {
  local target="$1" now secs
  now=$(date +%s)
  secs=$((target - now))
  ((secs < 0)) && secs=0
  if ((secs >= 86400)); then
    printf "%dd %dh" $((secs / 86400)) $((secs % 86400 / 3600))
  else
    printf "%dh%02d" $((secs / 3600)) $((secs % 3600 / 60))
  fi
}

# Context color: green up to CTX_WARN, yellow above it, red above CTX_CRIT
if [ "$PCT" -gt "$CTX_CRIT" ]; then CTX_COLOR="$RED"
elif [ "$PCT" -gt "$CTX_WARN" ]; then CTX_COLOR="$YELLOW"
else CTX_COLOR="$GREEN"; fi

# Context bar (braille: filled ⣿, dotted baseline ⣀ for the rest — same look as the tmux theme)
FILLED=$((PCT / 5))
EMPTY=$((20 - FILLED))
BAR="${CTX_COLOR}$(printf "%${FILLED}s" | sed 's/ /⣿/g')${DIM}$(printf "%${EMPTY}s" | sed 's/ /⣀/g')${RESET}"

# Duration format
if [ "$HOURS" -gt 0 ]; then
  DURATION="${HOURS}h${MINS}"
else
  DURATION="${MINS}m"
fi

# Line 1: [icon] [project] ([branch]) [LOC]
LINE1="${GRAY}${ICON_DIR}${RESET} ${TERRA_LIGHT}${PROJECT}${RESET}"
[ -n "$GIT_INFO" ] && LINE1="${LINE1} ${COMMENT}(${RESET}${GRAY}${GIT_INFO}${RESET}${COMMENT})${RESET}"
LINE1="${LINE1} ${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
echo -e "$LINE1"

# Line 2: [model] [context bar + %] [icon] [session duration]
echo -e "${GRAY}${MODEL}${RESET} ${BAR} ${GRAY}${PCT}%${RESET} ${COMMENT}·${RESET} ${GRAY}${ICON_CLOCK} ${DURATION}${RESET}"

# Line 3 visibility: CLAUDE_STATUSLINE_LIMITS = auto (default) | always | never.
# "auto" hides the limits when this session runs inside tmux AND tmux-vitals' Claude segment is
# already in the tmux status bar (the same numbers would be shown twice, one line apart).
LIMITS_MODE="${CLAUDE_STATUSLINE_LIMITS:-auto}"
show_limits() {
  case "$LIMITS_MODE" in
    always) return 0 ;;
    never)  return 1 ;;
  esac
  [ -z "$TMUX" ] && return 0
  # show-options takes one option per call
  ! { tmux show -g status-format; tmux show -g status-left; tmux show -g status-right; } 2>/dev/null \
    | grep -q 'vitals_claude\|vitals.sh claude\|vitals_llm\|vitals.sh llm'
}

# Line 3: same layout as tmux-vitals' segment_claude/render_provider (scripts/helpers.sh:219-255,
# scripts/vitals.sh:257-259), minus the leading "✳ Claude" icon+label — 5h/7d usage with the
# same warn/crit thresholds and reset countdown via ICON_RESET. Falls back to the vitals
# no-cache placeholder ("—") when rate limits are absent from this session's payload.
if ! show_limits; then
  :
elif [ -n "$FIVE_HR" ] || [ -n "$SEVEN_DAY" ]; then
  LINE3=""
  if [ -n "$FIVE_HR" ]; then
    COLOR5="$(level_color "$FIVE_HR")"
    LINE3="${GRAY}5h${RESET} ${COLOR5}${FIVE_HR}%${RESET}"
    [ -n "$FIVE_HR_RESET" ] && LINE3="${LINE3} ${COMMENT}${ICON_RESET} $(until_epoch "$FIVE_HR_RESET")${RESET}"
  fi
  if [ -n "$SEVEN_DAY" ]; then
    COLOR7="$(level_color "$SEVEN_DAY")"
    if [ -n "$FIVE_HR" ]; then
      LINE3="${LINE3} ${COMMENT}·${RESET} ${GRAY}7d${RESET} ${COLOR7}${SEVEN_DAY}%${RESET}"
    else
      LINE3="${GRAY}7d${RESET} ${COLOR7}${SEVEN_DAY}%${RESET}"
    fi
    [ -n "$SEVEN_DAY_RESET" ] && LINE3="${LINE3} ${COMMENT}${ICON_RESET} $(until_epoch "$SEVEN_DAY_RESET")${RESET}"
  fi
  echo -e "$LINE3"
else
  echo -e "${DIM}—${RESET}"
fi
