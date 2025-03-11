#!/bin/bash

set -e

if test -f key.properties; then
    keypath="key.properties"
elif test -f ~/key.properties; then
    keypath="~/key.properties"
else
    read -p "Path to key.properties: " keypath
    if ! test -f $keypath; then
        echo "File does not exist."
        exit 1
    fi

fi

read -p "Version number: v" vernum
pushd /tmp
rm -rf build
git clone https://github.com/Lojcs/tsacdop --recurse-submodules
mv tsacdop build
cd build
git checkout v$vernum --force
ln -s keypath android/key.properties
export PUB_CACHE=$(pwd)/.pub-cache
.flutter/bin/flutter config --no-analytics
.flutter/bin/flutter pub get
.flutter/bin/flutter build apk --release --split-per-abi
popd
mv /tmp/build/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ./Tsacdop-Fork-v$vernum-arm64-v8a.apk
mv /tmp/build/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ./Tsacdop-Fork-v$vernum-armeabi-v7a.apk
mv /tmp/build/build/app/outputs/flutter-apk/app-x86_64-release.apk ./Tsacdop-Fork-v$vernum-x86_64.apk
