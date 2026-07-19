#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HTML="$ROOT/index.html"
TMP="${TMPDIR:-/tmp}/grid-rush-inline.js"

test -f "$HTML"
test "$(find "$ROOT" -maxdepth 1 -name '*.html' | wc -l | tr -d ' ')" = "1"

sed -n '/<script>/,/<\/script>/p' "$HTML" | sed '1d;$d' > "$TMP"
node --check "$TMP"

if rg -n '<script[^>]+src=|<link[^>]+stylesheet|https?://' "$HTML"; then
  echo "Unexpected external dependency in index.html" >&2
  exit 1
fi

node - "$HTML" <<'NODE'
const fs = require('fs');
const html = fs.readFileSync(process.argv[2], 'utf8');
const match = html.match(/const LEVELS = (\[[\s\S]*?\n\s*\]);/);
if (!match) throw new Error('LEVELS configuration not found');
const levels = Function(`"use strict"; return (${match[1]})`)();
if (levels.length !== 8) throw new Error(`Expected 8 levels, found ${levels.length}`);
for (const level of levels) {
  if (level.targets + level.reds + level.neutrals !== level.cols * level.rows) {
    throw new Error(`Level ${level.id} tile totals do not match its grid`);
  }
}
console.log('Validated inline JavaScript and 8 level configurations.');
NODE

rm -f "$TMP"
