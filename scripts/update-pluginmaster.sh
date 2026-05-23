#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_RELEASE_REPO_URL="https://github.com/fenk19/DalamudPluginRepo"

VERSION=""
TAG=""
PLUGINMASTER="${PLUGINMASTER:-${REPO_ROOT}/pluginmaster.json}"
REPO_URL="${REPO_URL:-}"
RSR_REPO_URL="${RSR_REPO_URL:-}"
BMR_REPO_URL="${BMR_REPO_URL:-}"
LAST_UPDATE="${LAST_UPDATE:-}"
ONLY="all"
DRY_RUN=0
VERIFY_LINKS=0

RSR_ASSET=""
BMR_ASSET=""
RSR_SOURCE_ASSET=""
RSR_CHANGELOG=""
BMR_CHANGELOG=""

usage() {
  cat <<'USAGE'
Usage: scripts/update-pluginmaster.sh VERSION [options]
       scripts/update-pluginmaster.sh --version VERSION [options]

Updates pluginmaster.json for the integration release version.

By default it updates both plugin entries:
  - RotationSolver -> RotationSolver-BMR-VERSION.zip
  - BossModReborn  -> BossModReborn-RSR-VERSION.zip

Options:
  --version VERSION         Assembly/release version, for example 99.0.0.2.
  --tag TAG                 GitHub release tag. Default: VERSION.
  --pluginmaster PATH       pluginmaster.json path. Default: ./pluginmaster.json
  --repo-url URL            Public release repository URL for both plugin assets.
                            Default: https://github.com/fenk19/DalamudPluginRepo
  --rsr-repo-url URL        RotationSolver-BMR release repository URL.
                            Default: https://github.com/fenk19/DalamudPluginRepo
  --bmr-repo-url URL        BossModReborn-RSR release repository URL.
                            Default: https://github.com/fenk19/DalamudPluginRepo
  --last-update EPOCH       LastUpdate unix timestamp. Default: current time.
  --only all|rsr|bmr        Limit updated entries. Default: all.
  --rsr-asset NAME          RSR release asset name.
                            Default: RotationSolver-BMR-VERSION.zip
  --bmr-asset NAME          BMR release asset name.
                            Default: BossModReborn-RSR-VERSION.zip
  --rsr-source-asset NAME   RSR corresponding-source asset name.
                            Default: RotationSolverReborn-BMR-VERSION-source.zip
  --rsr-changelog TEXT      Changelog for the RSR entry.
  --bmr-changelog TEXT      Changelog for the BMR entry.
  --dry-run                 Print updated JSON to stdout without writing.
  --verify-links            Check computed download URLs with curl before writing.
  -h, --help                Show this help.

Environment:
  PLUGINMASTER, REPO_URL, RSR_REPO_URL, BMR_REPO_URL, LAST_UPDATE may be used
  instead of options.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:?missing version}"
      shift 2
      ;;
    --tag)
      TAG="${2:?missing tag}"
      shift 2
      ;;
    --pluginmaster)
      PLUGINMASTER="${2:?missing pluginmaster path}"
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:?missing repo url}"
      shift 2
      ;;
    --rsr-repo-url)
      RSR_REPO_URL="${2:?missing repo url}"
      shift 2
      ;;
    --bmr-repo-url)
      BMR_REPO_URL="${2:?missing repo url}"
      shift 2
      ;;
    --last-update)
      LAST_UPDATE="${2:?missing timestamp}"
      shift 2
      ;;
    --only)
      ONLY="${2:?missing selection}"
      shift 2
      ;;
    --rsr-asset)
      RSR_ASSET="${2:?missing asset name}"
      shift 2
      ;;
    --bmr-asset)
      BMR_ASSET="${2:?missing asset name}"
      shift 2
      ;;
    --rsr-source-asset)
      RSR_SOURCE_ASSET="${2:?missing asset name}"
      shift 2
      ;;
    --rsr-changelog)
      RSR_CHANGELOG="${2:?missing changelog}"
      shift 2
      ;;
    --bmr-changelog)
      BMR_CHANGELOG="${2:?missing changelog}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verify-links)
      VERIFY_LINKS=1
      shift
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
      if [[ -n "${VERSION}" ]]; then
        echo "Unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      VERSION="$1"
      shift
      ;;
  esac
done

[[ -n "${VERSION}" ]] || die "VERSION is required"
[[ "${VERSION}" =~ ^[0-9]+(\.[0-9]+){0,3}$ ]] || die "VERSION must be numeric AssemblyVersion format, for example 99.0.0.2"
case "${ONLY}" in
  all|rsr|bmr) ;;
  *) die "--only must be one of: all, rsr, bmr" ;;
esac

command -v python3 >/dev/null 2>&1 || die "python3 is required"
[[ -f "${PLUGINMASTER}" ]] || die "pluginmaster not found: ${PLUGINMASTER}"

TAG="${TAG:-${VERSION}}"
LAST_UPDATE="${LAST_UPDATE:-$(date +%s)}"
[[ "${LAST_UPDATE}" =~ ^[0-9]+$ ]] || die "--last-update must be a unix timestamp"

if [[ -n "${REPO_URL}" ]]; then
  RSR_REPO_URL="${RSR_REPO_URL:-${REPO_URL}}"
  BMR_REPO_URL="${BMR_REPO_URL:-${REPO_URL}}"
fi
RSR_REPO_URL="${RSR_REPO_URL:-${DEFAULT_RELEASE_REPO_URL}}"
BMR_REPO_URL="${BMR_REPO_URL:-${DEFAULT_RELEASE_REPO_URL}}"
RSR_REPO_URL="${RSR_REPO_URL%/}"
BMR_REPO_URL="${BMR_REPO_URL%/}"
rsr_release_base="${RSR_REPO_URL}/releases/download/${TAG}"
bmr_release_base="${BMR_REPO_URL}/releases/download/${TAG}"

RSR_ASSET="${RSR_ASSET:-RotationSolver-BMR-${VERSION}.zip}"
BMR_ASSET="${BMR_ASSET:-BossModReborn-RSR-${VERSION}.zip}"
RSR_SOURCE_ASSET="${RSR_SOURCE_ASSET:-RotationSolverReborn-BMR-${VERSION}-source.zip}"

rsr_download="${rsr_release_base}/${RSR_ASSET}"
bmr_download="${bmr_release_base}/${BMR_ASSET}"
rsr_source_download="${rsr_release_base}/${RSR_SOURCE_ASSET}"

RSR_CHANGELOG="${RSR_CHANGELOG:-Integration build ${VERSION}. Corresponding source: ${rsr_source_download}}"
BMR_CHANGELOG="${BMR_CHANGELOG:-Integration build ${VERSION}. BSD-3-Clause license notice is included in the plugin zip.}"

if (( VERIFY_LINKS )); then
  command -v curl >/dev/null 2>&1 || die "curl is required for --verify-links"
  if [[ "${ONLY}" == "all" || "${ONLY}" == "rsr" ]]; then
    curl -fsIL -o /dev/null "${rsr_download}" || die "RSR asset is not reachable: ${rsr_download}"
    curl -fsIL -o /dev/null "${rsr_source_download}" || die "RSR source asset is not reachable: ${rsr_source_download}"
  fi
  if [[ "${ONLY}" == "all" || "${ONLY}" == "bmr" ]]; then
    curl -fsIL -o /dev/null "${bmr_download}" || die "BMR asset is not reachable: ${bmr_download}"
  fi
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/pluginmaster.XXXXXX")"
cleanup() {
  rm -f "${tmp_file}"
}
trap cleanup EXIT

export VERSION LAST_UPDATE ONLY
export RSR_DOWNLOAD="${rsr_download}"
export BMR_DOWNLOAD="${bmr_download}"
export RSR_CHANGELOG BMR_CHANGELOG

python3 - "${PLUGINMASTER}" "${tmp_file}" <<'PY'
import json
import os
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])

version = os.environ["VERSION"]
last_update = int(os.environ["LAST_UPDATE"])
only = os.environ["ONLY"]

with source.open("r", encoding="utf-8-sig") as f:
    data = json.load(f)

if not isinstance(data, list):
    raise SystemExit("pluginmaster root must be a JSON array")

seen = set()
for entry in data:
    if not isinstance(entry, dict):
        continue
    internal_name = entry.get("InternalName")
    if internal_name == "RotationSolver" and only in ("all", "rsr"):
        entry["DownloadLinkInstall"] = os.environ["RSR_DOWNLOAD"]
        entry["DownloadLinkUpdate"] = os.environ["RSR_DOWNLOAD"]
        entry["AssemblyVersion"] = version
        entry["Changelog"] = os.environ["RSR_CHANGELOG"]
        entry["LastUpdate"] = last_update
        seen.add("rsr")
    elif internal_name == "BossModReborn" and only in ("all", "bmr"):
        entry["DownloadLinkInstall"] = os.environ["BMR_DOWNLOAD"]
        entry["DownloadLinkUpdate"] = os.environ["BMR_DOWNLOAD"]
        entry["AssemblyVersion"] = version
        entry["Changelog"] = os.environ["BMR_CHANGELOG"]
        entry["LastUpdate"] = last_update
        seen.add("bmr")

missing = []
if only in ("all", "rsr") and "rsr" not in seen:
    missing.append("RotationSolver")
if only in ("all", "bmr") and "bmr" not in seen:
    missing.append("BossModReborn")
if missing:
    raise SystemExit(f"missing plugin entry: {', '.join(missing)}")

with target.open("w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

if (( DRY_RUN )); then
  cat "${tmp_file}"
else
  mv "${tmp_file}" "${PLUGINMASTER}"
  trap - EXIT
  echo "Updated ${PLUGINMASTER}"
  echo "Version: ${VERSION}"
  if [[ "${ONLY}" == "all" || "${ONLY}" == "rsr" ]]; then
    echo "RSR: ${rsr_download}"
    echo "RSR source: ${rsr_source_download}"
  fi
  if [[ "${ONLY}" == "all" || "${ONLY}" == "bmr" ]]; then
    echo "BMR: ${bmr_download}"
  fi
fi
