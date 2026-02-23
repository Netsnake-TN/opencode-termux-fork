#!/usr/bin/env bash
set -euo pipefail

BUN_VERSION="${1:?bun version required}"
OUT_DIR="${2:?out dir required}"
mkdir -p "$OUT_DIR/assets" "$OUT_DIR/logs" "$OUT_DIR/status" "$OUT_DIR/work"

HOST_BUN="$HOME/.bun/bin/bun"
if [[ ! -x "$HOST_BUN" ]]; then
	echo "host bun not found at $HOST_BUN" >&2
	exit 10
fi

"$HOST_BUN" build --help >"$OUT_DIR/logs/bun-build-help.txt" || true

cat >"$OUT_DIR/work/hello.ts" <<'TS'
console.log("hello from bun armv7 probe")
TS

status="failed"
reason="unknown"

if "$HOST_BUN" build "$OUT_DIR/work/hello.ts" --compile --target=bun-linux-armv7 -o "$OUT_DIR/assets/bun-hello-linux-armv7"; then
	file "$OUT_DIR/assets/bun-hello-linux-armv7" >"$OUT_DIR/logs/bun-hello-file.txt" || true
	status="success"
	reason="bun host supports bun-linux-armv7 compile target"
else
	reason="bun host compile target bun-linux-armv7 unsupported or compile failed"
fi

python3 - <<PY
import json
from pathlib import Path
Path("$OUT_DIR/status/bun-armv7-attempt.json").write_text(json.dumps({
  "status": "$status",
  "reason": "$reason",
  "bun_version": "$BUN_VERSION"
}, indent=2)+"\n")
PY

[[ "$status" == "success" ]]
