#!/usr/bin/env bash
set -euo pipefail

# sonmat-codex bootstrap
# - prepares Codex config defaults (safe, non-destructive where possible)
# - upserts sonmat marketplace entry
# - installs fallback skills directly into ~/.codex/skills
# - optionally verifies visibility via codex exec

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_CONFIG="${CODEX_HOME}/config.toml"
AGENTS_DIR="${HOME}/.agents/plugins"
MARKETPLACE_JSON="${AGENTS_DIR}/marketplace.json"
CODEX_SKILLS_DIR="${CODEX_HOME}/skills"

SONMAT_REPO_DEFAULT="jun0-ds/sonmat-codex"
SONMAT_REPO="${SONMAT_REPO:-$SONMAT_REPO_DEFAULT}"

say() { printf "[sonmat-bootstrap] %s\n" "$*"; }
warn() { printf "[sonmat-bootstrap][warn] %s\n" "$*" >&2; }

ensure_dirs() {
  mkdir -p "${CODEX_HOME}" "${AGENTS_DIR}" "${CODEX_SKILLS_DIR}"
}

backup_if_exists() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cp "$path" "${path}.bak.${TIMESTAMP}"
    say "Backed up: ${path}.bak.${TIMESTAMP}"
  fi
}

ensure_codex_config() {
  if [[ ! -f "${CODEX_CONFIG}" ]]; then
    cat > "${CODEX_CONFIG}" <<'EOF'
approval_policy = "never"
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = true
EOF
    say "Created ${CODEX_CONFIG}"
    return
  fi

  # Non-destructive updates: only add missing keys/tables.
  # Existing user values are preserved.
  if ! grep -qE '^[[:space:]]*approval_policy[[:space:]]*=' "${CODEX_CONFIG}"; then
    printf '\napproval_policy = "never"\n' >> "${CODEX_CONFIG}"
    say "Added approval_policy to ${CODEX_CONFIG}"
  fi

  if ! grep -qE '^[[:space:]]*sandbox_mode[[:space:]]*=' "${CODEX_CONFIG}"; then
    printf 'sandbox_mode = "workspace-write"\n' >> "${CODEX_CONFIG}"
    say "Added sandbox_mode to ${CODEX_CONFIG}"
  fi

  if ! grep -qE '^[[:space:]]*\[sandbox_workspace_write\][[:space:]]*$' "${CODEX_CONFIG}"; then
    cat >> "${CODEX_CONFIG}" <<'EOF'

[sandbox_workspace_write]
network_access = true
EOF
    say "Added [sandbox_workspace_write] block to ${CODEX_CONFIG}"
    return
  fi

  if ! awk '
    BEGIN { in_block=0; has_key=0 }
    /^\[sandbox_workspace_write\][[:space:]]*$/ { in_block=1; next }
    /^\[.*\][[:space:]]*$/ { if (in_block) in_block=0 }
    in_block && /^[[:space:]]*network_access[[:space:]]*=/ { has_key=1 }
    END { exit(has_key ? 0 : 1) }
  ' "${CODEX_CONFIG}"; then
    local tmp
    tmp="$(mktemp)"
    awk '
      BEGIN { in_block=0; injected=0 }
      {
        print $0
        if ($0 ~ /^\[sandbox_workspace_write\][[:space:]]*$/) {
          in_block=1
          next
        }
        if (in_block && $0 ~ /^\[.*\][[:space:]]*$/ && !injected) {
          print "network_access = true"
          injected=1
          in_block=0
        }
      }
      END {
        if (in_block && !injected) print "network_access = true"
      }
    ' "${CODEX_CONFIG}" > "${tmp}"
    mv "${tmp}" "${CODEX_CONFIG}"
    say "Added network_access=true in [sandbox_workspace_write]"
  fi
}

upsert_marketplace_entry() {
  backup_if_exists "${MARKETPLACE_JSON}"

  python3 - <<'PY' "${MARKETPLACE_JSON}" "${SONMAT_REPO}"
import json
import os
import sys

path = sys.argv[1]
repo = sys.argv[2]

default_root = {
    "name": "jun0-marketplace",
    "interface": {"displayName": "jun0 plugins"},
    "plugins": [],
}

entry = {
    "name": "sonmat",
    "source": {"source": "github", "repo": repo},
    "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
    "category": "Productivity",
}

root = None
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            root = json.load(f)
    except Exception:
        root = None

if not isinstance(root, dict):
    root = default_root

if not isinstance(root.get("plugins"), list):
    root["plugins"] = []

plugins = root["plugins"]
idx = next((i for i, p in enumerate(plugins) if isinstance(p, dict) and p.get("name") == "sonmat"), None)
if idx is None:
    plugins.append(entry)
else:
    merged = dict(plugins[idx])
    merged.update(entry)
    plugins[idx] = merged

if "name" not in root:
    root["name"] = default_root["name"]
if not isinstance(root.get("interface"), dict):
    root["interface"] = default_root["interface"]
if "displayName" not in root["interface"]:
    root["interface"]["displayName"] = default_root["interface"]["displayName"]

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(root, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

  say "Updated ${MARKETPLACE_JSON}"
}

install_fallback_skills() {
  local missing=0
  for name in loop guard plan benchmark; do
    if [[ ! -d "${REPO_ROOT}/skills/${name}" ]]; then
      warn "Missing ${REPO_ROOT}/skills/${name}"
      missing=1
    fi
  done
  if [[ "${missing}" -eq 1 ]]; then
    warn "Skipping fallback skill install due to missing source directories."
    return
  fi

  for name in loop guard plan benchmark; do
    rm -rf "${CODEX_SKILLS_DIR:?}/${name}"
    cp -R "${REPO_ROOT}/skills/${name}" "${CODEX_SKILLS_DIR}/"
  done
  say "Installed fallback skills into ${CODEX_SKILLS_DIR}"
}

verify_installation() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex command not found; skipping verification."
    return
  fi

  if codex exec --skip-git-repo-check -C "${PWD}" \
      "List installed skills named loop, guard, plan, benchmark." >/tmp/sonmat-bootstrap-verify.log 2>/tmp/sonmat-bootstrap-verify.err; then
    say "Verification command completed."
    sed -n '1,80p' /tmp/sonmat-bootstrap-verify.log || true
  else
    warn "Verification command failed. See /tmp/sonmat-bootstrap-verify.err"
  fi
}

main() {
  say "Starting bootstrap"
  ensure_dirs
  ensure_codex_config
  upsert_marketplace_entry
  install_fallback_skills
  verify_installation
  say "Done"
}

main "$@"
