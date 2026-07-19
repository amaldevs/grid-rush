#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HTML="$ROOT/index.html"
TMP="${TMPDIR:-/tmp}/grid-rush-inline.js"

test -f "$HTML"
test "$(find "$ROOT" -maxdepth 1 -name '*.html' | wc -l | tr -d ' ')" = "1"

sed -n '/<script>/,/<\\/script>/p' "$HTML" | sed '1d;$d' > "$TMP"
node --check "$TMP"

if rg -n '<script[^>]+src=|<link[^>]+stylesheet|https?://' "$HTML"; then
  echo "Unexpected external dependency in index.html" >&2
  exit 1
fi

if rg -n 'highestUnlocked|const LEVELS|levelStrip|showComplete' "$HTML"; then
  echo "Fixed campaign code remains in the arcade build" >&2
  exit 1
fi

node - "$TMP" <<'NODE'
const fs = require('fs');
const script = fs.readFileSync(process.argv[2], 'utf8');
const start = script.indexOf('function waveConfig(n)');
const end = script.indexOf('function loadSave()', start);
if (start < 0 || end < 0) throw new Error('waveConfig not found');
const source = script.slice(start, end);
const waveConfig = Function('"use strict"; ' + source + '; return waveConfig;')();

for (let n = 1; n <= 50; n += 1) {
  const wave = waveConfig(n);
  const total = wave.cols * wave.rows;
  if (wave.neutrals < 2) throw new Error('Wave ' + n + ' has fewer than 2 neutrals');
  if (wave.cols > 6 || wave.rows > 6) throw new Error('Wave ' + n + ' exceeds the 6 by 6 cap');
  if (wave.targets + wave.reds + wave.neutrals !== total) {
    throw new Error('Wave ' + n + ' tile totals do not match its grid');
  }
}

for (const required of ['startBankMs: 8000', 'capMs: 12000', 'refundMs:', 'waveClearBonusMs:']) {
  if (!script.includes(required)) throw new Error('Missing economy rule: ' + required);
}

console.log('Validated arcade JavaScript, time economy, and waves 1 through 50.');
NODE

rm -f "$TMP"
