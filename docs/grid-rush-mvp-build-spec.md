# Grid Rush MVP Build Spec v0.2

This is the implementation contract for the first playable prototype.

## Deliverable

One `index.html` containing inline CSS, JavaScript, and SVG. There are no frameworks, build tools, service workers, assets, or network calls.

## Rules

There are three visually distinct tile kinds:

| Kind | Appearance | Result |
| --- | --- | --- |
| Target | Happy face with a golden ring | Resolves and reduces the remaining target count |
| Red | Red face with angry brows | Removes one heart and fails the shipped one heart levels |
| Neutral | Plain non red face without a ring | Applies the configured time penalty |

The player rule is: “Tap every ringed face before time runs out. Never tap a red one.”

A level is won when its final target is pressed with positive active time. It fails when active time reaches zero or no hearts remain. Any time deduction that exhausts the timer fails immediately.

Input decisions calculate live time rather than relying on the most recent animation frame. Tile gameplay classification is fixed at pointer press. Resolved targets are inert. The v0 grid is static.

## Flow

The game moves through boot, menu, level introduction, play, win, fail, pause, and completion states. The first attempt at a level during a session receives a short introduction. Retry skips it and starts the new attempt within one second. Winning the eighth and final level shows the MVP Complete screen. Progress never decreases or exceeds the configured maximum level.

Backgrounding pauses play. Resuming resets the animation timestamp so hidden time is never consumed. A play session owns exactly one animation frame loop, which is cancelled whenever play ends or pauses.

## Level configuration

| Level | Grid | Targets | Reds | Neutrals | Time |
| --- | --- | --- | --- | --- | --- |
| 1 | 2 by 2 | 2 | 0 | 2 | 10s |
| 2 | 3 by 2 | 3 | 1 | 2 | 10s |
| 3 | 3 by 3 | 3 | 1 | 5 | 9s |
| 4 | 3 by 3 | 4 | 2 | 3 | 9s |
| 5 | 3 by 4 | 4 | 2 | 6 | 8s |
| 6 | 3 by 4 | 5 | 3 | 4 | 8s |
| 7 | 4 by 4 | 5 | 3 | 8 | 8s |
| 8 | 4 by 4 | 6 | 4 | 6 | 8s |

All shipped levels use one heart and a 500ms neutral penalty. Layouts use seeded `mulberry32` randomness. Attempt counters last for the browser session and do not persist.

## Local development telemetry

Development mode is enabled with `?dev=1`. Each attempt records its level, seed, result, duration, first tap latency, taps, mistakes, attempt number, and next action. Records persist locally only. A pending result becomes abandoned if it is still unresolved on a later launch.

## Acceptance

The game must play from `file://` and a static HTTP origin, although persistence is only guaranteed through HTTP. Background time must not drain the timer. Retry must require one tap. Level 8 must never attempt to open level 9. Matching seeds must create matching layouts. Reduced motion and muted audio must preserve full playability.

The v0 exit question is whether scanning the grid, discriminating the three face types, and tapping quickly is satisfying enough that a playtester voluntarily retries.

