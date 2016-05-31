#!/usr/bin/env bash

set -ue

git checkout master
rm -rf esoui
cp -r "$1" .
find esoui/ -type f -name "*.dds" > Textures.txt
find esoui/ -type f -not -name "*.txt" -not -name "*.xml" -not -name "*.lua" -delete
vi README.md


