#!/bin/bash
# read-rules-md.sh
# UserPromptSubmit 훅: 유저 메시지마다 RULES.md를 읽어 Claude 컨텍스트에 주입합니다.
# jq 없이 Python으로 JSON 처리
set -euo pipefail

input=$(cat)

# Python으로 cwd 파싱 (jq 불필요)
cwd=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# RULES.md 탐색: cwd 우선, 없으면 CLAUDE_PROJECT_DIR 사용
RULES_MD_PATH=""
if [ -n "$cwd" ] && [ -f "$cwd/RULES.md" ]; then
  RULES_MD_PATH="$cwd/RULES.md"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${CLAUDE_PROJECT_DIR}/RULES.md" ]; then
  RULES_MD_PATH="${CLAUDE_PROJECT_DIR}/RULES.md"
fi

# RULES.md가 없으면 조용히 종료
if [ -z "$RULES_MD_PATH" ]; then
  exit 0
fi

RULES_MD_CONTENT=$(cat "$RULES_MD_PATH")

# Python으로 JSON 출력 (jq 불필요)
python3 -c "
import sys, json
content = sys.stdin.read()
output = {
    'continue': True,
    'suppressOutput': True,
    'systemMessage': '=== RULES.md (MCP 운영 규칙 - 작업 전 반드시 확인) ===\n\n' + content + '\n\n=== RULES.md 끝 ==='
}
print(json.dumps(output, ensure_ascii=False))
" <<EOF
$RULES_MD_CONTENT
EOF
