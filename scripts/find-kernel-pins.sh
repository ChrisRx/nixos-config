#!/usr/bin/env bash
# Discover, for every kernel series from a minimum major version upward, the
# newest nixpkgs revision that still provides it. Emits the table
# modules/nixos/core/kernel.nix reads, so a series is already pinned by the time
# you decide you need it.
#
#   ./scripts/find-kernel-pins.sh [min-major] [branch]
#
# Both arguments default to the values recorded in PREVIOUS_PINS, falling back
# to 7 and nixos-26.05, so a routine refresh needs no arguments and the floor
# is a property of the table rather than of how it was last invoked. Passing a
# floor rewrites it: raise it when the table has grown further back than is
# useful, and series below it are dropped.
#
# The floor is a minimum, not an exact major: with the default of 7 a future
# 8.x picks itself up with no change here.
#
# nixpkgs replaces an EOL kernel with a bare `throw` in one commit, so the
# revision wanted for a removed series is that commit's parent; a series still
# alive pins the branch head. Detection reads one file per commit probe rather
# than cloning, and those reads are cached and shared across series.
#
# Set PREVIOUS_PINS to an existing table to carry forward entries that can no
# longer be rediscovered -- a removal commit eventually falls out of the commit
# window below, and losing a working pin on a routine refresh would be worse
# than keeping a stale one.
set -euo pipefail

# Explicit argument wins, then whatever the existing table recorded, then the
# built-in default.
prev_field() {
  if [ -n "${PREVIOUS_PINS:-}" ] && [ -s "${PREVIOUS_PINS:-}" ]; then
    jq -r --arg d "$2" ".$1 // \$d" "$PREVIOUS_PINS"
  else
    printf '%s' "$2"
  fi
}

min_major=${1:-$(prev_field minMajor 7)}
branch=${2:-$(prev_field branch nixos-26.05)}

file="pkgs/top-level/linux-kernels.nix"
api="https://api.github.com/repos/NixOS/nixpkgs"
raw="https://raw.githubusercontent.com/NixOS/nixpkgs"

note() { printf '%s\n' "$*" >&2; }
die() {
  note "ERROR: $*"
  exit 1
}
get() { curl -sSf --max-time 30 --retry 3 --retry-delay 2 "$@"; }

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

# One fetch per commit, reused across every series we probe.
file_at() {
  local sha=$1
  # Separate statement: `local a=$1 b=$a` expands all words before assigning,
  # so b would see the unset global rather than the new a.
  local path="$cache/$sha"
  if [ ! -s "$path" ]; then
    get "$raw/$sha/$file" >"$path" || die "could not fetch $file at $sha"
  fi
  printf '%s' "$path"
}

# Three states, and a hard failure on fetch errors. Collapsing "fetch failed"
# into "not alive" would silently turn a network blip into a bogus pin.
state_of() {
  local path
  path=$(file_at "$1")
  if grep -qE "^[[:space:]]*$2 = callPackage" "$path"; then
    echo alive
  elif grep -qE "^[[:space:]]*$2 = throw" "$path"; then
    echo removed
  else
    echo absent
  fi
}

head_sha=$(get "$api/commits/$branch" | jq -r .sha)
note "branch $branch at $head_sha"

# Every series the branch head knows about at or above the floor, alive or
# tombstoned as a throw. Matching any major keeps this correct when 8.x lands.
mapfile -t series < <(
  grep -oE "linux_[0-9]+_[0-9]+ = (callPackage|throw)" "$(file_at "$head_sha")" |
    sed -E 's/linux_([0-9]+)_([0-9]+) .*/\1.\2/' |
    awk -F. -v min="$min_major" '$1 >= min' |
    sort -u -V
)
[ ${#series[@]} -gt 0 ] || die "no linux_*_* series >= ${min_major} found on $branch"
note "series found: ${series[*]}"

mapfile -t commits < <(
  get "$api/commits?sha=$branch&path=$file&per_page=100" | jq -r '.[].sha'
)

declare -A HASH STORE
entries=()

for s in "${series[@]}"; do
  attr="linux_${s//./_}"

  if [ "$(state_of "$head_sha" "$attr")" = alive ]; then
    rev=$head_sha
    note "$s: alive at head"
  else
    removal=""
    prev=""
    for sha in "${commits[@]}"; do
      if [ "$(state_of "$sha" "$attr")" = alive ]; then
        removal=$prev
        break
      fi
      prev=$sha
    done
    if [ -z "$removal" ]; then
      note "$s: SKIP -- no alive->removed transition in the last ${#commits[@]} commits touching $file"
      continue
    fi
    rev=$(get "$api/commits/$removal" | jq -r '.parents[0].sha')
    note "$s: removed by $removal, pinning parent $rev"
  fi

  # Revisions repeat (every alive series shares the head), so prefetch once.
  if [ -z "${HASH[$rev]:-}" ]; then
    pf=$(nix flake prefetch --json "github:NixOS/nixpkgs/$rev")
    HASH[$rev]=$(jq -r .hash <<<"$pf")
    STORE[$rev]=$(jq -r .storePath <<<"$pf")
  fi

  # Trust nothing: evaluate the attribute at the candidate before emitting it.
  if ! version=$(nix eval --raw --impure --expr "
        let s = (import ${STORE[$rev]} { config = {}; }).linuxKernel.packages;
        in s.${attr}.kernel.version
      " 2>/dev/null); then
    note "$s: SKIP -- $attr does not evaluate at $rev"
    continue
  fi

  note "$s: verified $version"
  entries+=("$(jq -n --arg s "$s" --arg rev "$rev" \
    --arg sha256 "${HASH[$rev]}" --arg version "$version" \
    '{ ($s): { $rev, $sha256, $version } }')")
done

[ ${#entries[@]} -gt 0 ] || die "no series could be pinned"
found=$(printf '%s\n' "${entries[@]}" | jq -s 'add')

# Anything the sweep could not rediscover keeps its previous entry, so an aged
# out removal commit degrades to a stale pin rather than a missing one.
if [ -n "${PREVIOUS_PINS:-}" ] && [ -s "${PREVIOUS_PINS:-}" ]; then
  previous_all=$(jq '.series // {}' "$PREVIOUS_PINS")

  # Raising the floor is how the table is trimmed, so previous entries below it
  # are dropped rather than carried.
  previous=$(jq --argjson min "$min_major" \
    'with_entries(select((.key | split(".")[0] | tonumber) >= $min))' <<<"$previous_all")
  dropped=$(jq -r --argjson p "$previous" \
    '[keys[] | . as $k | select(($p | has($k)) | not)] | join(", ")' <<<"$previous_all")
  [ -z "$dropped" ] || note "dropped, below floor ${min_major}: $dropped"

  # Bind the key: inside `$f | has(.)` the dot would rebind to $f, not the key.
  carried=$(jq -r --argjson f "$found" \
    '[keys[] | . as $k | select(($f | has($k)) | not)] | join(", ")' <<<"$previous")
  [ -z "$carried" ] || note "carried forward from previous table: $carried"

  series_json=$(jq -n --argjson p "$previous" --argjson f "$found" '$p + $f')
else
  series_json=$found
fi

# No generated-at field on purpose: it would differ on every run, so the table
# would look changed when it is not. git dates the file.
jq -n --arg branch "$branch" --argjson minMajor "$min_major" \
  --argjson series "$series_json" \
  '{ $branch, $minMajor, $series }'
