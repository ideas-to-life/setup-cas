#!/usr/bin/env bash
# Continuous Architecture System (CAS) - Standalone Tool Installation Helper
# Supports unauthenticated installation via:
#   curl -fsSL https://raw.githubusercontent.com/ideas-to-life/setup-cas/main/install-cas.sh | bash
# Provisions or upgrades the isolated `cas` CLI tool into ~/.local/bin without polluting project virtualenvs.

set -euo pipefail

FORCE=false
CHECK_ONLY=false
DIST_REPO="${CAS_DIST_REPO:-ideas-to-life/setup-cas}"
REPO_URL="${CAS_REPO_URL:-https://github.com/ideas-to-life/ideas-to-life-cas.git}"
VERSION="${CAS_VERSION:-main}"
WHEEL_URL="${CAS_WHEEL_URL:-}"

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=true
      ;;
    --check)
      CHECK_ONLY=true
      ;;
    --help|-h)
      echo "Usage: $0 [--force] [--check] [--help]"
      echo "  --force   Force reinstallation/upgrade to latest release"
      echo "  --check   Verify CAS installation and PATH availability without modifying state"
      echo "  --help    Show this message"
      exit 0
      ;;
    *)
      echo "[CAS][ERROR] Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

# 1. Prerequisite verification: uv
if ! command -v uv >/dev/null 2>&1; then
  echo "[CAS][INFO] 'uv' not found. Bootstrapping uv standalone package manager..."
  if command -v curl >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  else
    echo "[CAS][ERROR] 'curl' is required to auto-bootstrap uv. Please install uv manually: https://docs.astral.sh/uv/" >&2
    exit 1
  fi
fi

# Ensure PATH includes uv location
if ! command -v uv >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "[CAS][ERROR] uv installation completed but 'uv' is still not found in PATH." >&2
  exit 1
fi

UV_BIN_DIR="$(uv tool dir --bin 2>/dev/null || echo "$HOME/.local/bin")"

# 2. Check mode
if [ "$CHECK_ONLY" = true ]; then
  if command -v cas >/dev/null 2>&1; then
    echo "[CAS][OK] CAS CLI is available in PATH: $(which cas)"
    cas --version 2>/dev/null || cas --help >/dev/null
    exit 0
  elif [ -x "$UV_BIN_DIR/cas" ]; then
    echo "[CAS][WARN] CAS CLI exists at '$UV_BIN_DIR/cas' but '$UV_BIN_DIR' is not in PATH."
    exit 1
  else
    echo "[CAS][INFO] CAS CLI is not installed."
    exit 1
  fi
fi

# 3. Tool installation via uv tool install (Public Release Wheel -> Git fallback)
echo "[CAS][INFO] Installing/upgrading CAS CLI via uv tool install..."
if [ -z "$WHEEL_URL" ]; then
  if [ -z "$VERSION" ] || [ "$VERSION" = "main" ] || [ "$VERSION" = "latest" ]; then
    LATEST_WHEEL="$(curl -fsSL "https://raw.githubusercontent.com/${DIST_REPO}/main/LATEST_WHEEL" 2>/dev/null || echo "")"
    WHEEL_NAME="${LATEST_WHEEL:-cas_runner-0.1.1-py3-none-any.whl}"
    WHEEL_URL="https://github.com/${DIST_REPO}/releases/latest/download/${WHEEL_NAME}"
  else
    CLEAN_VER="${VERSION#v}"
    WHEEL_URL="https://github.com/${DIST_REPO}/releases/download/${VERSION}/cas_runner-${CLEAN_VER}-py3-none-any.whl"
  fi
fi

if ! uv tool install --force "$WHEEL_URL"; then
  echo "[CAS][WARN] Direct wheel installation failed ($WHEEL_URL); attempting git source fallback..."
  INSTALL_SPEC="git+${REPO_URL}"
  if [ -n "$VERSION" ] && [ "$VERSION" != "main" ]; then
    INSTALL_SPEC="${INSTALL_SPEC}@${VERSION}"
  fi
  uv tool install --force "$INSTALL_SPEC"
fi

# 4. PATH Verification & Guidance
export PATH="$UV_BIN_DIR:$PATH"

if ! command -v cas >/dev/null 2>&1; then
  echo "[CAS][WARN] '$UV_BIN_DIR' is not in your system PATH."
  echo "[CAS][HINT] Add the following line to your ~/.zshrc or ~/.bashrc profile:"
  echo "            export PATH=\"$UV_BIN_DIR:\$PATH\""
fi

# 5. Final Smoke Test
if [ -x "$UV_BIN_DIR/cas" ]; then
  echo "[CAS][SUCCESS] CAS CLI is installed and ready at: $UV_BIN_DIR/cas"
  "$UV_BIN_DIR/cas" --help >/dev/null
  exit 0
else
  echo "[CAS][ERROR] Installation succeeded but binary not found at $UV_BIN_DIR/cas" >&2
  exit 1
fi
