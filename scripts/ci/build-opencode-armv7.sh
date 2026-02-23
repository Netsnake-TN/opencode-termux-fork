#!/usr/bin/env bash
set -euo pipefail

OPENCODE_VERSION="${1:?opencode version required}"
OUT_DIR="${2:?out dir required}"
mkdir -p "$OUT_DIR/assets" "$OUT_DIR/logs" "$OUT_DIR/status" "$OUT_DIR/work/opencode"

HOST_BUN="$HOME/.bun/bin/bun"
if [[ ! -x "$HOST_BUN" ]]; then
	echo "host bun not found at $HOST_BUN" >&2
	exit 10
fi

WORK="$OUT_DIR/work/opencode"
cd "$WORK"

npm pack "opencode@${OPENCODE_VERSION}" >"$OUT_DIR/logs/opencode-npm-pack.txt" 2>&1 || {
	echo "npm pack opencode failed" >&2
	exit 20
}

tgz=$(ls -1 opencode-*.tgz | head -n1)
tar -xzf "$tgz"

python3 - <<'PY' >"$OUT_DIR/logs/opencode-package-bin.txt"
import json
from pathlib import Path
p=Path('package/package.json')
d=json.loads(p.read_text())
print(json.dumps({"name":d.get("name"),"version":d.get("version"),"bin":d.get("bin")}, indent=2))
PY

BIN_REL=$(
	python3 - <<'PY'
import json
from pathlib import Path
d=json.loads(Path('package/package.json').read_text())
b=d.get('bin')
if isinstance(b, str):
    print(b)
elif isinstance(b, dict):
    print(next(iter(b.values())))
else:
    raise SystemExit(1)
PY
)

ENTRY="package/${BIN_REL}"
if [[ ! -f "$ENTRY" ]]; then
	echo "bin entry not found: $ENTRY" >&2
	exit 30
fi

status="failed"
reason="unknown"
if "$HOST_BUN" build "$ENTRY" --compile --target=bun-linux-armv7 -o "$OUT_DIR/assets/opencode-linux-armv7" >"$OUT_DIR/logs/opencode-bun-compile.txt" 2>&1; then
	file "$OUT_DIR/assets/opencode-linux-armv7" >"$OUT_DIR/logs/opencode-armv7-file.txt" || true
	status="success"
	reason="compiled opencode package entry with host bun"
else
	reason="bun compile target unsupported or package entry requires unsupported build/runtime features"
fi

python3 - <<PY
import json
from pathlib import Path
Path("$OUT_DIR/status/opencode-armv7-attempt.json").write_text(json.dumps({
  "status": "$status",
  "reason": "$reason",
  "opencode_version": "$OPENCODE_VERSION"
}, indent=2)+"\n")
PY

[[ "$status" == "success" ]]
