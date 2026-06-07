#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
release_dir="${RELEASE_DIR:-$repo_root/.release/manual}"
packager="$repo_root/.release/release.sh"
publish=false

usage() {
    cat <<'EOF'
Usage: scripts/package-local.sh [--publish-curseforge]

Builds the addon with the BigWigs packager.

Options:
  --publish-curseforge  Upload to CurseForge. Requires CF_API_KEY in the environment.

Environment:
  RELEASE_DIR           Output directory. Defaults to .release/manual.
  CF_API_KEY            CurseForge API token, only needed with --publish-curseforge.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --publish-curseforge)
            publish=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

mkdir -p "$(dirname "$packager")" "$release_dir"

if [[ ! -f "$packager" ]]; then
    curl -fsSL https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh -o "$packager"
fi
chmod +x "$packager"

args=(-e -l -r "$release_dir")
if [[ "$publish" == true ]]; then
    if [[ -z "${CF_API_KEY:-}" ]]; then
        echo "CF_API_KEY is required when using --publish-curseforge." >&2
        exit 1
    fi
else
    args=(-d "${args[@]}")
fi

"$packager" "${args[@]}"
