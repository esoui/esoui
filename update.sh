#!/usr/bin/env bash

set -ue

git checkout master
find esoui/ -type f -name "*.dds" > Textures.txt
find esoui/ -type f -not -name "*.txt" -not -name "*.xml" -not -name "*.lua" -delete
vi README.md


