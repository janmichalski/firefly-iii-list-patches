#!/usr/bin/env bash
# Check whether a Firefly III image still ships the exact template files
# these patches were made from. Run it before every Firefly III upgrade.
#
# Usage: scripts/check-upstream.sh <firefly-iii-image>
# Example: scripts/check-upstream.sh fireflyiii/core:version-6.7.9
#
# Exit code 0: both originals match, the patched files can be mounted as they are.
# Exit code 1: at least one original changed; review the change before mounting.
set -euo pipefail

image=${1:?usage: $0 <firefly-iii-image>}

# Original files from Firefly III 6.7.9 and their SHA-256 sums.
declare -A expected=(
    [resources/views/transactions/index.blade.php]=c2293f96db23eff9dd6f13b4404e54ecdf83d7eadf3cf912455da28eb57986b5
    [resources/views/components/lists/groups-large.blade.php]=a5cb6633a39d3879d910857efce360dc7a8c5aa2d0ef84ee148c4c353fd28d3c
)

status=0
for path in "${!expected[@]}"; do
    actual=$(docker run --rm --entrypoint sha256sum "$image" "/var/www/html/$path" 2>/dev/null | cut -d' ' -f1) || actual="missing"
    if [[ $actual == "${expected[$path]}" ]]; then
        echo "OK       $path"
    else
        echo "CHANGED  $path (got $actual)"
        status=1
    fi
done

if [[ $status -ne 0 ]]; then
    echo "Upstream changed a patched template. Mounting the old patched file would hide that change." >&2
    echo "Compare the new original with patches/*.diff and update the patched file first." >&2
fi
exit $status
