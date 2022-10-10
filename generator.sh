#!/bin/bash

set -eu -o pipefail
set -x

while read VERSION; do
  echo "+ building $IMAGE_NAME:$VERSION"
  docker build --pull -t $IMAGE_NAME:$VERSION --build-arg SKAFFOLD_VERSION=$VERSION .
  docker push $IMAGE_NAME:$VERSION
done < <(cat versions.txt)
