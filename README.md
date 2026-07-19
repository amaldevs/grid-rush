# Grid Rush

Grid Rush is a compact mobile reflex game. Find every ringed face before the timer expires, avoid infected red faces, and do not waste time on bystanders.

The v0 prototype is deliberately implemented as one self contained `index.html` with no dependencies, build step, service worker, or network access.

## Run locally

Open `index.html` directly, or serve the directory with any static server:

```sh
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

Append `?dev=1` to enable local playtest telemetry and the development panel:

```text
http://localhost:8080/?dev=1
```

Telemetry remains on the device and can be copied as JSON from the result overlays or development panel.

## Scope

The implementation follows [the MVP build specification](docs/grid-rush-mvp-build-spec.md). It contains eight levels, deterministic layouts, local progress, accessible visual distinctions, automatic pause when backgrounded, minimal generated audio, and a one tap retry loop.

## Validation

Run:

```sh
./scripts/check.sh
```

The check extracts the inline JavaScript, validates its syntax with Node.js, verifies the required single file constraints, and checks the level configuration totals.

