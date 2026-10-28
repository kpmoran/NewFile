#!/bin/bash
# Builds NewFile.app into ./build. Run: ./build.sh   then open build/NewFile.app
set -euo pipefail
cd "$(dirname "$0")"
APP=build/NewFile.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -target arm64-apple-macosx13.0 \
    -framework Cocoa Sources/main.swift -o "$APP/Contents/MacOS/NewFile"
cp Info.plist "$APP/Contents/"
cp AppIcon.icns "$APP/Contents/Resources/"
# Ad-hoc sign so macOS remembers the Automation (Finder) permission across rebuilds.
codesign --force --sign - --identifier io.sagelab.NewFile "$APP"
echo "Built $APP"
