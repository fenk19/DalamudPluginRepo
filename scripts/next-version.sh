#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

CURRENT=""
PLUGINMASTER="${PLUGINMASTER:-${REPO_ROOT}/pluginmaster.json}"

usage() {
  cat <<'USAGE'
Usage: scripts/next-version.sh CHANGE_KIND [options]

Prints the next fixed integration version for the 99.X.Y.Z release series.

Change kinds:
  upstream-only  Official upstream sync only; increments Z.
  custom         Custom integration behavior change; increments Y and resets Z.
  conflict       Upstream sync conflict was resolved; increments Y and resets Z.

Options:
  --current VERSION       Current version. Default: read from pluginmaster.json.
  --pluginmaster PATH     pluginmaster.json path used when --current is omitted.
  -h, --help              Show this help.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

CHANGE_KIND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --current)
      CURRENT="${2:?missing version}"
      shift 2
      ;;
    --pluginmaster)
      PLUGINMASTER="${2:?missing pluginmaster path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "${CHANGE_KIND}" ]]; then
        echo "Unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      CHANGE_KIND="$1"
      shift
      ;;
  esac
done

[[ -n "${CHANGE_KIND}" ]] || die "CHANGE_KIND is required"
case "${CHANGE_KIND}" in
  upstream-only|custom|conflict) ;;
  *) die "CHANGE_KIND must be one of: upstream-only, custom, conflict" ;;
esac

if [[ -z "${CURRENT}" ]]; then
  command -v python3 >/dev/null 2>&1 || die "python3 is required"
  [[ -f "${PLUGINMASTER}" ]] || die "pluginmaster not found: ${PLUGINMASTER}"
  CURRENT="$(
    python3 - "${PLUGINMASTER}" <<'PY'
import json
import sys
from pathlib import Path

with Path(sys.argv[1]).open("r", encoding="utf-8-sig") as f:
    data = json.load(f)

versions = {
    entry.get("AssemblyVersion")
    for entry in data
    if isinstance(entry, dict) and entry.get("InternalName") in {"RotationSolver", "BossModReborn"}
}
versions.discard(None)
if len(versions) != 1:
    raise SystemExit(f"expected one shared integration version, got: {sorted(versions)}")
print(next(iter(versions)))
PY
  )"
fi

[[ "${CURRENT}" =~ ^99\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || die "current version must use 99.X.Y.Z format: ${CURRENT}"

x="${BASH_REMATCH[1]}"
y="${BASH_REMATCH[2]}"
z="${BASH_REMATCH[3]}"

case "${CHANGE_KIND}" in
  upstream-only)
    z=$((z + 1))
    ;;
  custom|conflict)
    y=$((y + 1))
    z=0
    ;;
esac

printf '99.%s.%s.%s\n' "${x}" "${y}" "${z}"
