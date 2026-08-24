#!/bin/sh
# 手元のFlutter SDKが .flutter-version と一致するか調べる。
#
# FVMのようなバージョンマネージャを使わない構成のため、一致は自動では保たれない。
# ビルドが通ってしまい気づかないので、明示的に確認する。
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
EXPECTED=$(tr -d '[:space:]' < "$ROOT/.flutter-version")
ACTUAL=$(flutter --version 2>/dev/null | sed -n '1s/^Flutter \([^ ]*\).*/\1/p')

if [ -z "$ACTUAL" ]; then
  echo "error: flutter が見つからない。PATHを確認する" >&2
  exit 1
fi

if [ "$EXPECTED" != "$ACTUAL" ]; then
  cat >&2 <<MSG
error: Flutter SDK のバージョンが一致しない
  期待 (.flutter-version): $EXPECTED
  実際 (flutter --version): $ACTUAL

$EXPECTED に切り替えてから、生成物を作り直すこと:
  cd legacyapp_flutter
  flutter pub get
  flutter build swift-package --platform ios
MSG
  exit 1
fi

echo "Flutter $ACTUAL (.flutter-version と一致)"
