#!/usr/bin/env bash
set -euo pipefail

# install.sh — Install SARA skills into the current git project
#
# Run from inside your project directory:
#   curl -fsSL https://raw.githubusercontent.com/cgb-76/SARA/main/install.sh | bash
#
# With flags:
#   curl -fsSL https://raw.githubusercontent.com/cgb-76/SARA/main/install.sh | bash -s -- --backup
#
# Options:
#   --backup   Preserve existing SKILL.md as SKILL.md.bak before overwriting
#   --force    Override downgrade protection (allow installing older versions)
#   --branch   Source branch or tag (default: main)
#   --help     Show this help message and exit

BACKUP=false
FORCE=false
BRANCH="main"
REPO="cgb-76/SARA"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup) BACKUP=true; shift ;;
    --force)  FORCE=true;  shift ;;
    --branch)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --branch requires a value." >&2; exit 1
      fi
      BRANCH="$2"; shift 2 ;;
    --help)
      echo "Usage: curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- [OPTIONS]"
      echo ""
      echo "Install SARA skills into the current git project."
      echo ""
      echo "Options:"
      echo "  --backup         Preserve existing SKILL.md as SKILL.md.bak before overwriting"
      echo "  --force          Override downgrade protection (allow installing older versions)"
      echo "  --branch <ref>   Source branch or tag (default: main)"
      echo "  --help           Show this help message and exit"
      exit 0 ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1 ;;
  esac
done

TARGET_DIR="$PWD"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Ensure a git repository exists — initialise one if needed (D-03)
if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo "No git repository found — running git init..."
  git -C "$TARGET_DIR" init
fi

# Known skills — fixed set for this release
SKILLS=(
  sara-init
  sara-ingest
  sara-discuss
  sara-extract
  sara-update
  sara-add-stakeholder
  sara-minutes
  sara-agenda
  sara-lint
)

TARGET_SKILLS_DIR="$TARGET_DIR/.claude/skills"
mkdir -p "$TARGET_SKILLS_DIR"

INSTALLED=()

for skill_name in "${SKILLS[@]}"; do
  src_url="${BASE_URL}/.claude/skills/${skill_name}/SKILL.md"
  dest_skill_dir="${TARGET_SKILLS_DIR}/${skill_name}"
  dest_file="${dest_skill_dir}/SKILL.md"

  # Download to a temp file
  tmp_file="$(mktemp)"
  if ! curl -fsSL "${src_url}" -o "${tmp_file}" 2>/dev/null; then
    echo "Warning: could not download ${skill_name} from ${src_url} — skipping." >&2
    rm -f "${tmp_file}"
    continue
  fi

  # Extract source version
  src_ver="$(grep "^version:" "${tmp_file}" 2>/dev/null | awk '{print $2}' || true)"
  [[ -z "$src_ver" ]] && src_ver="0.0.0"

  # Downgrade check (D-09)
  if [[ -f "$dest_file" ]] && [[ "$FORCE" != "true" ]]; then
    inst_ver="$(grep "^version:" "${dest_file}" 2>/dev/null | awk '{print $2}' || true)"
    [[ -z "$inst_ver" ]] && inst_ver="0.0.0"

    older="$(printf '%s\n%s\n' "${src_ver}" "${inst_ver}" | sort -V | head -1)"
    if [[ "$older" = "$src_ver" ]] && [[ "$src_ver" != "$inst_ver" ]]; then
      echo "Warning: source version (${src_ver}) is older than installed version (${inst_ver}) for ${skill_name} — skipping. Use --force to override." >&2
      rm -f "${tmp_file}"
      continue
    fi
  fi

  # Backup existing SKILL.md (D-05)
  if [[ "$BACKUP" = "true" ]] && [[ -f "$dest_file" ]]; then
    cp "${dest_file}" "${dest_file}.bak"
  fi

  mkdir -p "${dest_skill_dir}"
  mv "${tmp_file}" "${dest_file}"

  INSTALLED+=("${skill_name}")
done

# Known agent files — fixed set for this release
AGENTS=(
  sara-requirement-extractor
  sara-decision-extractor
  sara-action-extractor
  sara-risk-extractor
  sara-artifact-sorter
)

TARGET_AGENTS_DIR="$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_AGENTS_DIR"

for agent_name in "${AGENTS[@]}"; do
  src_url="${BASE_URL}/.claude/agents/${agent_name}.md"
  dest_file="${TARGET_AGENTS_DIR}/${agent_name}.md"

  tmp_file="$(mktemp)"
  if ! curl -fsSL "${src_url}" -o "${tmp_file}" 2>/dev/null; then
    echo "Warning: could not download ${agent_name} from ${src_url} — skipping." >&2
    rm -f "${tmp_file}"
    continue
  fi

  if [[ "$BACKUP" = "true" ]] && [[ -f "$dest_file" ]]; then
    cp "${dest_file}" "${dest_file}.bak"
  fi

  mv "${tmp_file}" "${dest_file}"
  INSTALLED+=("${agent_name}")
done

# Post-install output (D-07)
if [[ ${#INSTALLED[@]} -eq 0 ]]; then
  echo "No skills were installed."
  exit 0
fi

echo "Installed skills:"
for name in "${INSTALLED[@]}"; do
  echo "  ${name}"
done

echo ""
echo "Next: open Claude Code in this directory and run /sara-init"
