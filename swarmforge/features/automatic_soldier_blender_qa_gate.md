# Blender quantitative QA implementation gate

## Task and ownership

Board task: `Crear animacion automatica de soldado con arma adjunta`.

This is the first implementation handoff. `blender-rigger` owns the read-only
Blender-side collector and evaluator implementation against a dedicated lab
copy. `visual-qa` independently audits reproducibility and issues the gate
verdict from structured evidence. It must not edit Blender or Godot assets.

Rig changes, animation changes, candidate export, and all Godot work remain
blocked until this gate records `PASS`.

## Required implementation

1. Record a baseline manifest for the real soldier and rifle inputs: content
   hashes, paths, Blender version, units/meters, object and armature scale,
   skeleton and bone inventory, action names/ranges, and `Grip`, `Foregrip`, and
   `Muzzle`/`Tip` transforms. Do not modify or resave source assets.
2. Implement a deterministic Blender lab collector and evaluator for Idle,
   Walk, Fire, and their transitions. It must measure:
   - `Grip` to right-palm distance and `Foregrip` to left-palm distance;
   - palm and finger orientation/contact relative to the weapon;
   - barrel direction relative to the declared aim vector;
   - IK reach ratio, bend angle, pole-plane sign, and singular/unreachable frames;
   - weapon/hand/body penetration through reproducible proximity queries or
     raycasts;
   - temporal contact and transform stability.
3. Emit versioned JSONL with one row per sample and one summary row. Include
   candidate/input hash, run ID, Blender version, scene/action/transition, FPS,
   frame/time, raw measurements, threshold violations, aggregate statistics,
   worst samples, coverage status, and automatic `PASS`/`FAIL`.
4. Return process status 0 only for `PASS`; missing markers/bones, NaN/invalid
   measurements, non-uniform unauthorized scale, incomplete samples, or a hard
   threshold violation must return nonzero and `FAIL`.
5. Store secondary front, side, and three-quarter captures linked by run ID.
   Captures document the result but cannot override the quantitative verdict.

## Calibration and provisional thresholds

Sample at least 60 Hz: Idle for 3 seconds, two complete Walk cycles, complete
Fire (or 2 seconds), and five repetitions of each required transition. Calibrate
from real-asset distributions and record sample count, percentiles, outliers,
measurement uncertainty, rationale, and the immutable threshold-set version.
Calibration must not tune against a future candidate.

Begin with `rifle_grip_v1` guardrails:

- right Grip distance: p95 <= 0.025 m, max <= 0.040 m;
- left Foregrip distance: p95 <= 0.030 m, max <= 0.050 m;
- palm normal: p95 <= 20 degrees, max <= 30 degrees;
- palm longitudinal axis: p95 <= 15 degrees, max <= 25 degrees;
- at least three non-thumb fingers 0.002--0.020 m from grip surface, thumb
  <= 0.025 m, joint penetration <= 0.005 m;
- muzzle/aim error: Idle and Fire p95 <= 5 degrees/max <= 8 degrees; Walk and
  transitions p95 <= 10 degrees/max <= 15 degrees;
- IK reach ratio 0.55--0.97, elbow bend 10--165 degrees, stable pole-plane sign,
  and zero singular or unreachable samples;
- hand/weapon penetration <= 0.005 m, body/weapon penetration <= 0.010 m, and
  no muzzle-axis ray through torso or head;
- per-frame contact delta <= 0.010 m and weapon angular delta <= 8 degrees at
  60 Hz; transition-boundary jump <= 0.020 m and <= 10 degrees.

If real-asset calibration proves a threshold invalid because of measurement
noise or proxy geometry, change it only in a new version and document the raw
evidence and reason. Never relax it merely to produce a passing baseline.

## Acceptance criteria for this handoff

- Source assets are byte-identical before and after the run.
- A clean checkout/lab copy can reproduce the same sample coverage and verdict.
- Automated tests cover transform math, angular wrap, percentiles, missing data,
  singular IK, penetration boundaries, temporal discontinuities, and exit codes.
- The baseline manifest, versioned threshold file, JSONL samples, summary, test
  report, command line, and secondary capture paths are included in the evidence.
- `visual-qa` independently runs or audits the evaluator and returns explicit
  `PASS` or `FAIL` with exact metric/reproducibility reasons.
- No rig, animation, GLB candidate, Godot scene, or Godot script is modified or
  forwarded while this gate is incomplete or failing.

