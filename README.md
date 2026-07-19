# Grid Rush

Grid Rush is a mobile reflex arcade game. Tap every ringed face, avoid infected red faces, and keep a shared time bank alive for as many waves as possible.

Every run starts at wave 1. Correct taps refund time, wave clears add a larger bonus, and the generated grids become denser as the run progresses. One red tap ends the run.

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

Append `?dev=1` for local run telemetry:

```text
http://localhost:8080/?dev=1
```

Append `?seed=1234` to reproduce an entire generated run.

## Product contract

The current behaviour follows [the arcade run specification](docs/grid-rush-arcade-run-spec.md). The earlier [v0.2 build specification](docs/grid-rush-mvp-build-spec.md) is retained as design history.

## Validation

Run:

```sh
./scripts/check.sh
```

The check validates the inline JavaScript, dependency free single file constraint, removal of the fixed level campaign, and generated wave invariants through wave 50.
