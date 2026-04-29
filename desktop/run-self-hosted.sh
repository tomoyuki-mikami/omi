#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

load_env_file() {
  local file="$1"
  if [ -f "$file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$file"
    set +a
  fi
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_safe_url() {
  local name="$1"
  local value="${!name:-}"

  if [ -z "$value" ]; then
    fail "$name is required for self-hosted desktop launch"
  fi

  case "$value" in
    *api.omi.me*|*api.omiapi.com*|*desktop-backend-hhibjajaja-uc.a.run.app*|*desktop-backend-dt5lrfkkoa-uc.a.run.app*)
      fail "$name points to an Omi-managed backend: $value"
      ;;
  esac
}

require_local_google_service_plist() {
  OMI_GOOGLE_SERVICE_INFO_PLIST="${OMI_GOOGLE_SERVICE_INFO_PLIST:-self-hosted/GoogleService-Info.plist}"
  export OMI_GOOGLE_SERVICE_INFO_PLIST

  if [ ! -f "$OMI_GOOGLE_SERVICE_INFO_PLIST" ]; then
    fail "OMI_GOOGLE_SERVICE_INFO_PLIST must point to your Firebase GoogleService-Info.plist: $OMI_GOOGLE_SERVICE_INFO_PLIST"
  fi

  local project_id=""
  project_id="$(/usr/libexec/PlistBuddy -c "Print :PROJECT_ID" "$OMI_GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || true)"

  if [ -z "$project_id" ]; then
    fail "OMI_GOOGLE_SERVICE_INFO_PLIST does not contain PROJECT_ID: $OMI_GOOGLE_SERVICE_INFO_PLIST"
  fi

  case "$project_id" in
    based-hardware|based-hardware-dev)
      fail "OMI_GOOGLE_SERVICE_INFO_PLIST points to an Omi-managed Firebase project: $project_id"
      ;;
  esac
}

load_env_file "self-hosted.env"
load_env_file "Backend-Rust/.env"
load_env_file ".env.app"
load_env_file ".env.app.dev"

require_safe_url "OMI_PYTHON_API_URL"
require_safe_url "OMI_DESKTOP_API_URL"
require_local_google_service_plist

# Self-hosted local development should use this repo's Rust desktop backend by
# default. Set OMI_SKIP_BACKEND=1 only when pointing at a backend you operate
# somewhere else.
export OMI_SKIP_BACKEND="${OMI_SKIP_BACKEND:-0}"
export OMI_SKIP_TUNNEL="${OMI_SKIP_TUNNEL:-1}"
export OMI_API_BASE_URL="${OMI_API_BASE_URL:-${OMI_DESKTOP_API_URL%/}/v2}"

echo "Self-hosted preflight passed:"
echo "  OMI_PYTHON_API_URL=$OMI_PYTHON_API_URL"
echo "  OMI_DESKTOP_API_URL=$OMI_DESKTOP_API_URL"
echo "  OMI_API_BASE_URL=$OMI_API_BASE_URL"
echo "  OMI_GOOGLE_SERVICE_INFO_PLIST=$OMI_GOOGLE_SERVICE_INFO_PLIST"
echo

if [ "${OMI_SELF_HOSTED_PREFLIGHT_ONLY:-}" = "1" ]; then
  exit 0
fi

exec bash ./run.sh "$@"
