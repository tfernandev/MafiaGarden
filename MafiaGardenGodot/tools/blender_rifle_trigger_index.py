"""Detect the trigger-guard hole and seat the right index there.

The hole is the enclosed empty in a side-view YZ slice (the guard loop).
The trigger is the front-top inner wall of that loop. Mixamo index is
already at the hole in XY; we only drop the pad onto the trigger in Z,
keeping local X inside the rifle thickness so the finger goes through
the loop. Other right fingers curl around the pistol grip. No fingertip IK.
"""
from __future__ import annotations

import math
import sys
from collections import defaultdict, deque

import bpy
from mathutils import Quaternion, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, r"C:\Users\Usuario\source\JuegosMobile\MafiaGardenGodot\tools")
from blender_rifle_finger_contact import (  # noqa: E402
    STEP_DEG,
    _bt,
    _bvh_world,
    _inside,
    _palm_bvh,
    curl_finger,
    diagnose,
    mute_finger_ik,
)

WELL_NAME = "DEBUG_TriggerWell"
X_HOLE = (0.220, 0.275)


def detect_trigger_well(ak) -> dict:
    """Enclosed empty in the YZ slice = trigger-guard interior.

    Trigger blade ≈ front-top inner wall of that loop, not the hole centroid
    (the centroid sits too low, in the grip cavity).
    """
    verts = [v.co.copy() for v in ak.data.vertices]
    bvh = BVHTree.FromPolygons(
        verts,
        [list(p.vertices) for p in ak.data.polygons],
        epsilon=0.0,
    )
    xs = [v.x for v in verts if -0.22 <= v.y <= -0.10 and -0.08 <= v.z <= 0.06]
    x = sorted(xs)[len(xs) // 2] if xs else 0.244
    y0, y1, z0, z1 = -0.28, 0.08, -0.14, 0.14
    ny, nz = 72, 56
    occ = [[False] * nz for _ in range(ny)]
    for iy in range(ny):
        y = y0 + (y1 - y0) * iy / (ny - 1)
        for iz in range(nz):
            z = z0 + (z1 - z0) * iz / (nz - 1)
            loc, nrm, idx, d = bvh.find_nearest(Vector((x, y, z)))
            occ[iy][iz] = d is not None and d < 0.004

    seen = [[False] * nz for _ in range(ny)]
    holes = []
    for iy in range(ny):
        for iz in range(nz):
            if occ[iy][iz] or seen[iy][iz]:
                continue
            q = deque([(iy, iz)])
            seen[iy][iz] = True
            cells = []
            border = False
            while q:
                cy, cz = q.popleft()
                cells.append((cy, cz))
                if cy == 0 or cz == 0 or cy == ny - 1 or cz == nz - 1:
                    border = True
                for dy, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny2, nz2 = cy + dy, cz + dz
                    if not (0 <= ny2 < ny and 0 <= nz2 < nz):
                        continue
                    if seen[ny2][nz2] or occ[ny2][nz2]:
                        continue
                    seen[ny2][nz2] = True
                    q.append((ny2, nz2))
            if not border and 20 <= len(cells) <= 400:
                holes.append(cells)
    if not holes:
        raise RuntimeError("no enclosed trigger-guard hole")
    holes.sort(key=lambda h: sum(c[0] for c in h) / len(h))
    hole = holes[0]
    ys = [y0 + (y1 - y0) * c[0] / (ny - 1) for c in hole]
    zs = [z0 + (z1 - z0) * c[1] / (nz - 1) for c in hole]
    hole_set = set(hole)
    wall = []
    for iy, iz in hole_set:
        for dy, dz in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, 1)):
            a, b = iy + dy, iz + dz
            if 0 <= a < ny and 0 <= b < nz and occ[a][b]:
                y = y0 + (y1 - y0) * a / (ny - 1)
                z = z0 + (z1 - z0) * b / (nz - 1)
                wall.append((y, z))
    roof = [w for w in wall if w[1] >= 0.00 and w[0] >= -0.16]
    if roof:
        y_t = sum(w[0] for w in roof) / len(roof)
        z_t = sum(w[1] for w in roof) / len(roof)
    else:
        y_t = sum(ys) / len(ys)
        z_t = min(zs) + 0.78 * (max(zs) - min(zs))
    local = Vector((x, y_t, z_t))
    return {
        "world": ak.matrix_world @ local,
        "local": local,
        "gap_cm": (max(zs) - min(zs)) * 100.0,
        "bbox": (min(ys), max(ys), min(zs), max(zs)),
        "x": x,
        "n_cells": len(hole),
    }


def _place_debug(mid: Vector):
    if WELL_NAME in bpy.data.objects:
        o = bpy.data.objects[WELL_NAME]
    else:
        o = bpy.data.objects.new(WELL_NAME, None)
        bpy.context.collection.objects.link(o)
    o.empty_display_type = "SPHERE"
    o.empty_display_size = 0.014
    o.matrix_world.translation = mid
    if "ORIENT_Gatillo" in bpy.data.objects:
        bpy.data.objects["ORIENT_Gatillo"].matrix_world.translation = mid


def _index_pad(arm) -> Vector:
    a = arm.matrix_world @ arm.pose.bones["mixamorig:RightHandIndex2"].tail
    b = arm.matrix_world @ arm.pose.bones["mixamorig:RightHandIndex3"].head
    return (a + b) * 0.5


def _local_ak(ak, p: Vector) -> Vector:
    return ak.matrix_world.inverted() @ p


def restore_right_index(frame: int):
    arm = bpy.data.objects["Armature"]
    act = arm.animation_data.action
    bag = act.layers[0].strips[0].channelbags[0]
    vals = defaultdict(dict)
    for fc in bag.fcurves:
        dp = fc.data_path or ""
        if "RightHandIndex" not in dp:
            continue
        vals[dp][fc.array_index] = fc.evaluate(frame)
    n = 0
    for dp, comps in vals.items():
        name = dp.split('pose.bones["', 1)[1].split('"]', 1)[0]
        prop = dp.rsplit(".", 1)[-1]
        pb = arm.pose.bones.get(name)
        if pb is None or prop != "rotation_quaternion":
            continue
        pb.rotation_mode = "QUATERNION"
        q = [comps.get(i, 0.0) for i in range(4)]
        if q[0] == 0 and q[1] == 0 and q[2] == 0 and q[3] == 0:
            q[0] = 1.0
        pb.rotation_quaternion = q
        n += 1
    bpy.context.view_layer.update()
    print(f"[WeaponCalib] restored Mixamo Right Index {n} @ {frame}")


def pad_in_hole(ak, pad: Vector, info: dict) -> bool:
    loc = _local_ak(ak, pad)
    y0, y1, z0, z1 = info["bbox"]
    return (
        X_HOLE[0] <= loc.x <= X_HOLE[1]
        and (y0 - 0.01) <= loc.y <= (y1 + 0.01)
        and (z0 - 0.01) <= loc.z <= (z1 + 0.01)
    )


def seat_index(well: Vector, bvh_ak, bvh_pal, max_per=(40.0, 24.0, 14.0)):
    """Drop pad onto the trigger; keep local X inside the guard thickness."""
    arm = bpy.data.objects["Armature"]
    ak = bpy.data.objects["AK_Body"]
    for j, cap in zip((1, 2, 3), max_per):
        pb = arm.pose.bones[f"mixamorig:RightHandIndex{j}"]
        pb.rotation_mode = "QUATERNION"
        d_now = (_index_pad(arm) - well).length
        if d_now * 100 <= 0.6:
            print(f"  index pad already on trigger {d_now*100:.1f}cm")
            break
        axes = [Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0))]
        best = None
        best_d = d_now
        q00 = pb.rotation_quaternion.copy()
        for axis in axes:
            for sign in (1.0, -1.0):
                pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q00
                bpy.context.view_layer.update()
                loc = _local_ak(ak, _index_pad(arm))
                tip = _bt(arm, "mixamorig:RightHandIndex4")
                in_pal, _ = _inside(bvh_pal, tip) if bvh_pal else (False, 9)
                in_ak, _ = _inside(bvh_ak, tip)
                d2 = (_index_pad(arm) - well).length
                pb.rotation_quaternion = q00
                if in_pal or in_ak or loc.x < X_HOLE[0] or loc.x > X_HOLE[1]:
                    continue
                if d2 < best_d - 0.00025:
                    best_d = d2
                    best = (axis.copy(), sign)
        bpy.context.view_layer.update()
        if best is None:
            print(f"  index j{j}: no improving axis (pad {d_now*100:.1f}cm)")
            continue
        axis, sign = best
        acc = 0.0
        while acc + STEP_DEG <= cap:
            q0 = pb.rotation_quaternion.copy()
            pb.rotation_quaternion = Quaternion(axis, math.radians(STEP_DEG) * sign) @ q0
            bpy.context.view_layer.update()
            loc = _local_ak(ak, _index_pad(arm))
            tip = _bt(arm, "mixamorig:RightHandIndex4")
            in_pal, _ = _inside(bvh_pal, tip) if bvh_pal else (False, 9)
            in_ak, _ = _inside(bvh_ak, tip)
            d2 = (_index_pad(arm) - well).length
            if in_pal or in_ak or loc.x < X_HOLE[0] or loc.x > X_HOLE[1] or d2 > d_now + 0.001:
                pb.rotation_quaternion = q0
                bpy.context.view_layer.update()
                break
            acc += STEP_DEG
            d_now = d2
            if d_now * 100 <= 0.6:
                break
        print(f"  index j{j}: curl {acc:.0f}deg -> pad_trig {d_now*100:.1f}cm")


def run():
    mute_finger_ik()
    frame = int(bpy.context.scene.frame_current)
    restore_right_index(frame)
    ak = bpy.data.objects["AK_Body"]
    arm = bpy.data.objects["Armature"]
    mesh = bpy.data.objects["SoldadoMesh"]
    info = detect_trigger_well(ak)
    well = info["world"]
    _place_debug(well)
    print(
        f"[WeaponCalib] trigger well world={[round(x, 3) for x in well]} "
        f"local={[round(x, 3) for x in info['local']]} "
        f"opening_z_cm={info['gap_cm']:.1f} cells={info['n_cells']}"
    )
    pad = _index_pad(arm)
    print(
        f"[WeaponCalib] index pad before {round((pad - well).length * 100, 1)}cm "
        f"in_hole={pad_in_hole(ak, pad, info)}"
    )
    _, _, _, bvh_ak = _bvh_world(ak)
    ev, me, bvh_pal = _palm_bvh(mesh, False)
    seat_index(well, bvh_ak, bvh_pal)
    print("[WeaponCalib] embrace mango (middle/ring/pinky/thumb)")
    for f in ("Thumb", "Middle", "Ring", "Pinky"):
        curl_finger(
            "Right",
            f,
            bvh_ak,
            bvh_pal,
            max_per=(36.0, 20.0, 10.0),
            contact_cm=1.0,
            allow_y=(f == "Thumb"),
        )
    ev.to_mesh_clear()
    pad = _index_pad(arm)
    loc = _local_ak(ak, pad)
    print(
        f"[WeaponCalib] index pad after {round((pad - well).length * 100, 1)}cm "
        f"local={[round(x, 3) for x in loc]} in_hole={pad_in_hole(ak, pad, info)}"
    )
    diagnose()
    bpy.ops.wm.save_mainfile()
    print("[WeaponCalib] saved", bpy.data.filepath)


if __name__ == "__main__":
    run()
