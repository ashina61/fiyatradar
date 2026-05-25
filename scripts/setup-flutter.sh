#!/usr/bin/env bash
set -euo pipefail

# Provisions a Flutter toolchain for ephemeral cloud/CI containers that ship
# without one. Pinned to the version the GitHub Actions workflows use
# (subosito/flutter-action -> 3.24.0) so local `flutter analyze`/`flutter test`
# results match CI. Override by exporting FLUTTER_VERSION before sourcing.
#
# Usage: source scripts/setup-flutter.sh   (source, so PATH persists)

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.0}"
FLUTTER_DIR="${HOME}/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

flutter --version
flutter precache --no-ios --no-macos --no-windows --no-linux --android
