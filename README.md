# sonmat (손맛) for Codex CLI

> 엄마가 하면 맛있던데 왜 내가 하면...?

범용 자율 루프 플러그인 for Codex CLI.
[Claude Code 버전](https://github.com/jun0-ds/sonmat)의 Codex CLI 포팅.

## 설치

플러그인 디렉토리에 복사:

```bash
# 개인 설치
cp -R sonmat-codex ~/.codex/plugins/sonmat

# marketplace.json에 등록
```

또는 `~/.agents/plugins/marketplace.json`에 추가:

```json
{
  "name": "sonmat-marketplace",
  "interface": {
    "displayName": "sonmat"
  },
  "plugins": [
    {
      "name": "sonmat",
      "source": {
        "source": "github",
        "repo": "jun0-ds/sonmat-codex"
      },
      "category": "workflow"
    }
  ]
}
```

## 특징

- **System 1/2 이중 프로세스** — 빠른 판단(스킬)과 깊은 분석(워커)을 상황에 따라 자동 전환
- **범용 루프 엔진** — 개발, ML/DL, 데이터 분석, 문서, 글쓰기 등 도메인별 자율 반복
- **경량 규율 주입** — core.md + 도메인 규율이 워커에 실제로 전달됨

## 구조

```
sonmat-codex/
├── .codex-plugin/
│   └── plugin.json
├── skills/
│   ├── loop/        # 범용 자율 루프 프로토콜
│   ├── guard/       # 가드레일 (커밋 전 검증, 스코프 체크)
│   ├── plan/        # 마일스톤/페이즈 관리 (progress.md)
│   ├── benchmark/   # 비교실험 프레임워크
│   └── discipline/  # 도메인별 규율 파일
├── agents/
│   └── sonmat-worker.md
└── hooks/
```

## 사용법

설치 후 Codex CLI를 시작하면 sonmat이 자동으로 동작합니다.
도메인 자동 판단, 규율 주입, 에스컬레이션 등은 Claude Code 버전과 동일합니다.

## 라이선스

MIT
