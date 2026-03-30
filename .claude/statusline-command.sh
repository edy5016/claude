#!/usr/bin/env bash

# stdin 안전 처리 (블로킹 방지)
read -t 0.1 input || input=""

if [ -z "$input" ]; then
  echo "..."
  exit 0
fi

# Python 선택 (Windows 대응)
PYTHON=python


# JSON 파싱 - model
model=$($PYTHON -c "
import sys, json
try:
  data = json.loads(sys.stdin.read())
  print(data.get('model', {}).get('display_name', 'Unknown'))
except:
  print('Unknown')
" <<< "$input")

# JSON 파싱 - cwd
cwd=$($PYTHON -c "
import sys, json
try:
  data = json.loads(sys.stdin.read())
  print(data.get('cwd') or data.get('workspace', {}).get('current_dir', ''))
except:
  print('')
" <<< "$input")

# JSON 파싱 - context %
used_pct=$($PYTHON -c "
import sys, json
try:
  data = json.loads(sys.stdin.read())
  v = data.get('context_window', {}).get('used_percentage')
  print('' if v is None else v)
except:
  print('')
" <<< "$input")

# 경로 축약 (.../folder/subfolder)
short_cwd=$(echo "$cwd" | sed 's|\\|/|g' | awk -F/ '{
  if (NF>2) print ".../"$(NF-1)"/"$NF;
  else print $0
}')

# Git branch
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ANSI 색상
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"
SEP="${DIM} | ${RESET}"

# 출력 시작 (stderr로 출력)
printf "${CYAN}%s${RESET}" "$model" >&2
printf "${SEP}${GREEN}%s${RESET}" "$short_cwd" >&2

# Git branch 출력
[ -n "$git_branch" ] && printf "${SEP}${MAGENTA}%s${RESET}" "$git_branch" >&2

# Context 출력
if [ -n "$used_pct" ]; then
  used_int=$($PYTHON -c "print(round(float('$used_pct')))")
  
  if [ "$used_int" -ge 80 ]; then
    COLOR=$RED
  elif [ "$used_int" -ge 50 ]; then
    COLOR=$YELLOW
  else
    COLOR=$GREEN
  fi

  printf "${SEP}${COLOR}CTX %s%%${RESET}" "$used_int" >&2
else
  printf "${SEP}${DIM}CTX -" >&2
fi

printf "\n" >&2