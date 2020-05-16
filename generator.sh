#!/bin/bash

while read VERSION; do
  echo "+ building "
  docker build --pull -t $IMAGE_NAME:$VERSION --build-arg SKAFFOLD_VERSION=$VERSION .
  docker push $IMAGE_NAME:$VERSION
done < <(cat versions.txt)
