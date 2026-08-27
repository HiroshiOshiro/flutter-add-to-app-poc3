#!/bin/sh
# 手元のFlutter SDKが .flutter-version の下限を満たすか調べる。
#
# .flutter-version は「サポートする下限」。これ以上なら何でもよい。
# CIはこの下限そのものでビルドする。新しいSDKにしか無いAPIを使うと落ちるため。
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MINIMUM=$(tr -d '[:space:]' < "$ROOT/.flutter-version")
ACTUAL=$(flutter --version 2>/dev/null | sed -n '1s/^Flutter \([^ ]*\).*/\1/p')

if [ -z "$ACTUAL" ]; then
  echo "error: flutter が見つからない。PATHを確認する" >&2
  exit 1
fi

# 並べ替えて先頭が下限のままなら ACTUAL >= MINIMUM
if [ "$(printf '%s\n%s\n' "$MINIMUM" "$ACTUAL" | sort -V | head -1)" != "$MINIMUM" ]; then
  cat >&2 <<MSG
error: Flutter SDK が下限を満たしていない
  下限 (.flutter-version): $MINIMUM
  手元 (flutter --version): $ACTUAL

$MINIMUM 以上に切り替えてから、生成物を作り直すこと:
  cd legacyapp_flutter
  flutter pub get
  flutter build swift-package --platform ios
MSG
  exit 1
fi

echo "Flutter $ACTUAL (下限 $MINIMUM を満たす)"
