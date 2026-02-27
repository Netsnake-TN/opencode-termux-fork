#!/usr/bin/env bash
set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CFG_FILE="$CFG_DIR/opencode.json"
OMO_CFG="$CFG_DIR/oh-my-opencode.json"
LOCAL_PLUGINS="$CFG_DIR/local-plugins"
SYSTEM_PLUGINS="${PREFIX:-/data/data/com.termux/files/usr}/lib/opencode/plugins"

json_escape() {
	local s="$1"
	python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$s"
}

print_check() {
	local key="$1" status="$2" detail="$3"
	printf '{"check":%s,"status":%s,"detail":%s}\n' "$(json_escape "$key")" "$(json_escape "$status")" "$(json_escape "$detail")"
}

main() {
	print_check "opencode.bin" "info" "$(command -v opencode || echo missing)"
	if command -v opencode >/dev/null 2>&1; then
		print_check "opencode.version" "info" "$(opencode --version 2>/dev/null || echo unknown)"
	fi

	if [[ -f "$CFG_FILE" ]]; then
		if python3 -c 'import json,sys;json.load(open(sys.argv[1]))' "$CFG_FILE" >/dev/null 2>&1; then
			print_check "config.opencode_json" "ok" "$CFG_FILE"
		else
			print_check "config.opencode_json" "fail" "invalid json: $CFG_FILE"
		fi
	else
		print_check "config.opencode_json" "warn" "missing: $CFG_FILE"
	fi

	if [[ -f "$OMO_CFG" ]]; then
		print_check "config.omo_json" "ok" "$OMO_CFG"
	else
		print_check "config.omo_json" "warn" "missing: $OMO_CFG"
	fi

	if [[ -d "$LOCAL_PLUGINS" ]]; then
		local count
		count="$(find "$LOCAL_PLUGINS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
		print_check "plugins.local.count" "info" "$count"
	else
		print_check "plugins.local.count" "warn" "local plugin dir missing"
	fi

	if [[ -d "$SYSTEM_PLUGINS" ]]; then
		local count2
		count2="$(find "$SYSTEM_PLUGINS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
		print_check "plugins.system.count" "info" "$count2"
	else
		print_check "plugins.system.count" "info" "system plugin dir not present"
	fi
}

main
