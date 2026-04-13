#!/bin/bash
# read-rules-md.sh
# UserPromptSubmit 훅: 유저 메시지마다 RULES.md를 읽어 Claude 컨텍스트에 주입합니다.
# jq 없이 Python으로 JSON 처리

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

# Python이 파일을 직접 읽어 JSON 출력
# - 따옴표 heredoc(<<'PYEOF')으로 셸 변수 확장 차단 (shell injection 수정)
# - sys.argv[1]로 파일 경로 전달 (heredoc $변수 취약점 제거)
# - 오류 발생 시 continue:true 반환 (프롬프트 차단 방지)
if ! python3 - "$RULES_MD_PATH" << 'PYEOF'
import sys, json
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        content = f.read()
    output = {
        'continue': True,
        'suppressOutput': True,
        'systemMessage': '=== RULES.md (MCP 운영 규칙 - 작업 전 반드시 확인) ===\n\n' + content + '\n\n=== RULES.md 끝 ==='
    }
except Exception:
    output = {'continue': True, 'suppressOutput': True}
print(json.dumps(output, ensure_ascii=False))
PYEOF
then
  printf '{"continue":true,"suppressOutput":true}\n'
fi
