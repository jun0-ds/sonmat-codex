# sonmat (손맛) for Codex CLI

> 엄마가 하면 맛있던데 왜 내가 하면...?
>
> Your AI is confident. Your AI can still be wrong.

범용 자율 루프 플러그인 for Codex CLI.
[Claude Code 버전](https://github.com/jun0-ds/sonmat)의 Codex CLI 포팅.

## What This Is

sonmat is a Codex-oriented discipline layer for autonomous loops:

- `loop` — plan -> execute -> evaluate -> judge -> repeat/exit
- `guard` — pre-commit and scope guardrails
- `plan` — milestone/phase/task progression
- `benchmark` — compare strategies quantitatively

핵심은 "확신할수록 검증"입니다.

## Quick Start (No Claude Setup)

처음 링크를 받은 사람이 바로 따라할 수 있는 최소 절차입니다.

### 0) Run Codex from project root

예: `~/work/my-project`에서 `codex` 실행.
(전역 설정은 홈 경로에, 실행은 프로젝트 루트에서)

### 1) Configure Codex runtime

Create `~/.codex/config.toml`:

```toml
approval_policy = "never"
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = true
```

### 2) Register marketplace

Create `~/.agents/plugins/marketplace.json`:

```json
{
  "name": "jun0-marketplace",
  "interface": {
    "displayName": "jun0 plugins"
  },
  "plugins": [
    {
      "name": "sonmat",
      "source": {
        "source": "github",
        "repo": "jun0-ds/sonmat-codex"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

### 3) Reload and verify

- Codex를 완전히 재시작
- `/plugins` 또는 `/skills`에서 `sonmat` 확인
- 빠른 확인: `codex exec --skip-git-repo-check -C "$PWD" "List installed skills named loop, guard, plan, benchmark"`

안 보이면 캐시를 지우고 다시 시작:

```bash
rm -rf ~/.codex/.tmp/plugins
```

## Windows Guide (WSL2 Recommended)

Windows에서는 **WSL2(Ubuntu)** 안에서 Codex를 실행하는 것을 권장합니다.

### Why WSL2?

- 문서의 `~/.codex`, `~/.agents` 경로를 그대로 사용할 수 있음
- Linux 명령(`rm`, `mkdir`, `cat`)을 그대로 사용 가능
- 경로/권한 이슈가 Windows 네이티브 실행보다 적음

### Steps on Windows

1. WSL2 Ubuntu에서 Codex를 설치/실행한다.
2. 아래 Linux 경로 기준으로 동일하게 설정한다.
   - `~/.codex/config.toml`
   - `~/.agents/plugins/marketplace.json`
3. 프로젝트도 WSL 경로(예: `~/work/my-project`)에서 열고 `codex`를 실행한다.

### If you must run on Windows native

- 홈 경로를 `%USERPROFILE%` 기준으로 매핑해야 한다.
- 경로 예시:
  - `%USERPROFILE%\\.codex\\config.toml`
  - `%USERPROFILE%\\.agents\\plugins\\marketplace.json`
- 다만 플러그인/경로 호환성 문제를 줄이려면 WSL2 실행이 더 안전하다.

## AGENTS.md Note

Codex의 기본 가이드 파일은 `CLAUDE.md`가 아니라 `AGENTS.md`입니다.
팀 공통 규율은 `AGENTS.md`에 두고, 코어 규율은 영어로 작성하는 것을 권장합니다.

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
