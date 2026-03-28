#!/bin/bash
# sonmat session-start hook for Codex CLI
# 경량 도메인 판단 + System 1 컨텍스트 로딩

# Detect domain from workspace files
DOMAIN="general"

if [ -f "pyproject.toml" ]; then
  if grep -q "torch\|tensorflow\|transformers\|scikit-learn" pyproject.toml 2>/dev/null; then
    DOMAIN="ai-ml-dl"
  else
    DOMAIN="dev"
  fi
elif [ -f "package.json" ] || [ -f "tsconfig.json" ]; then
  DOMAIN="dev"
elif ls *.ipynb 1>/dev/null 2>&1; then
  if grep -q "pandas\|numpy\|matplotlib" *.ipynb 2>/dev/null; then
    DOMAIN="analysis"
  else
    DOMAIN="ai-ml-dl"
  fi
elif [ -d "docs" ] && ls docs/*.md 1>/dev/null 2>&1; then
  DOMAIN="document"
fi

# Output as JSON for Codex CLI hook system
cat << EOF
{"additionalContext": "sonmat 활성화됨. 감지된 도메인: ${DOMAIN}. 대화 중 도메인은 태스크 단위로 전환 가능."}
EOF
