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

if rg -n 'highestUnlocked|const LEVELS|levelStrip|showComplete|timer-track|timer-fill' "$HTML"; then
  echo "Removed campaign or timer bar code remains" >&2
  exit 1
fi

node - "$HTML" "$TMP" <<'NODE'
const fs = require('fs');
const html = fs.readFileSync(process.argv[2], 'utf8');
const script = fs.readFileSync(process.argv[3], 'utf8');
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

for (const required of [
  'startBankMs: 7000',
  'capMs: 10000',
  'Math.max(300, 550 - 15 * n)',
  'Math.max(400, 1500 - 100 * n)',
  'neutralPenaltyMs: 600'
]) {
  if (!script.includes(required)) throw new Error('Missing economy rule: ' + required);
}

if (!html.includes('class="tile-shade"')) throw new Error('Tile shade is missing');
if (!html.includes('transform: scaleY(var(--drain))')) throw new Error('Top to bottom drain rendering is missing');
if (!script.includes("el.grid.style.setProperty('--drain', String(drain))")) {
  throw new Error('Grid level synchronized drain write is missing');
}
if ((script.match(/style\.setProperty\('--drain'/g) || []).length !== 1) {
  throw new Error('Drain must have exactly one grid level style write path');
}

console.log('Validated synchronized tile countdown, tougher economy, and waves 1 through 50.');
NODE

rm -f "$TMP"
