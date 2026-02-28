#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release.sh <version> [--dry-run]

Examples:
  ./scripts/release.sh 0.1.1
  ./scripts/release.sh 0.2.0 --dry-run
EOF
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

VERSION="$1"
DRY_RUN="${2:-}"

case "$DRY_RUN" in
  ""|--dry-run) ;;
  *)
    echo "error: unknown flag '$DRY_RUN'"
    usage
    exit 1
    ;;
esac

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "error: version must match X.Y.Z (got '$VERSION')"
  exit 1
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

TAG="v$VERSION"

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "Releasing checkmate.nvim $VERSION"
  if [ -n "$(git status --porcelain)" ]; then
    echo "[dry-run] Note: working tree is dirty (real release would fail)"
  fi
  if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "[dry-run] Note: tag '$TAG' already exists (real release would fail)"
  fi
  echo "[dry-run] Would write VERSION"
  echo "[dry-run] Would write lua/checkmate/version.lua"
  echo "[dry-run] Would run ./scripts/test.sh"
  echo "[dry-run] Would git add VERSION lua/checkmate/version.lua"
  echo "[dry-run] Would git commit -m \"chore(release): v$VERSION\""
  echo "[dry-run] Would git tag v$VERSION"
  echo "[dry-run] Done"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: git working tree is not clean"
  echo "commit or stash changes first"
  exit 1
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "error: tag '$TAG' already exists"
  exit 1
fi

echo "Releasing checkmate.nvim $VERSION"

printf '%s\n' "$VERSION" > VERSION

cat > lua/checkmate/version.lua <<EOF
local M = {}

M.current = '$VERSION'

return M
EOF

./scripts/test.sh

git add VERSION lua/checkmate/version.lua
git commit -m "chore(release): v$VERSION"
git tag "$TAG"

echo "Release commit and tag created."
echo "Next:"
echo "  git push origin main"
echo "  git push origin $TAG"
