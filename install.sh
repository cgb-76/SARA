#!/usr/bin/env bash
set -euo pipefail

# install.sh — Install SARA skills into a target git project
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --target <dir>   Target project directory (default: current working directory)
#   --backup         Preserve existing SKILL.md as SKILL.md.bak before overwriting
#   --force          Override downgrade protection (allow installing older versions)
#   --help           Show this help message and exit

BACKUP=false
FORCE=false
TARGET_DIR="$PWD"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup)
      BACKUP=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --target)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --target requires a directory argument." >&2
        exit 1
      fi
      TARGET_DIR="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $(basename "$0") [--target <dir>] [--backup] [--force] [--help]"
      echo ""
      echo "Install SARA skills into a target git project."
      echo ""
      echo "Options:"
      echo "  --target <dir>   Target project directory (default: current working directory)"
      echo "  --backup         Preserve existing SKILL.md as SKILL.md.bak before overwriting"
      echo "  --force          Override downgrade protection (allow installing older versions)"
      echo "  --help           Show this help message and exit"
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Usage: $(basename "$0") [--target <dir>] [--backup] [--force] [--help]" >&2
      exit 1
      ;;
  esac
done

# Guard: target directory must be a git repository (D-03)
if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo "Error: install.sh must be run inside a git repository. SARA pipeline commands depend on git commits." >&2
  exit 1
fi

# Locate source skills (relative to this script's location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS_DIR="$SCRIPT_DIR/.claude/skills"

# Collect sara-* directories dynamically (D-04)
mapfile -t SKILL_DIRS < <(find "$SOURCE_SKILLS_DIR" -maxdepth 1 -type d -name 'sara-*' | sort)

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
  echo "Error: no sara-* skill directories found in $SOURCE_SKILLS_DIR" >&2
  exit 1
fi

# Create target skills directory
TARGET_SKILLS_DIR="$TARGET_DIR/.claude/skills"
mkdir -p "$TARGET_SKILLS_DIR"

INSTALLED=()

# Per-skill install loop
for src_skill_dir in "${SKILL_DIRS[@]}"; do
  skill_name="$(basename "$src_skill_dir")"
  dest_skill_dir="$TARGET_SKILLS_DIR/$skill_name"

  # Extract source version
  src_ver="$(grep "^version:" "$src_skill_dir/SKILL.md" 2>/dev/null | awk '{print $2}' || true)"
  if [[ -z "$src_ver" ]]; then
    src_ver="0.0.0"
  fi

  # Downgrade check (D-09)
  if [[ -f "$dest_skill_dir/SKILL.md" ]] && [[ "$FORCE" != "true" ]]; then
    inst_ver="$(grep "^version:" "$dest_skill_dir/SKILL.md" 2>/dev/null | awk '{print $2}' || true)"
    if [[ -z "$inst_ver" ]]; then
      inst_ver="0.0.0"
    fi

    older="$(printf '%s\n%s\n' "$src_ver" "$inst_ver" | sort -V | head -1)"
    if [[ "$older" = "$src_ver" ]] && [[ "$src_ver" != "$inst_ver" ]]; then
      echo "Warning: source version ($src_ver) is older than installed version ($inst_ver) for $skill_name — skipping. Use --force to override." >&2
      continue
    fi
  fi

  # Backup existing SKILL.md (D-05)
  if [[ "$BACKUP" = "true" ]] && [[ -f "$dest_skill_dir/SKILL.md" ]]; then
    cp "$dest_skill_dir/SKILL.md" "$dest_skill_dir/SKILL.md.bak"
  fi

  # Copy skill directory contents
  mkdir -p "$dest_skill_dir"
  cp -r "$src_skill_dir/." "$dest_skill_dir/"

  INSTALLED+=("$skill_name")
done

# Post-install output (D-07)
if [[ ${#INSTALLED[@]} -eq 0 ]]; then
  echo "No skills were installed."
  exit 0
fi

echo "Installed skills:"
for name in "${INSTALLED[@]}"; do
  echo "$name"
done

echo ""
echo "Next: open Claude Code in this directory and run /sara-init"
