# sonmat-codex (Archived)

> **This repository has been archived.** The Codex-specific port has been consolidated into the main sonmat repository.

## Where to go

**[jun0-ds/sonmat](https://github.com/jun0-ds/sonmat)** — the single source of truth for all CLI platforms.

## Why archived?

sonmat's core files (discipline, skills, agents) are plain markdown and work identically across Claude Code, Codex CLI, and Gemini CLI. Maintaining separate repos per CLI created sync overhead with no real benefit. Now sonmat is one repo with a [multi-CLI guide](https://github.com/jun0-ds/sonmat#other-ai-clis) for non-Claude setups.

## Quick migration

```bash
# Remove old sonmat-codex
rm -rf ~/.codex/plugins/sonmat

# Copy from main sonmat
git clone https://github.com/jun0-ds/sonmat.git /tmp/sonmat
cp -r /tmp/sonmat/discipline ~/.codex/
cp -r /tmp/sonmat/skills ~/.codex/
rm -rf /tmp/sonmat
```

See the [sonmat README](https://github.com/jun0-ds/sonmat#other-ai-clis) for full setup instructions.
