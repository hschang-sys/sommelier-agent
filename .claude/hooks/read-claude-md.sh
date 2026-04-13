#!/bin/bash
# read-claude-md.sh
# UserPromptSubmit 훅: 유저 메시지마다 CLAUDE.md를 읽어 Claude 컨텍스트에 주입합니다.
set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // ""')

# CLAUDE.md 탐색: cwd 우선, 없으면 CLAUDE_PROJECT_DIR 사용
CLAUDE_MD_PATH=""
if [ -n "$cwd" ] && [ -f "$cwd/CLAUDE.md" ]; then
  CLAUDE_MD_PATH="$cwd/CLAUDE.md"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
  CLAUDE_MD_PATH="$CLAUDE_PROJECT_DIR/CLAUDE.md"
fi

# CLAUDE.md가 없으면 조용히 종료
if [ -z "$CLAUDE_MD_PATH" ]; then
  exit 0
fi

CLAUDE_MD_CONTENT=$(cat "$CLAUDE_MD_PATH")

# Claude 컨텍스트에 CLAUDE.md 내용을 systemMessage로 주입
jq -n --arg content "$CLAUDE_MD_CONTENT" '{
  "continue": true,
  "suppressOutput": true,
  "systemMessage": ("=== CLAUDE.md (반드시 읽고 따르세요) ===\n\n" + $content + "\n\n=== CLAUDE.md 끝 ===")
}'
