#!/bin/bash

set -eu -o pipefail
set -x

# safer than rm
echo -n > versions.txt

MAX_VERSIONS=${MAX_VERSIONS:-5}

while read -r VERSION; do
  echo "${VERSION}" >> versions.txt
done < <(curl -sSq -H "Accept: application/vnd.github+json" https://api.github.com/repos/GoogleContainerTools/skaffold/releases?per_page=100 | \
          jq -r '.[] | select(.prerelease==false) | .tag_name' | \
          sed 's:^v::' | sort -rV | head -n ${MAX_VERSIONS})
