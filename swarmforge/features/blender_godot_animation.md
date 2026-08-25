# Feature: reusable Blender → Godot equipment animations

## Outcome

Create a reproducible pipeline in `MafiaGardenGodot` for a Mixamo-like character
to hold a modular weapon convincingly in Idle, Walk, and Fire. It must be usable
for later rifles, pistols, swords, and two-hand props.

## Scope for the first vertical slice

1. One soldier, one rifle, and three states: Idle, Walk, Fire.
2. A Blender lab copy that produces candidate pose/animation exports without
   overwriting original assets.
3. A Godot lab scene using the candidate with modular weapon attachment.
4. Godot 4.6 `TwoBoneIK3D` support-hand correction toward the weapon's
   `Foregrip` marker.
5. Runtime captures and structured measurements for visual QA.

## Out of scope

- automatic Mixamo downloading;
- reloads, hand swaps, finger-by-finger procedural posing, or weapon recoil;
- replacing the current production attachment system before lab validation.

## Acceptance criteria

- Right hand owns the weapon through one `BoneAttachment3D`.
- The weapon is not parented to both hands.
- Each weapon defines `Grip`, `Foregrip` when needed, and `Muzzle`/`Tip`.
- Idle, Walk, and Fire have front, side, and three-quarter runtime captures.
- No state has an obviously floating hand, severe clipping, inverted elbow, or
  an implausible weapon direction.
- Adding a comparable rifle is documented as data/marker configuration rather
  than a bespoke attachment script.
