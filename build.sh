#!/usr/bin/env bash
set -euxo pipefail
source ./docker.env
./get-armbian-build.sh
rm -rf build/userpatches
cp -a userpatches build/

# compile.sh debugging options: DEBUG=yes RAW_LOG=yes
cd build
./compile.sh generate-dockerfile DOCKERFILE_USE_ARMBIAN_IMAGE_AS_BASE=no
docker build -t armbian-builder:local -f Dockerfile .
./compile.sh build helm-v2a

echo "Images in build/output/images/"
exit 0
