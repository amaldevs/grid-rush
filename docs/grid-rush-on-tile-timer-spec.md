# Grid Rush — On-Tile Timer Spec (v1.1)

**Type:** change spec against the v1.0 arcade-run spec / implementation. Everything not mentioned keeps v1.0 behavior (run model, wave generation, time-bank economy structure, seeds, save schema v2, telemetry shape, pause/visibility, single-file constraint).

## 0. Change summary

1. **The separate timer bar is removed.** The time bank is rendered **on every tile**: a translucent shade drains **top-to-bottom over each face**, synchronized across the grid, driven by the single run bank. One simulation, N displays.
2. **All three kinds show the drain — including reds.** The shade descends over the brows first (the primary red/happy tell), so a low bank makes the grid progressively harder to *read*, not just shorter to play. The timer display is itself a difficulty mechanic.
3. **The economy is tightened** (§3): smaller starting bank, lower cap, leaner refunds.

> Interpretation note (decided): this is the **synchronized** model — every tile displays the same bank value. The alternative (independent per-tile countdowns with staggered expiries, forcing target triage; reds carrying decoy timers) is a *different mechanic*, reserved as a possible wave-≥12 escalation in v2. Do not implement it here.

---

## 1. Tile drain rendering (normative)

- Each `.tile` gains a full-size overlay child (`.tile-shade`), `pointer-events: none`, above the SVG, below the target ring.
- The shade is anchored to the **top** of the tile and its coverage equals the drained fraction: `coverage = 1 − bank / capMs`.
  - Implementation: overlay spans 100% of the tile; `transform: scaleY(var(--drain)); transform-origin: top;` where `--drain ∈ [0, 1]`.
  - `--drain` is set **once per rAF tick on the grid container** (a single CSS-custom-property write); tiles inherit it. Never write per-tile styles per frame.
- **Denominator is `capMs`, not `startBankMs`:** a run starts with the top ~30% of every face already shaded (7000/10000), and refunds visibly *lift* the shade grid-wide. The shade rising on a correct tap replaces the old bar-fill feedback; keep the green `+0.Ns` float-up on the tapped tile.
- Shade appearance: translucent dark fill, ~65% opacity — faces stay readable *through* it at a cost of effort. Urgency replaces the old bar colors: shade tint neutral ≤ normal, **amber tint when bank ≤ 3500 ms, red tint + existing pulse animation when bank ≤ 1800 ms**.
- `prefers-reduced-motion`: no pulse; shade still moves (it is state display, not decoration) but with the transition-snapping already used elsewhere.

### Readability fairness invariants (new, kept forever)

1. At any drain level, at least one red discriminator must remain perceivable: the red base color reads through the translucent shade at all coverages, and the angry mouth (bottom third of the face) is unoccluded until coverage > 85% — which at cap-relative rendering means bank < 1500 ms, i.e. already inside the danger window. Full occlusion may only coincide with `RUN_OVER`.
2. The target ring renders **above** the shade at all times. Targets must be findable on a fully drained grid; they just aren't *readable* cheaply. (The ring is the "must tap" signal; the face is the "safe to tap" signal — only the second degrades.)
3. The shade never intercepts input (`pointer-events: none`) and never alters hit areas.

## 2. HUD changes

- **Delete** `.timer-track` / `.timer-fill` and the amber/danger bar classes.
- HUD reduces to: wave label (left) · spacer · pause (right). The `targets left` count stays in `.meta`.
- No numeric bank readout. The grid is the readout. (Dev mode may print `bank` in the corner under `?dev=1`.)

## 3. Economy retune ("a bit tougher")

```js
const ECON = {
  startBankMs: 7000,                                  // was 8000
  capMs: 10000,                                       // was 12000
  refundMs: n => Math.max(300, 550 - 15 * n),         // was max(350, 650 − 15n)
  waveClearBonusMs: n => Math.max(400, 1500 - 100 * n), // was max(500, 2000 − 100n)
  neutralPenaltyMs: 600                               // was 500
};
```

- Net effect: warm-up regime (bank building) compresses from waves 1–3 to waves 1–2; the net-negative squeeze starts around wave 4–5 instead of 6.
- **Do not tighten further in this change.** The occlusion mechanic (§1) independently raises difficulty in a way the old numbers never priced in; two difficulty increases are being shipped at once and telemetry must separate them. If `waveReached` medians collapse below ~4, the first lever to relax is the shade opacity (65% → 55%), not the economy.
- Tuning signals unchanged from v1.0 (`bankAtClearMs` trajectory), plus one addition to per-wave telemetry: `redTapsNearDrainCount` — wrong-red taps that occur while bank < 1800 ms. If red deaths cluster overwhelmingly in the danger window, the occlusion is doing its job; if they dominate at *high* bank too, the base discriminators are too weak (fix faces, not numbers).

## 4. Acceptance criteria (delta)

1. No separate timer bar exists anywhere in the DOM.
2. Every tile of every kind shows the identical drain level within one frame; a correct tap visibly raises the shade on **all** tiles simultaneously.
3. Drain is rendered relative to `capMs`: a fresh run starts visibly part-drained; the cap corresponds to fully clear faces.
4. Frame cost: one style write per tick for the drain (grid-level custom property), verified no per-tile writes in the tick path; smooth on a 6×6 grid on a physical mid-range Android device.
5. Red discriminator invariant holds: with bank at 1800 ms on a 6×6 wave, a red and a happy neutral are distinguishable in a screenshot (color + mouth); the target ring is fully visible at 0 bank... which is unreachable in PLAYING, so: at 200 ms bank.
6. Shade never blocks or shifts input: tap accuracy tests from v0.2 pass unchanged.
7. Bank freeze during WAVE_CLEAR now manifests as a frozen shade; background-resume during transition still loses zero bank.
8. Economy constants match §3 exactly; `scripts/check.sh` updated for the removed bar and new constants, and passes.

## 5. Out of scope

Independent per-tile timers / staggered expiries (candidate v2 mechanic, waves ≥ 12) · per-kind drain rates · shade-based disguise mechanics (a red whose shade "sticks" — good later, not now) · everything already excluded by v1.0 §8.

## 6. The v1.1 exit question

> On a drained grid, does hesitation come from **reading difficulty** (good — the mechanic works) or from **visual mush** (bad — opacity/contrast problem)? Watch a playtester at bank < 2000 ms: if they lean in and squint but still act, ship it; if they freeze or tap randomly, lower shade opacity before touching anything else.
