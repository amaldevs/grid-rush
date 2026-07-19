# Grid Rush

Grid Rush is a mobile reflex arcade game built around visual discrimination under pressure.

Every run starts at wave 1. Each wave begins with fully clear cells, then one synchronized shade descends across every face as the shared time bank drains. Correct taps refund time and wave clears add a bonus.

The ring rule is deliberately deceptive:

1. Solid gold ring: tap it.
2. Dashed red ring: avoid it because it ends the run.
3. No ring: leave it because it costs time.

The game is implemented as one self contained `index.html` with no dependencies, build step, service worker, or network access.

## Play

The private ChatGPT Site is available at:

https://grid-rush.amaldevs.chatgpt.site

## Run locally

Open `index.html` directly, or serve the directory with any static server:

```sh
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

Append `?dev=1` for local run telemetry, or `?seed=1234` to reproduce an entire generated run.

## Product contracts

The current behaviour follows [the drain and ring parity specification](docs/grid-rush-drain-ring-parity-spec.md), building on [the on tile timer specification](docs/grid-rush-on-tile-timer-spec.md) and [the arcade run specification](docs/grid-rush-arcade-run-spec.md). The earlier [v0.2 build specification](docs/grid-rush-mvp-build-spec.md) remains as design history.

## Validation

Run:

```sh
./scripts/check.sh
```

The check validates the inline JavaScript, dependency free single file constraint, full clear wave entry, running maximum drain normalization, ring parity, aggressive economy, and generated wave invariants through wave 50.
