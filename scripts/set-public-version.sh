#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

VERSION=""
ONLY="all"
DRY_RUN=0
VERIFY_LINKS=0
COMMIT=0
PUSH=0
LAST_UPDATE=""
RSR_CHANGELOG=""
BMR_CHANGELOG=""

usage() {
  cat <<'USAGE'
Usage: scripts/set-public-version.sh VERSION [options]
       scripts/set-public-version.sh --version VERSION [options]

Sets the public Dalamud repository metadata to a fixed released version. This
can move the published metadata forward or backward, as long as the referenced
versioned GitHub Release assets already exist.

Note: Dalamud's automatic update detection only offers updates to versions
greater than the installed version. Publishing a lower AssemblyVersion is useful
for new installs and manual reinstall/recovery, but it will not automatically
downgrade clients that already installed a higher version.

Options:
  --version VERSION       Public version to publish, for example 99.0.0.2.
  --only all|rsr|bmr      Limit updated entries. Default: all.
  --last-update EPOCH     LastUpdate unix timestamp. Default: current time.
  --rsr-changelog TEXT    Changelog for the RotationSolver entry.
  --bmr-changelog TEXT    Changelog for the BossModReborn entry.
  --verify-links          Check referenced release assets with curl.
  --dry-run               Print updated JSON without writing pluginmaster.json.
  --commit                Commit pluginmaster.json after updating it.
  --push                  Push the current branch after committing.
  -h, --help              Show this help.
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
    --only)
      ONLY="${2:?missing selection}"
      shift 2
      ;;
    --last-update)
      LAST_UPDATE="${2:?missing timestamp}"
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
    --verify-links)
      VERIFY_LINKS=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --commit)
      COMMIT=1
      shift
      ;;
    --push)
      PUSH=1
      COMMIT=1
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
if (( DRY_RUN && (COMMIT || PUSH) )); then
  die "--dry-run cannot be combined with --commit or --push"
fi

args=("${VERSION}" --only "${ONLY}")
if [[ -n "${LAST_UPDATE}" ]]; then
  args+=(--last-update "${LAST_UPDATE}")
fi
if [[ -n "${RSR_CHANGELOG}" ]]; then
  args+=(--rsr-changelog "${RSR_CHANGELOG}")
fi
if [[ -n "${BMR_CHANGELOG}" ]]; then
  args+=(--bmr-changelog "${BMR_CHANGELOG}")
fi
if (( VERIFY_LINKS )); then
  args+=(--verify-links)
fi
if (( DRY_RUN )); then
  args+=(--dry-run)
fi

"${SCRIPT_DIR}/update-pluginmaster.sh" "${args[@]}"

if (( COMMIT )); then
  cd "${REPO_ROOT}"
  git diff --quiet -- pluginmaster.json && die "pluginmaster.json did not change"
  git add pluginmaster.json
  git commit -m "Set public plugin version to ${VERSION}"
fi

if (( PUSH )); then
  cd "${REPO_ROOT}"
  git push origin HEAD
fi
