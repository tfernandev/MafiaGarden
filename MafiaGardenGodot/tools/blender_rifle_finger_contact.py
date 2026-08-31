"""Collision-stop finger curl for the lab hold.

Removes far-side fingertip IK (that pulled digits through the palm),
restores Mixamo finger quats, then curls each joint until the tip
nears the AK without entering the palm or the rifle volume.

Optionally reparents Grip -> RightHand (keep world) so the weapon
follows the owner hand; left arm IK stays on Foregrip.

Run in Blender MCP:
  runpy.run_path(..., run_name='__main__')
"""
from __future__ import annotations

import math
import shutil

import bpy
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

FINGERS = ("Thumb", "Index", "Middle", "Ring", "Pinky")
STEP_DEG = 3.0
MAX_JOINT_DEG = 75.0
CONTACT_CM = 1.2
INSIDE_EPS = -0.0015
PALM = "HANDCOL_Palma"


def _bw(arm, name: str) -> Vector:
    return arm.matrix_world @ arm.pose.bones[name].head


def _bt(arm, name: str) -> Vector:
    return arm.matrix_world @ arm.pose.bones[name].tail


def _bvh_world(obj):
    deps = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(deps)
    me = ev.to_mesh()
    mw = ev.matrix_world
    bvh = BVHTree.FromPolygons(
        [mw @ v.co for v in me.vertices],
        [list(p.vertices) for p in me.polygons],
        epsilon=0.0,
    )
    return ev, me, mw, bvh


def _palm_bvh(mesh, side_left: bool):
    ev, me, mw, _ = _bvh_world(mesh)
    matn = [m.name if m else "" for m in mesh.data.materials]
    idx = matn.index(PALM)
    arm = bpy.data.objects["Armature"]
    rh = _bw(arm, "mixamorig:RightHand")
    lh = _bw(arm, "mixamorig:LeftHand")
    verts = [mw @ v.co for v in me.vertices]
    polys = []
    for p in me.polygons:
        if p.material_index != idx:
            continue
        c = Vector()
        for vi in p.vertices:
            c += me.vertices[vi].co
        pt = mw @ (c / len(p.vertices))
        is_l = (pt - lh).length < (pt - rh).length
        if is_l != side_left:
            continue
        polys.append(list(p.vertices))
    bvh = BVHTree.FromPolygons(verts, polys, epsilon=0.0) if polys else None
    return ev, me, bvh


def _inside(bvh, p: Vector, eps=INSIDE_EPS, max_dist=0.025) -> tuple[bool, float]:
    """Inside only if behind the surface AND close to it (ignore flipped-normal ghosts)."""
    loc, nrm, _, dist = bvh.find_nearest(p)
    if loc is None:
        return False, 9.0
    n = Vector(nrm).normalized()
    return bool((p - loc).dot(n) < eps and dist < max_dist), dist


def mute_finger_ik():
    arm = bpy.data.objects["Armature"]
    n = 0
    for pb in arm.pose.bones:
        if "Hand" not in pb.name:
            continue
        if not any(f in pb.name for f in FINGERS):
            continue
        for c in pb.constraints:
            if c.type == "IK":
                c.mute = True
                c.influence = 0.0
                n += 1
    bpy.context.view_layer.update()
    print(f"[WeaponCalib] muted {n} finger IK constraints")


def restore_mixamo_fingers(frame: int, side: str | None = None):
    """Overwrite pose with Mixamo quaternion/location from the active action."""
    arm = bpy.data.objects["Armature"]
    ad = arm.animation_data
    if not ad or not ad.action:
        return 0
    act = ad.action
    bag = act.layers[0].strips[0].channelbags[0]
    from collections import defaultdict

    vals = defaultdict(dict)
    needle = f"{side}Hand" if side else None
    for fc in bag.fcurves:
        dp = fc.data_path or ""
        if not any(x in dp for x in ("HandThumb", "HandIndex", "HandMiddle", "HandRing", "HandPinky")):
            continue
        if needle and needle not in dp:
            continue
        vals[dp][fc.array_index] = fc.evaluate(frame)
    n = 0
    for dp, comps in vals.items():
        if "pose.bones[\"" not in dp:
            continue
        name = dp.split("pose.bones[\"", 1)[1].split("\"]", 1)[0]
        prop = dp.rsplit(".", 1)[-1]
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        if prop == "rotation_quaternion":
            pb.rotation_mode = "QUATERNION"
            q = [comps.get(i, 0.0) for i in range(4)]
            if q[0] == 0 and q[1] == 0 and q[2] == 0 and q[3] == 0:
                q[0] = 1.0
            pb.rotation_quaternion = q
            n += 1
        elif prop == "location":
            pb.location = [comps.get(i, 0.0) for i in range(3)]
        elif prop == "scale":
            pb.scale = [comps.get(i, 1.0) for i in range(3)]
    bpy.context.view_layer.update()
    print(f"[WeaponCalib] restored Mixamo finger channels {n} @ frame {frame} side={side}")
    return n


def _tip(arm, side: str, f: str) -> Vector:
    return _bt(arm, f"mixamorig:{side}Hand{f}4")


def _try_axis(arm, pb, axis: Vector, sign: float, side: str, f: str, bvh_ak, bvh_pal) -> float:
    """Return score: drop in AK distance if we rotate STEP, or -1 if illegal."""
    q0 = pb.rotation_quaternion.copy()
    pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q0
    bpy.context.view_layer.update()
    p = _tip(arm, side, f)
    in_ak, d_ak = _inside(bvh_ak, p)
    in_pal, _ = _inside(bvh_pal, p) if bvh_pal else (False, 9.0)
    pb.rotation_quaternion = q0
    bpy.context.view_layer.update()
    if in_pal or in_ak:
        return -1.0
    return d_ak


def pick_curl(arm, pb, side: str, f: str, bvh_ak, bvh_pal, d_now: float, allow_y: bool = False):
    best = None
    best_d = d_now
    axes = [Vector((1, 0, 0)), Vector((0, 0, 1))]
    if allow_y:
        axes.append(Vector((0, 1, 0)))
    for axis in axes:
        for sign in (1.0, -1.0):
            q0 = pb.rotation_quaternion.copy()
            pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q0
            bpy.context.view_layer.update()
            p = _tip(arm, side, f)
            in_ak, d_ak = _inside(bvh_ak, p)
            in_pal, _ = _inside(bvh_pal, p) if bvh_pal else (False, 9.0)
            pb.rotation_quaternion = q0
            bpy.context.view_layer.update()
            if in_pal or in_ak:
                continue
            if d_ak < best_d - 0.0005:
                best_d = d_ak
                best = (axis.copy(), sign)
    return best


def curl_finger(
    side: str,
    f: str,
    bvh_ak,
    bvh_pal,
    max_per=(75.0, 75.0, 75.0),
    contact_cm=CONTACT_CM,
    allow_y=False,
):
    arm = bpy.data.objects["Armature"]
    p0 = _tip(arm, side, f)
    in_pal0, dp0 = _inside(bvh_pal, p0) if bvh_pal else (False, 9.0)
    if in_pal0:
        print(f"  {side} {f}: uncurl (tip in palm dist {dp0*100:.1f}cm)")
        for j in (3, 2, 1):
            name = f"mixamorig:{side}Hand{f}{j}"
            if name not in arm.pose.bones:
                continue
            pb = arm.pose.bones[name]
            pb.rotation_mode = "QUATERNION"
            for _ in range(int(max(max_per) / STEP_DEG)):
                p = _tip(arm, side, f)
                in_pal, d_pal = _inside(bvh_pal, p)
                if not in_pal:
                    break
                best_q = None
                best_score = d_pal
                q0 = pb.rotation_quaternion.copy()
                axes = [Vector((1, 0, 0)), Vector((0, 0, 1))]
                if allow_y:
                    axes.append(Vector((0, 1, 0)))
                for axis in axes:
                    for sign in (1.0, -1.0):
                        pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q0
                        bpy.context.view_layer.update()
                        p2 = _tip(arm, side, f)
                        in2, d2 = _inside(bvh_pal, p2)
                        if best_q is None or (not in2 and in_pal) or (in2 and d2 < best_score):
                            if (not in2) or (d2 < best_score):
                                best_score = -1.0 if not in2 else d2
                                best_q = pb.rotation_quaternion.copy()
                        pb.rotation_quaternion = q0
                if best_q is None:
                    break
                pb.rotation_quaternion = best_q
                bpy.context.view_layer.update()
            p = _tip(arm, side, f)
            in_pal, _ = _inside(bvh_pal, p)
            if not in_pal:
                break

    locked = None
    for j in (1, 2, 3):
        name = f"mixamorig:{side}Hand{f}{j}"
        if name not in arm.pose.bones:
            continue
        pb = arm.pose.bones[name]
        pb.rotation_mode = "QUATERNION"
        p = _tip(arm, side, f)
        _, d_now = _inside(bvh_ak, p)
        if d_now * 100 <= contact_cm:
            break
        pick = locked or pick_curl(arm, pb, side, f, bvh_ak, bvh_pal, d_now, allow_y=allow_y)
        if pick is None:
            continue
        if locked is None:
            locked = pick
        axis, sign = pick
        cap = max_per[j - 1]
        acc = 0.0
        while acc + STEP_DEG <= cap:
            q0 = pb.rotation_quaternion.copy()
            pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q0
            bpy.context.view_layer.update()
            p = _tip(arm, side, f)
            in_ak, d_ak = _inside(bvh_ak, p)
            in_pal, _ = _inside(bvh_pal, p) if bvh_pal else (False, 9.0)
            if in_pal or in_ak or d_ak > d_now + 0.002:
                pb.rotation_quaternion = q0
                bpy.context.view_layer.update()
                break
            acc += STEP_DEG
            d_now = d_ak
            if d_now * 100 <= contact_cm:
                break
        print(f"  {side} {f} j{j}: curl {acc:.0f}deg/{cap:.0f} -> tip_ak {d_now*100:.1f}cm")


def recurl_left_support():
    """Support hand: drape over the handguard, do not accordion-fold to chase the tip."""
    arm = bpy.data.objects["Armature"]
    lh = arm.pose.bones["mixamorig:LeftHand"]
    if "CR_hold" in lh.constraints:
        lh.constraints["CR_hold"].influence = 0.0
        print("[WeaponCalib] CR_hold inf=0 (was twisting left wrist)")
    if "SW_AK" in lh.constraints:
        lh.constraints["SW_AK"].influence = 0.25
    frame = int(bpy.context.scene.frame_current)
    restore_mixamo_fingers(frame, side="Left")
    mesh = bpy.data.objects["SoldadoMesh"]
    ak = bpy.data.objects["AK_Body"]
    _, _, _, bvh_ak = _bvh_world(ak)
    ev, me, bvh_pal = _palm_bvh(mesh, True)
    print("[WeaponCalib] LEFT SUPPORT CURL")
    for f in FINGERS:
        curl_finger(
            "Left",
            f,
            bvh_ak,
            bvh_pal,
            max_per=(30.0, 16.0, 8.0),
            contact_cm=2.8,
            allow_y=(f == "Thumb"),
        )
    ev.to_mesh_clear()
    print("[WeaponCalib] AFTER LEFT SUPPORT")
    diagnose()
    bpy.ops.wm.save_mainfile()
    print("[WeaponCalib] saved", bpy.data.filepath)


def diagnose():
    arm = bpy.data.objects["Armature"]
    mesh = bpy.data.objects["SoldadoMesh"]
    ak = bpy.data.objects["AK_Body"]
    _, _, _, bvh_ak = _bvh_world(ak)
    print("[WeaponCalib] FINGER CONTACT")
    for side, is_l in (("Right", False), ("Left", True)):
        ev, me, bvh_pal = _palm_bvh(mesh, is_l)
        for f in FINGERS:
            p = _tip(arm, side, f)
            in_ak, d_ak = _inside(bvh_ak, p)
            in_pal, d_pal = _inside(bvh_pal, p) if bvh_pal else (False, 9.0)
            st = "FAIL" if in_pal or in_ak else ("PASS" if d_ak * 100 <= CONTACT_CM + 1.5 else "WARN")
            print(
                f"  {side:5} {f:6} ak_cm={d_ak*100:5.1f} in_ak={in_ak} "
                f"palm_cm={d_pal*100:5.1f} in_palm={in_pal} {st}"
            )
        ev.to_mesh_clear()


def parent_grip_to_right_hand():
    grip = bpy.data.objects["Grip"]
    arm = bpy.data.objects["Armature"]
    mw = grip.matrix_world.copy()
    # Parent while the right-hand IK still holds the pose, then mute IK
    # so the rifle follows Mixamo instead of staying world-locked.
    pb = arm.pose.bones["mixamorig:RightHand"]
    parent_mw = (arm.matrix_world @ pb.matrix).copy()
    parent_mw.translation = arm.matrix_world @ pb.tail
    inv = parent_mw.inverted() @ mw
    grip.parent = None
    bpy.context.view_layer.update()
    grip.matrix_world = mw
    bpy.context.view_layer.update()
    grip.parent = arm
    grip.parent_type = "BONE"
    grip.parent_bone = "mixamorig:RightHand"
    grip.matrix_parent_inverse = inv
    grip.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    for cname in ("IK_mano", "SW_AK"):
        if cname in pb.constraints:
            pb.constraints[cname].mute = True
            print(f"[WeaponCalib] muted Right {cname}")
    bpy.context.view_layer.update()
    drift = (grip.matrix_world.translation - mw.translation).length * 100
    print(f"[WeaponCalib] Grip -> RightHand parent={grip.parent_bone} post-mute drift_cm={drift:.3f}")
    return drift


def shrink_debug_palms(target=0.02):
    for name in ("DEBUG_Palma_ManoIzquierda", "DEBUG_Palma_ManoDerecha"):
        o = bpy.data.objects.get(name)
        if o is None:
            continue
        bpy.context.view_layer.update()
        md = max(o.dimensions.x, o.dimensions.y, o.dimensions.z)
        if md < 1e-6:
            continue
        o.scale *= target / md
        bpy.context.view_layer.update()
        print(f"[WeaponCalib] shrink {name} dim={[round(x,3) for x in o.dimensions]}")


def run():
    src = bpy.data.filepath
    if src:
        bak = src.replace(".blend", "_pre_contact.bak.blend")
        shutil.copy2(src, bak)
        print("[WeaponCalib] bak", bak)
    frame = int(bpy.context.scene.frame_current)
    mute_finger_ik()
    restore_mixamo_fingers(frame)
    print("[WeaponCalib] AFTER MIXAMO RESTORE")
    diagnose()
    mesh = bpy.data.objects["SoldadoMesh"]
    ak = bpy.data.objects["AK_Body"]
    _, _, _, bvh_ak = _bvh_world(ak)
    print("[WeaponCalib] COLLISION CURL")
    for side, is_l in (("Right", False), ("Left", True)):
        ev, me, bvh_pal = _palm_bvh(mesh, is_l)
        for f in FINGERS:
            curl_finger(side, f, bvh_ak, bvh_pal)
        ev.to_mesh_clear()
    print("[WeaponCalib] AFTER CURL")
    diagnose()
    drift = parent_grip_to_right_hand()
    shrink_debug_palms()
    print("[WeaponCalib] AFTER PARENT")
    diagnose()
    bpy.ops.wm.save_mainfile()
    print("[WeaponCalib] saved", bpy.data.filepath, "drift", drift)


if __name__ == "__main__":
    run()
elif __name__ == "leftfix":
    recurl_left_support()
