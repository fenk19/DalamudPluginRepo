#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

VERSION=""
TAG=""
ONLY="all"
DRY_RUN=0
VERIFY_LINKS=0
COMMIT=0
PUSH=0
LAST_UPDATE=""
REPO_URL=""
RSR_REPO_URL=""
BMR_REPO_URL=""
RSR_ASSET=""
BMR_ASSET=""
RSR_SOURCE_ASSET=""
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
  --tag TAG               GitHub release tag. Default: VERSION.
  --only all|rsr|bmr      Limit updated entries. Default: all.
  --repo-url URL          Public release repository URL for both plugin assets.
                          Default: https://github.com/fenk19/DalamudPluginRepo
  --rsr-repo-url URL      RotationSolver-BMR release repository URL.
  --bmr-repo-url URL      BossModReborn-RSR release repository URL.
  --rsr-asset NAME        RSR release asset name.
  --bmr-asset NAME        BMR release asset name.
  --rsr-source-asset NAME RSR corresponding-source asset name.
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
    --tag)
      TAG="${2:?missing tag}"
      shift 2
      ;;
    --only)
      ONLY="${2:?missing selection}"
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
if [[ -n "${TAG}" ]]; then
  args+=(--tag "${TAG}")
fi
if [[ -n "${REPO_URL}" ]]; then
  args+=(--repo-url "${REPO_URL}")
fi
if [[ -n "${RSR_REPO_URL}" ]]; then
  args+=(--rsr-repo-url "${RSR_REPO_URL}")
fi
if [[ -n "${BMR_REPO_URL}" ]]; then
  args+=(--bmr-repo-url "${BMR_REPO_URL}")
fi
if [[ -n "${RSR_ASSET}" ]]; then
  args+=(--rsr-asset "${RSR_ASSET}")
fi
if [[ -n "${BMR_ASSET}" ]]; then
  args+=(--bmr-asset "${BMR_ASSET}")
fi
if [[ -n "${RSR_SOURCE_ASSET}" ]]; then
  args+=(--rsr-source-asset "${RSR_SOURCE_ASSET}")
fi
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
