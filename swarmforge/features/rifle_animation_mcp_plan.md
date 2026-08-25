# Rifle animation MCP vertical slice

## Decision

Keep the rifle modular in Godot. The right hand is the sole weapon owner through
one `BoneAttachment3D`; the left hand may be corrected toward the weapon's
`Foregrip` with `TwoBoneIK3D`. Do not embed or parent the rifle into the source
character rig, and do not replace any existing `.blend`, `.glb`, `.tscn`, or
`.gd` asset.

## Current-system inspection

- `scenes/weapons/rifle.tscn` exposes `Grip`, `Foregrip`, and `Muzzle`.
- `scripts/weapon_attach.gd` supports a right-hand `BoneAttachment3D`, modular
  weapon instancing, marker lookup, and optional `TwoBoneIK3D`.
- `soldado_anim.tscn` instances the modular rifle under a right-hand
  `BoneAttachment3D`.
- Existing `.blend` and `.glb` files are source or prior candidates and must not
  be overwritten.
- `models/weapons/README.md` contains legacy embedded-weapon advice. It is not
  the design for this vertical slice.

## Role sequence and gates

1. **Blender rigger — connection gate.** Establish that Blender MCP targets a
   dedicated lab Blender instance on a port distinct from every other active
   Blender chat. Read-only endpoint inspection is sufficient. Do not manipulate
   Blender or any asset. Report endpoint identity, lab-file identity, port,
   conflicting active ports checked, and a screenshot or diagnostic log path.
2. **Blender rigger — inspection gate.** On a separately authorized follow-up,
   inspect the source rig, animation inventory, bone names/orientation, and the
   rifle marker contract. Produce a written diagnosis only; do not change source
   assets.
3. **Blender rigger — candidate gate.** After the diagnosis is accepted, create
   exactly one clearly named candidate rifle pose/animation in a backed-up lab
   copy. Preserve the Mixamo skeleton and all source animations.
4. **Godot integrator.** Import the candidate without replacing production
   assets. Use the existing modular rifle scene and one right-hand attachment;
   configure the support-hand IK target from `Foregrip`.
5. **Visual QA.** Validate runtime Idle, Walk, and Fire from front, side, and
   three-quarter views. Godot runtime captures are the source of truth.

No two roles may write through the same Blender MCP endpoint. Each gate requires
a committed handoff and review before the next gate begins.

## Vertical-slice acceptance criteria

- Idle begins in a plausible two-handed rifle pose; the support hand does not
  visibly float and the rifle has a stable, intentional aim direction.
- Walk preserves believable hand contact and aim without severe torso/weapon
  clipping, elbow inversion, or visible transition pops into or out of Idle.
- Fire preserves the same ownership and contact rules, has a plausible firing
  direction through `Muzzle`, and does not pop when transitioning from or back
  to Idle/Walk.
- Each state has Godot runtime captures from front, side, and three-quarter
  views, plus a report identifying scene, animation/state, candidate asset, and
  marker/IK configuration.
- A comparable rifle can be added by supplying its scene and marker transforms,
  without a bespoke attachment script.

## First handoff

The first handoff is only the Blender MCP connection gate. It authorizes no
Blender writes and no asset edits. If a dedicated endpoint or distinct port
cannot be proven, stop and report the blocker without opening or changing an
asset.
