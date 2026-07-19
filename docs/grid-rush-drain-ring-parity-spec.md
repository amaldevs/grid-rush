# Grid Rush — Drain Render + Ring Parity Spec (v1.2)

**Type:** change spec against v1.1. Everything not mentioned keeps v1.1 behavior (synchronized on-tile drain, run/bank model, wave generation, seeds, telemetry, single-file constraint).

## 0. Change summary

1. **Every wave starts with fully clear cells.** The drain shade is normalized per wave, never showing a wave that begins part-drained — regardless of how little bank is actually carried in.
2. **Red tiles get rings too.** The ring stops being the "tap me" marker and becomes a "decide" marker; targets and reds are distinguished by ring style + face, and ring-scanning alone no longer works.
3. **The economy tightens again** (§3) — the "aggressive" step.

---

## 1. Per-wave drain normalization (replaces v1.1 §1 denominator rule)

- New per-wave runtime value: `waveMaxBankMs` — set to the bank at wave entry (after the wave-clear bonus of the previous wave), then **updated as a running max** whenever refunds push the bank higher during the wave.
- Displayed coverage: `coverage = 1 − bank / waveMaxBankMs`, clamped to [0, 1].
  - Wave entry ⇒ coverage 0: **every wave starts with fully clear faces.**
  - A refund that raises the bank above the previous max lifts the shade back to fully clear and raises the denominator; the shade can never render "over-full."
- **Height is now relative; truth lives in the tint.** Urgency tinting stays on the **absolute** bank: amber when bank ≤ 3500 ms, red + pulse when bank ≤ 1800 ms. Consequence (intended): a wave entered with 2000 ms of bank renders full-height but already red-tinted and visibly fast-draining. Players learn: shade height = how this wave is going; shade color = how the run is going.
- Drain speed varies by wave as a side effect (same real-time drain over a smaller denominator = faster visual descent on low-bank waves). This is correct and desirable tension; do not compensate for it.
- Refund feedback: when the shade is already fully lifted (bank at running max), the shade cannot show the refund — the green `+0.Ns` float-up on the tapped tile is therefore mandatory, not decorative. Keep it.
- Everything else from v1.1 §1 stands: single grid-level `--drain` write per tick, shade above SVG / below rings, `pointer-events: none`, ~65% opacity, reduced-motion handling.

## 2. Ring parity (replaces the v0.2 "ring = target" rule)

| Kind | Ring | Face |
|---|---|---|
| **Target** | **Solid** gold ring, existing pulse | Happy face |
| **Red** | **Dashed** red ring, same geometry and pulse timing | Red face, angry brows/mouth |
| **Neutral** | No ring | Plain face |

- Both ring types render **above the shade** at all times (unchanged z-order rule).
- **Discrimination redundancy (normative):** target vs red must never come down to hue alone. The solid-vs-dashed stroke is the second channel (`stroke-dasharray` on an SVG ring, or CSS `border-style: dashed` if the existing `::before` ring is kept — either is fine, but the dash gaps must be visible at 48 px tiles).
- Updated player rule (menu tagline + run intro line): **"Tap every solid-gold ring. Dashed red rings end the run. No ring — leave it."**
- Fairness invariant update (supersedes v1.1 §1 invariant 2): on a fully drained grid, a target and a red must remain distinguishable **by ring alone** (color + dash), since faces are the occluded channel. Verifiable by screenshot at bank ≤ 200 ms.
- Neutrals remain ringless: they are findable as "the ringless ones" even under heavy shade, and their cost stays a penalty, not a death — unchanged.

## 3. Economy retune (the "aggressive" step)

```js
const ECON = {
  startBankMs: 6000,                                   // was 7000
  capMs: 9000,                                         // was 10000
  refundMs: n => Math.max(250, 500 - 20 * n),          // was max(300, 550 − 15n)
  waveClearBonusMs: n => Math.max(350, 1200 - 100 * n), // was max(400, 1500 − 100n)
  neutralPenaltyMs: 700                                 // was 600
};
```

- Warm-up regime effectively disappears: even wave 1–2 are near-neutral economy; the squeeze starts immediately and hard around wave 3–4.
- Relief-lever order if telemetry shows collapse (median `waveReached` < 3 after ~10 runs of practice): first shade opacity (65% → 55%), then `refundMs` slope (−20 → −15), then `startBankMs`. One lever per iteration.
- New telemetry per wave (in addition to v1.1): `waveMaxBankMs` and `bankAtWaveEntryMs` — together with `bankAtClearMs` these show whether players are treading water (entry ≈ clear), sinking (clear < entry), or recovering (max > entry) at each depth. The economy is tuned right when the median run transitions tread → sink around wave 4–6, and red-ring deaths (not timeouts) account for a meaningful share of run ends — if nearly all deaths are timeouts, the dashed rings are too easy to avoid and reds are decorative; consider red count or placement, not economy.

## 4. Acceptance criteria (delta)

1. Every wave's first rendered frame shows coverage 0 on all tiles, including a wave entered with < 2000 ms of bank (which must simultaneously show the red tint + pulse).
2. A refund above the running max lifts the shade to fully clear and subsequent drain renders against the new denominator; the shade never renders negative/over-full.
3. Reds display dashed red rings above the shade; targets solid gold; neutrals none. A grayscale screenshot of a drained grid still distinguishes target from red by dash pattern.
4. The run-intro line and menu tagline state the new three-way ring rule.
5. Economy constants match §3 exactly; `scripts/check.sh` updated and passing.
6. Regression: all v1.1 criteria not superseded here still pass (single style-write per tick, WAVE_CLEAR freeze, input never blocked by shade, 6×6 smoothness on device).

## 5. Out of scope

Independent per-tile timers (still the v2 candidate) · ring-style disguises (a red with a *solid* ring — a natural future cruelty, explicitly not now) · per-kind drain rates · everything excluded by v1.0/v1.1.

## 6. The v1.2 exit question

> With ring parity, deaths should migrate from timeouts toward red taps. Is the resulting death mix (telemetry: outcome ratio by wave) roughly balanced — say 40–60% red taps in waves ≥ 4? All-timeout = reds too avoidable; all-red = discrimination unfair. Balanced = the game is now about *looking*, which is the game you've been steering toward.
