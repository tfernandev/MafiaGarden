"""5-layer rifle-hold validator for the Blender lab.

Layers: geometry, contact, anatomy, temporal, regression.
Source of truth = evaluated mesh + bones. Screenshots are FAIL extras only.

Run in Blender MCP:
  runpy.run_path(..., run_name='__main__')   # static + sweep + regression
  runpy.run_path(..., run_name='autoseat')   # current frame + optional inside push
"""
from __future__ import annotations

import json
import math
import os
from datetime import datetime, timezone

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------
PALMA, DEDOS, PULGAR = "HANDCOL_Palma", "HANDCOL_Dedos", "HANDCOL_Pulgar"
MANGO, HG, CULATA, MIRA = "AKCOL_Mango", "AKCOL_Guardamanos", "AKCOL_Culata", "AKCOL_Mira"
FINGERS = ("Thumb", "Index", "Middle", "Ring", "Pinky")
ANIMS = (
    ("IdleSoldado", "Idle"),
    ("WalkingSoldado", "Walk"),
    ("FiringRifleSoldado", "Fire"),
)
TRANSITIONS = (
    ("IdleSoldado", "WalkingSoldado"),
    ("WalkingSoldado", "FiringRifleSoldado"),
    ("IdleSoldado", "FiringRifleSoldado"),
    ("FiringRifleSoldado", "IdleSoldado"),
    ("WalkingSoldado", "IdleSoldado"),
    ("FiringRifleSoldado", "WalkingSoldado"),
)

# ---------------------------------------------------------------------------
# Thresholds (calibrate here, not in the report)
# ---------------------------------------------------------------------------
PALM_ON_MIN = 70.0
INSIDE_MAX = 12.0
THUMB_INSIDE_MAX = 20.0
CULATA_IN_MAX = 8
WRAP_MIN = 60.0
WRAP_AZIMUTH_DEG = 40.0
GRIP_ERR_PASS = 1.5  # cm
GRIP_ERR_WARN = 3.0
PALM_ANG_PASS = 20.0
PALM_ANG_WARN = 35.0
ELBOW_FOLD_FAIL = 15.0
ELBOW_FOLD_WARN = 30.0
ELBOW_EXT_WARN = 160.0
ELBOW_EXT_FAIL = 175.0
REACH_SLACK = 1.02
STOCK_PASS = 8.0  # cm
STOCK_WARN = 18.0
CHEST_MIN = 3.0  # cm
CHEST_MAX_WARN = 25.0
CHEST_MAX_FAIL = 35.0
SIGHT_WARN = 25.0  # deg, Fire only
SIGHT_FAIL = 45.0
FIRE_PITCH_LO = 15.0
FIRE_PITCH_HI = 40.0
JITTER_WARN_CM = 4.0
JITTER_FAIL_CM = 10.0
GRIP_DRIFT_WARN = 2.0
GRIP_DRIFT_FAIL = 6.0
RIGID_FAIL_CM = 0.8
SEAM_WARN_CM = 5.0
SEAM_FAIL_CM = 15.0
SHOULDER_ELEV_WARN = 55.0
SHOULDER_ELEV_FAIL = 80.0

OUT_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..",
    "calib_shots",
    "hold_validate",
)
BASELINE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hold_validate_baseline.json")


def _f(x) -> float:
    return round(float(x), 4)


def _mat_i(obj, name: str) -> int:
    for i, m in enumerate(obj.data.materials):
        if m and m.name == name:
            return i
    raise RuntimeError(name)


def _bw(arm, name: str) -> Vector:
    return arm.matrix_world @ arm.pose.bones[name].head


def _bt(arm, name: str) -> Vector:
    return arm.matrix_world @ arm.pose.bones[name].tail


def _deg(a: Vector, b: Vector) -> float:
    if a.length < 1e-8 or b.length < 1e-8:
        return 180.0
    return math.degrees(a.angle(b))


def _status_grip_cm(cm: float) -> str:
    if cm < GRIP_ERR_PASS:
        return "PASS"
    if cm < GRIP_ERR_WARN:
        return "WARN"
    return "FAIL"


def _status_ang(deg: float, lo_pass: float, lo_warn: float) -> str:
    if deg < lo_pass:
        return "PASS"
    if deg < lo_warn:
        return "WARN"
    return "FAIL"


def _status_on(pct: float, mn: float) -> str:
    return "PASS" if pct >= mn else "FAIL"


def _status_inside(pct: float, cap: float) -> str:
    return "PASS" if pct <= cap else "FAIL"


def _worse(a: str, b: str) -> str:
    rank = {"PASS": 0, "WARN": 1, "FAIL": 2, "INFO": -1}
    return a if rank.get(a, 0) >= rank.get(b, 0) else b


def _score_status(st: str) -> float:
    return {"PASS": 0.0, "INFO": 0.0, "WARN": 0.35, "FAIL": 1.0}.get(st, 0.0)


def _ak_bvh():
    ak = bpy.data.objects["AK_Body"]
    deps = bpy.context.evaluated_depsgraph_get()
    eak = ak.evaluated_get(deps)
    me = eak.to_mesh()
    mw = eak.matrix_world
    bvh = BVHTree.FromPolygons(
        [mw @ v.co for v in me.vertices],
        [list(p.vertices) for p in me.polygons],
        epsilon=0.0,
    )
    mats = []
    for p in me.polygons:
        mat = ""
        if p.material_index < len(ak.data.materials) and ak.data.materials[p.material_index]:
            mat = ak.data.materials[p.material_index].name
        mats.append(mat)
    return ak, eak, me, mw, bvh, mats


def _centroid_mat(obj, mat: str) -> Vector:
    mi = _mat_i(obj, mat)
    acc = Vector()
    area = 0.0
    for poly in obj.data.polygons:
        if poly.material_index != mi:
            continue
        c = Vector()
        for vi in poly.vertices:
            c += obj.data.vertices[vi].co
        w = obj.matrix_world @ (c / len(poly.vertices))
        acc += w * poly.area
        area += poly.area
    return acc / max(1e-9, area)


def _zone_centers(me, mw, mat_idx: int):
    out = []
    for poly in me.polygons:
        if poly.material_index != mat_idx:
            continue
        c = Vector()
        for vi in poly.vertices:
            c += me.vertices[vi].co
        n = (mw.to_3x3() @ poly.normal).normalized()
        out.append((mw @ (c / len(poly.vertices)), n, poly.area))
    return out


def _polar(p: Vector, axis_p: Vector, axis_d: Vector) -> Vector:
    v = p - axis_p
    return v - axis_d * v.dot(axis_d)


def measure_frame() -> dict:
    """All geometry/contact/anatomy metrics at the current evaluated frame."""
    ak, eak, meak, mwa, bvh, poly_mat = _ak_bvh()
    mesh = bpy.data.objects["SoldadoMesh"]
    arm = bpy.data.objects["Armature"]
    grip = bpy.data.objects["Grip"]
    deps = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(deps)
    me = ev.to_mesh()
    mw = ev.matrix_world
    rh = _bw(arm, "mixamorig:RightHand")
    lh = _bw(arm, "mixamorig:LeftHand")
    matn = [m.name if m else "" for m in mesh.data.materials]
    gat = bpy.data.objects["DEBUG_Trigger_Mango"].matrix_world.translation
    hg_pt = bpy.data.objects["DEBUG_Guardamanos"].matrix_world.translation
    mz = bpy.data.objects["DEBUG_Punta_Disparo"].matrix_world.translation
    barrel = (mz - gat).normalized()
    down = (grip.matrix_world.to_3x3() @ Vector((0, 1, 0))).normalized()
    if down.z > 0:
        down = -down
    mango_c = _centroid_mat(ak, MANGO)
    hg_c = _centroid_mat(ak, HG)
    culata_c = _centroid_mat(ak, CULATA)
    try:
        mira_c = _centroid_mat(ak, MIRA)
    except RuntimeError:
        mira_c = mz

    def nearest(p: Vector):
        loc, nrm, idx, dist = bvh.find_nearest(p)
        n = Vector(nrm).normalized()
        inside = (p - loc).dot(n) < -0.001
        return poly_mat[idx], dist, inside, Vector(loc), n

    def split_side(p: Vector) -> str:
        return "L" if (p - lh).length < (p - rh).length else "R"

    zones = {}
    for zname, want_r, want_l in (
        (PALMA, MANGO, HG),
        (DEDOS, MANGO, HG),
        (PULGAR, MANGO, HG),
    ):
        idx = matn.index(zname)
        for tag, want, is_l in (("R", want_r, False), ("L", want_l, True)):
            n = on = inn = 0
            ds = 0.0
            acc = Vector()
            nacc = Vector()
            for poly in me.polygons:
                if poly.material_index != idx:
                    continue
                c = Vector()
                for vi in poly.vertices:
                    c += me.vertices[vi].co
                p = mw @ (c / len(poly.vertices))
                if ((p - lh).length < (p - rh).length) != is_l:
                    continue
                am, dist, inside, _, nrm = nearest(p)
                n += 1
                ds += dist
                acc += p
                nacc += (mw.to_3x3() @ poly.normal).normalized()
                if inside:
                    inn += 1
                if am == want:
                    on += 1
            key = f"{zname}_{tag}"
            zones[key] = {
                "n": n,
                "on": _f(on / max(1, n) * 100),
                "inside": _f(inn / max(1, n) * 100),
                "mean_cm": _f(ds / max(1, n) * 100),
                "centroid": (acc / max(1, n)) if n else Vector(),
                "normal": nacc.normalized() if nacc.length > 1e-8 else Vector((0, 0, 1)),
            }

    palm_r = zones[f"{PALMA}_R"]["centroid"]
    palm_l = zones[f"{PALMA}_L"]["centroid"]
    n_r = zones[f"{PALMA}_R"]["normal"]
    n_l = zones[f"{PALMA}_L"]["normal"]

    # contact error: palm centroid → dedicated grip markers + nearest surface
    _, dist_r, _, loc_r, _ = nearest(palm_r) if zones[f"{PALMA}_R"]["n"] else ("", 9, False, gat, Vector())
    _, dist_l, _, loc_l, _ = nearest(palm_l) if zones[f"{PALMA}_L"]["n"] else ("", 9, False, hg_pt, Vector())
    grip_err_r = (palm_r - gat).length * 100.0
    grip_err_l = (palm_l - hg_pt).length * 100.0
    surf_err_r = dist_r * 100.0
    surf_err_l = dist_l * 100.0

    # palm orientation from the hand bone (mesh-average normals are ~orthogonal on a curved palm)
    def palm_bone_ang(side: str, toward: Vector) -> float:
        hm = (arm.matrix_world @ arm.pose.bones[f"mixamorig:{side}Hand"].matrix).to_3x3()
        best = 180.0
        for ax in (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))):
            w = hm @ ax
            best = min(best, _deg(w, toward), _deg(-w, toward))
        return best

    ang_r = palm_bone_ang("Right", gat - rh)
    ang_l = palm_bone_ang("Left", hg_pt - lh)
    fwd_r = _bt(arm, "mixamorig:RightHand") - rh
    fwd_l = _bt(arm, "mixamorig:LeftHand") - lh
    barrel_align_r = _deg(fwd_r, barrel)
    barrel_align_l = _deg(fwd_l, barrel)

    def order_ok(wrist: Vector, palm: Vector, grip_pt: Vector) -> dict:
        axis = grip_pt - wrist
        L = axis.length
        if L < 1e-6:
            return {"t": 0.0, "status": "FAIL", "cm_off_axis": 99.0}
        t = (palm - wrist).dot(axis) / (L * L)
        closest = wrist + axis * t
        off = (palm - closest).length * 100.0
        st = "PASS" if 0.12 <= t <= 0.92 and off < 8.0 else ("WARN" if 0.0 <= t <= 1.05 and off < 14.0 else "FAIL")
        return {"t": _f(t), "status": st, "cm_off_axis": _f(off)}

    order_r = order_ok(rh, palm_r, gat)
    order_l = order_ok(lh, palm_l, hg_pt)

    def wrap_hand(palm: Vector, axis_p: Vector, axis_d: Vector, side: str) -> dict:
        n0 = _polar(palm, axis_p, axis_d)
        n0 = n0.normalized() if n0.length > 1e-6 else Vector((1, 0, 0))
        rows = []
        ok = 0
        for f in FINGERS:
            p = _bt(arm, f"mixamorig:{side}Hand{f}4")
            am, dist, inside, _, _ = nearest(p)
            rt = _polar(p, axis_p, axis_d)
            if rt.length < 1e-6:
                ang = 0.0
            else:
                ang = math.degrees(
                    math.atan2(n0.cross(rt.normalized()).dot(axis_d), n0.dot(rt.normalized()))
                )
            wrapped = abs(ang) >= WRAP_AZIMUTH_DEG
            ok += int(wrapped)
            rows.append(
                {
                    "finger": f,
                    "az": _f(ang),
                    "wrap": wrapped,
                    "dist_cm": _f(dist * 100),
                    "inside": bool(inside),
                    "on_part": am,
                    "status": "FAIL" if inside and dist > 0.002 else ("PASS" if wrapped or f == "Thumb" and abs(ang) >= 20 else ("WARN" if abs(ang) >= 25 else "FAIL")),
                }
            )
        return {"frac": _f(ok / 5.0 * 100), "fingers": rows}

    wrap_r = wrap_hand(palm_r, mango_c, down, "Right")
    wrap_l = wrap_hand(palm_l, hg_c, barrel, "Left")
    # thumb along barrel on support hand is OK
    for row in wrap_l["fingers"]:
        if row["finger"] == "Thumb" and not row["wrap"] and row["dist_cm"] < 4.0:
            row["status"] = "PASS"

    # culata in body
    bvh_b = BVHTree.FromPolygons(
        [mw @ v.co for v in me.vertices],
        [list(p.vertices) for p in me.polygons],
        epsilon=0.0,
    )
    mi_c = _mat_i(ak, CULATA)
    n_in = n_tot = 0
    for poly in ak.data.polygons:
        if poly.material_index != mi_c:
            continue
        c = Vector()
        for vi in poly.vertices:
            c += ak.data.vertices[vi].co
        w = ak.matrix_world @ (c / len(poly.vertices))
        n_tot += 1
        loc, nrm, _, _ = bvh_b.find_nearest(w)
        if loc is not None and (w - loc).dot(Vector(nrm).normalized()) < -0.002:
            n_in += 1

    chest = _bw(arm, "mixamorig:Spine2")
    rifle_c = (mango_c + hg_c) * 0.5
    chest_cm = (rifle_c - chest).length * 100.0
    sh_r = _bw(arm, "mixamorig:RightArm")  # glenohumeral, not clavicle origin
    stock_cm = 99.0
    mi_stock = _mat_i(ak, CULATA)
    for poly in ak.data.polygons:
        if poly.material_index != mi_stock:
            continue
        c = Vector()
        for vi in poly.vertices:
            c += ak.data.vertices[vi].co
        w = ak.matrix_world @ (c / len(poly.vertices))
        d = (w - sh_r).length * 100.0
        if d < stock_cm:
            stock_cm = d

    def elbow(side: str) -> dict:
        sh = _bw(arm, f"mixamorig:{side}Arm")
        el = _bw(arm, f"mixamorig:{side}ForeArm")
        wr = _bw(arm, f"mixamorig:{side}Hand")
        ang = _deg(sh - el, wr - el)
        if ang < ELBOW_FOLD_FAIL or ang > ELBOW_EXT_FAIL:
            st = "FAIL"
        elif ang < ELBOW_FOLD_WARN or ang > ELBOW_EXT_WARN:
            st = "WARN"
        else:
            st = "PASS"
        db = arm.data.bones
        scale = sum(arm.matrix_world.to_scale()) / 3.0
        L = (db[f"mixamorig:{side}Arm"].length + db[f"mixamorig:{side}ForeArm"].length) * scale
        tgt_name = "IK_Wrist_Derecha" if side == "Right" else "IK_Wrist_Izquierda"
        tgt = bpy.data.objects[tgt_name].matrix_world.translation if tgt_name in bpy.data.objects else wr
        reach = (tgt - sh).length
        ik_err = (wr - tgt).length * 100.0
        unreach = reach > L * REACH_SLACK
        return {
            "angle": _f(ang),
            "status": st,
            "reach_cm": _f(reach * 100),
            "max_cm": _f(L * 100),
            "unreachable": unreach,
            "ik_err_cm": _f(ik_err),
            "ik_status": "FAIL" if unreach else ("WARN" if ik_err > 3.0 else "PASS"),
        }

    el_r = elbow("Right")
    el_l = elbow("Left")

    def shoulder(side: str) -> dict:
        spine = _bw(arm, "mixamorig:Spine2")
        sh = _bw(arm, f"mixamorig:{side}Shoulder")
        arm_p = _bw(arm, f"mixamorig:{side}Arm")
        up = Vector((0, 0, 1))
        elev = 90.0 - _deg(arm_p - sh, up)
        # 0 = arm hanging down, 90 = T-pose
        open_ang = _deg(sh - spine, arm_p - sh)
        if abs(elev) > SHOULDER_ELEV_FAIL:
            st = "FAIL"
        elif abs(elev) > SHOULDER_ELEV_WARN:
            st = "WARN"
        else:
            st = "PASS"
        return {"elev_deg": _f(elev), "open_deg": _f(open_ang), "status": st}

    # muzzle / body
    spine_f = (_bt(arm, "mixamorig:Spine2") - _bw(arm, "mixamorig:Spine2"))
    if spine_f.length < 1e-6:
        spine_f = Vector((0, -1, 0))
    pitch = math.degrees(math.asin(max(-1.0, min(1.0, barrel.z))))
    yaw_body = _deg(Vector((barrel.x, barrel.y, 0.0)), Vector((spine_f.x, spine_f.y, 0.0)))
    head = _bw(arm, "mixamorig:Head")
    v_eye = mira_c - head
    v_sight = mz - mira_c
    sight_ang = _deg(v_eye, v_sight)

    # weapon rigid internals (current snapshot; compared across time in sweep)
    fg = bpy.data.objects["Foregrip"].matrix_world.translation
    rigid = {
        "grip_foregrip_cm": _f((grip.matrix_world.translation - fg).length * 100),
        "grip_muzzle_cm": _f((grip.matrix_world.translation - mz).length * 100),
        "trigger_muzzle_cm": _f((gat - mz).length * 100),
        "scale": [_f(x) for x in ak.matrix_world.to_scale()],
    }

    # setup
    parent = grip.parent.name if grip.parent else None
    pb = arm.pose.bones["mixamorig:RightHand"]
    ik_mute = pb.constraints["IK_mano"].mute if "IK_mano" in pb.constraints else True

    # wrist relative to grip (consistency)
    ginv = grip.matrix_world.inverted()
    rel_r = ginv @ rh
    rel_l = ginv @ lh

    # culata / chest statuses
    if chest_cm < CHEST_MIN:
        chest_st = "FAIL"
    elif chest_cm > CHEST_MAX_FAIL:
        chest_st = "FAIL"
    elif chest_cm > CHEST_MAX_WARN:
        chest_st = "WARN"
    else:
        chest_st = "PASS"
    if stock_cm < STOCK_PASS:
        stock_st = "PASS"
    elif stock_cm < STOCK_WARN:
        stock_st = "WARN"
    else:
        stock_st = "FAIL"

    scene = bpy.context.scene
    out = {
        "file": bpy.data.filepath,
        "frame": int(scene.frame_current),
        "action": arm.animation_data.action.name if arm.animation_data and arm.animation_data.action else None,
        "setup": {
            "grip_parent": parent,
            "grip_parent_type": grip.parent_type,
            "right_ik_mute": bool(ik_mute),
            "world_locked": parent == "AK_Lock",
        },
        "zones": {
            k: {sk: sv for sk, sv in v.items() if sk not in ("centroid", "normal")}
            for k, v in zones.items()
        },
        "culata_in": n_in,
        "culata_n": n_tot,
        "contact": {
            "right_grip_err_cm": _f(grip_err_r),
            "left_grip_err_cm": _f(grip_err_l),
            "right_surf_cm": _f(surf_err_r),
            "left_surf_cm": _f(surf_err_l),
            "right_status": _status_grip_cm(min(grip_err_r, surf_err_r)),
            "left_status": _status_grip_cm(min(grip_err_l, surf_err_l)),
        },
        "orient": {
            "right_palm_deg": _f(ang_r),
            "left_palm_deg": _f(ang_l),
            "right_status": _status_ang(ang_r, PALM_ANG_PASS, PALM_ANG_WARN),
            "left_status": _status_ang(ang_l, PALM_ANG_PASS, PALM_ANG_WARN),
            "right_barrel_deg": _f(barrel_align_r),
            "left_barrel_deg": _f(barrel_align_l),
        },
        "order": {"right": order_r, "left": order_l},
        "wrap": {
            "right": wrap_r["frac"],
            "left": wrap_l["frac"],
            "right_fingers": wrap_r["fingers"],
            "left_fingers": wrap_l["fingers"],
        },
        "anatomy": {
            "right_elbow": el_r,
            "left_elbow": el_l,
            "right_shoulder": shoulder("Right"),
            "left_shoulder": shoulder("Left"),
        },
        "stock": {
            "shoulder_cm": _f(stock_cm),
            "chest_cm": _f(chest_cm),
            "shoulder_status": stock_st,
            "chest_status": chest_st,
        },
        "aim": {
            "pitch_deg": _f(pitch),
            "yaw_body_deg": _f(yaw_body),
            "sight_deg": _f(sight_ang),
        },
        "rigid": rigid,
        "rel_hand": {
            "right": [_f(x) for x in rel_r],
            "left": [_f(x) for x in rel_l],
        },
        "hands_world": {
            "right": [_f(x) for x in rh],
            "left": [_f(x) for x in lh],
            "grip": [_f(x) for x in grip.matrix_world.translation],
        },
    }
    ev.to_mesh_clear()
    eak.to_mesh_clear()
    return out


def verdict_frame(m: dict, *, fire: bool = False) -> dict:
    checks = []

    def add(layer: str, name: str, status: str, **extra):
        row = {"layer": layer, "name": name, "status": status}
        row.update(extra)
        checks.append(row)

    z = m["zones"]
    add("contact", "palm_R_on_mango", _status_on(z[f"{PALMA}_R"]["on"], PALM_ON_MIN), pct=z[f"{PALMA}_R"]["on"])
    add("contact", "palm_L_on_handguard", _status_on(z[f"{PALMA}_L"]["on"], PALM_ON_MIN), pct=z[f"{PALMA}_L"]["on"])
    for k, cap in (
        (f"{PALMA}_R", INSIDE_MAX),
        (f"{PALMA}_L", INSIDE_MAX),
        (f"{DEDOS}_R", INSIDE_MAX),
        (f"{DEDOS}_L", INSIDE_MAX),
        (f"{PULGAR}_R", THUMB_INSIDE_MAX),
        (f"{PULGAR}_L", THUMB_INSIDE_MAX),
    ):
        add("geometry", f"{k}_inside", _status_inside(z[k]["inside"], cap), pct=z[k]["inside"])
    add(
        "geometry",
        "culata_in_torso",
        "FAIL" if m["culata_in"] > CULATA_IN_MAX else "PASS",
        n=m["culata_in"],
    )
    add("contact", "wrap_R", _status_on(m["wrap"]["right"], WRAP_MIN), pct=m["wrap"]["right"])
    add("contact", "wrap_L", _status_on(m["wrap"]["left"], WRAP_MIN), pct=m["wrap"]["left"])
    add("contact", "right_grip_err", m["contact"]["right_status"], cm=m["contact"]["right_grip_err_cm"])
    add("contact", "left_grip_err", m["contact"]["left_status"], cm=m["contact"]["left_grip_err_cm"])
    add("contact", "right_palm_orient", m["orient"]["right_status"], deg=m["orient"]["right_palm_deg"])
    add("contact", "left_palm_orient", m["orient"]["left_status"], deg=m["orient"]["left_palm_deg"])
    add("anatomy", "wrist_palm_grip_R", m["order"]["right"]["status"], t=m["order"]["right"]["t"])
    add("anatomy", "wrist_palm_grip_L", m["order"]["left"]["status"], t=m["order"]["left"]["t"])
    add("anatomy", "right_elbow", m["anatomy"]["right_elbow"]["status"], deg=m["anatomy"]["right_elbow"]["angle"])
    add("anatomy", "left_elbow", m["anatomy"]["left_elbow"]["status"], deg=m["anatomy"]["left_elbow"]["angle"])
    add("anatomy", "right_ik_reach", m["anatomy"]["right_elbow"]["ik_status"], cm=m["anatomy"]["right_elbow"]["reach_cm"])
    add("anatomy", "left_ik_reach", m["anatomy"]["left_elbow"]["ik_status"], cm=m["anatomy"]["left_elbow"]["reach_cm"])
    add("anatomy", "right_shoulder", m["anatomy"]["right_shoulder"]["status"], deg=m["anatomy"]["right_shoulder"]["elev_deg"])
    add("anatomy", "left_shoulder", m["anatomy"]["left_shoulder"]["status"], deg=m["anatomy"]["left_shoulder"]["elev_deg"])
    add("geometry", "stock_shoulder", m["stock"]["shoulder_status"], cm=m["stock"]["shoulder_cm"])
    add("geometry", "rifle_chest", m["stock"]["chest_status"], cm=m["stock"]["chest_cm"])
    if fire:
        pitch = m["aim"]["pitch_deg"]
        pst = "PASS" if FIRE_PITCH_LO <= pitch <= FIRE_PITCH_HI else "WARN"
        add("geometry", "muzzle_pitch_fire", pst, deg=pitch)
        sag = m["aim"]["sight_deg"]
        if "DEBUG_Eye" in bpy.data.objects:
            sst = "PASS" if sag < SIGHT_WARN else ("WARN" if sag < SIGHT_FAIL else "FAIL")
        else:
            sst = "INFO"
        add("geometry", "head_sight", sst, deg=sag)
    else:
        add("geometry", "muzzle_pitch", "INFO", deg=m["aim"]["pitch_deg"])
        add("geometry", "head_sight", "INFO", deg=m["aim"]["sight_deg"])

    for side in ("right", "left"):
        for row in m["wrap"][f"{side}_fingers"]:
            add("contact", f"finger_{side}_{row['finger']}", row["status"], az=row["az"], cm=row["dist_cm"])

    overall = "PASS"
    score = 0.0
    for c in checks:
        overall = _worse(overall, c["status"] if c["status"] != "INFO" else "PASS")
        score += _score_status(c["status"])
    fails = [c["name"] for c in checks if c["status"] == "FAIL"]
    warns = [c["name"] for c in checks if c["status"] == "WARN"]
    return {"status": overall, "score": _f(score), "fails": fails, "warns": warns, "checks": checks}


def push_inside_fingertips(pad=0.02):
    arm = bpy.data.objects["Armature"]
    _, eak, meak, mwa, bvh, _ = _ak_bvh()
    for side in ("Right", "Left"):
        for f in FINGERS:
            pb = arm.pose.bones[f"mixamorig:{side}Hand{f}4"]
            p = arm.matrix_world @ pb.tail
            loc, nrm, _, _ = bvh.find_nearest(p)
            n = Vector(nrm).normalized()
            if (p - loc).dot(n) < 0.008:
                name = f"IK_Dedo_{side}_{f}"
                if name in bpy.data.objects:
                    bpy.data.objects[name].matrix_world.translation = loc + n * pad
    eak.to_mesh_clear()
    bpy.context.view_layer.update()


def _set_action(arm, action_name: str):
    ad = arm.animation_data
    if ad is None:
        arm.animation_data_create()
        ad = arm.animation_data
    for t in ad.nla_tracks:
        t.mute = True
    ad.action = bpy.data.actions[action_name]


def _action_range(name: str):
    a = bpy.data.actions[name]
    lo, hi = a.frame_range
    return int(lo), int(hi)


def _sample_frames(lo: int, hi: int, step: int | None = None) -> list[int]:
    if step is None:
        span = max(1, hi - lo)
        step = max(1, span // 8)
    frames = list(range(lo, hi + 1, step))
    if frames[-1] != hi:
        frames.append(hi)
    return frames


def sweep_action(action_name: str, label: str) -> dict:
    arm = bpy.data.objects["Armature"]
    scene = bpy.context.scene
    _set_action(arm, action_name)
    lo, hi = _action_range(action_name)
    frames = _sample_frames(lo, hi)
    samples = []
    fire = label == "Fire"
    for f in frames:
        scene.frame_set(f)
        bpy.context.view_layer.update()
        m = measure_frame()
        v = verdict_frame(m, fire=fire)
        samples.append({"frame": f, "measure": m, "verdict": v})
    # jitter + grip consistency + rigid drift
    spikes = []
    drifts = []
    rigid_fail = []
    if samples:
        r0 = samples[0]["measure"]["rel_hand"]["right"]
        l0 = samples[0]["measure"]["rel_hand"]["left"]
        rig0 = samples[0]["measure"]["rigid"]
        for i in range(1, len(samples)):
            a = samples[i - 1]["measure"]
            b = samples[i]["measure"]
            wr = Vector(a["hands_world"]["right"])
            wr2 = Vector(b["hands_world"]["right"])
            wl = Vector(a["hands_world"]["left"])
            wl2 = Vector(b["hands_world"]["left"])
            dR = (wr2 - wr).length * 100
            dL = (wl2 - wl).length * 100
            dt = max(1, samples[i]["frame"] - samples[i - 1]["frame"])
            # per-frame equivalent
            if dR / dt > JITTER_FAIL_CM or dL / dt > JITTER_FAIL_CM:
                st = "FAIL"
            elif dR / dt > JITTER_WARN_CM or dL / dt > JITTER_WARN_CM:
                st = "WARN"
            else:
                st = "PASS"
            if st != "PASS":
                spikes.append(
                    {
                        "from": samples[i - 1]["frame"],
                        "to": samples[i]["frame"],
                        "dR_cm": _f(dR),
                        "dL_cm": _f(dL),
                        "status": st,
                    }
                )
            rel_r = Vector(b["rel_hand"]["right"]) - Vector(r0)
            rel_l = Vector(b["rel_hand"]["left"]) - Vector(l0)
            drift = max(rel_r.length, rel_l.length) * 100
            dst = "PASS" if drift < GRIP_DRIFT_WARN else ("WARN" if drift < GRIP_DRIFT_FAIL else "FAIL")
            if dst != "PASS":
                drifts.append({"frame": samples[i]["frame"], "cm": _f(drift), "status": dst})
            for k in ("grip_foregrip_cm", "grip_muzzle_cm", "trigger_muzzle_cm"):
                if abs(b["rigid"][k] - rig0[k]) > RIGID_FAIL_CM:
                    rigid_fail.append({"frame": samples[i]["frame"], "k": k, "a": rig0[k], "b": b["rigid"][k]})
    worst = max(samples, key=lambda s: s["verdict"]["score"]) if samples else None
    n_pass = sum(1 for s in samples if s["verdict"]["status"] == "PASS")
    n_fail = sum(1 for s in samples if s["verdict"]["status"] == "FAIL")
    n_warn = sum(1 for s in samples if s["verdict"]["status"] == "WARN")
    overall = "FAIL" if n_fail else ("WARN" if n_warn else "PASS")
    if spikes and any(x["status"] == "FAIL" for x in spikes):
        overall = "FAIL"
    if rigid_fail:
        overall = "FAIL"
    heatmap = "".join(
        {"PASS": "o", "WARN": ".", "FAIL": "X"}.get(s["verdict"]["status"], "?") for s in samples
    )
    pct = 100.0 * n_pass / max(1, len(samples))
    return {
        "action": action_name,
        "label": label,
        "frames": [s["frame"] for s in samples],
        "heatmap": heatmap,
        "pass_pct": _f(pct),
        "status": overall,
        "n_pass": n_pass,
        "n_warn": n_warn,
        "n_fail": n_fail,
        "spikes": spikes,
        "drifts": drifts,
        "rigid_fail": rigid_fail,
        "worst": {
            "frame": worst["frame"],
            "status": worst["verdict"]["status"],
            "score": worst["verdict"]["score"],
            "fails": worst["verdict"]["fails"],
            "warns": worst["verdict"]["warns"],
            "contact": worst["measure"]["contact"],
            "anatomy": {
                "right_elbow": worst["measure"]["anatomy"]["right_elbow"]["angle"],
                "left_elbow": worst["measure"]["anatomy"]["left_elbow"]["angle"],
            },
            "zones": worst["measure"]["zones"],
            "wrap": {"right": worst["measure"]["wrap"]["right"], "left": worst["measure"]["wrap"]["left"]},
        }
        if worst
        else None,
        "samples": samples,
    }


def sweep_transitions() -> list[dict]:
    arm = bpy.data.objects["Armature"]
    scene = bpy.context.scene
    rows = []
    for a, b in TRANSITIONS:
        _set_action(arm, a)
        lo, hi = _action_range(a)
        scene.frame_set(hi)
        bpy.context.view_layer.update()
        ma = measure_frame()
        _set_action(arm, b)
        lo2, _ = _action_range(b)
        scene.frame_set(lo2)
        bpy.context.view_layer.update()
        mb = measure_frame()
        dR = (Vector(mb["hands_world"]["right"]) - Vector(ma["hands_world"]["right"])).length * 100
        dL = (Vector(mb["hands_world"]["left"]) - Vector(ma["hands_world"]["left"])).length * 100
        dG = (Vector(mb["hands_world"]["grip"]) - Vector(ma["hands_world"]["grip"])).length * 100
        jump = max(dR, dL, dG)
        st = "PASS" if jump < SEAM_WARN_CM else ("WARN" if jump < SEAM_FAIL_CM else "FAIL")
        rows.append(
            {
                "from": a,
                "to": b,
                "dR_cm": _f(dR),
                "dL_cm": _f(dL),
                "dG_cm": _f(dG),
                "status": st,
            }
        )
    return rows


def _worst_list(sweeps: list[dict], n=5) -> list[dict]:
    items = []
    for sw in sweeps:
        for s in sw["samples"]:
            items.append(
                {
                    "anim": sw["label"],
                    "frame": s["frame"],
                    "status": s["verdict"]["status"],
                    "score": s["verdict"]["score"],
                    "fails": s["verdict"]["fails"][:8],
                    "left_grip_cm": s["measure"]["contact"]["left_grip_err_cm"],
                    "right_grip_cm": s["measure"]["contact"]["right_grip_err_cm"],
                    "left_elbow": s["measure"]["anatomy"]["left_elbow"]["angle"],
                    "clip_R": s["measure"]["zones"][f"{DEDOS}_R"]["inside"],
                }
            )
    items.sort(key=lambda x: -x["score"])
    return items[:n]


def _write_snapshot(sw_label: str, sample: dict):
    os.makedirs(os.path.abspath(OUT_DIR), exist_ok=True)
    frame = sample["frame"]
    base = os.path.abspath(os.path.join(OUT_DIR, f"{sw_label}_frame_{frame:03d}"))
    payload = {
        "animation": sw_label,
        "frame": frame,
        "verdict": {k: sample["verdict"][k] for k in ("status", "score", "fails", "warns")},
        "contact": sample["measure"]["contact"],
        "wrap": {
            "right": sample["measure"]["wrap"]["right"],
            "left": sample["measure"]["wrap"]["left"],
            "right_fingers": sample["measure"]["wrap"]["right_fingers"],
            "left_fingers": sample["measure"]["wrap"]["left_fingers"],
        },
        "anatomy": sample["measure"]["anatomy"],
        "stock": sample["measure"]["stock"],
        "aim": sample["measure"]["aim"],
        "setup": sample["measure"]["setup"],
        "zones": sample["measure"]["zones"],
    }
    with open(base + ".json", "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    scene = bpy.context.scene
    prev = scene.render.filepath
    try:
        scene.render.filepath = base + ".jpg"
        scene.render.image_settings.file_format = "JPEG"
        bpy.ops.render.opengl(write_still=True)
        img = base + ".jpg"
    except Exception as e:
        img = f"opengl_fail:{e}"
    scene.render.filepath = prev
    return base + ".json", img


def _compact_sweep(sw: dict) -> dict:
    return {
        "label": sw["label"],
        "action": sw["action"],
        "status": sw["status"],
        "pass_pct": sw["pass_pct"],
        "heatmap": sw["heatmap"],
        "n_fail": sw["n_fail"],
        "n_warn": sw["n_warn"],
        "worst_frame": sw["worst"]["frame"] if sw["worst"] else None,
        "worst_fails": sw["worst"]["fails"] if sw["worst"] else [],
        "spikes": sw["spikes"],
        "drifts": sw["drifts"],
        "rigid_fail": sw["rigid_fail"],
    }


def regression_compare(report: dict) -> dict:
    compact = {
        "static_status": report["static"]["verdict"]["status"],
        "anims": {s["label"]: s["status"] for s in report["anims_compact"]},
        "fails": sorted(
            {f"{s['label']}:{name}" for s in report["anims_compact"] for name in s["worst_fails"]}
        ),
    }
    if not os.path.isfile(BASELINE_PATH):
        blob = {"created": datetime.now(timezone.utc).isoformat(), "compact": compact}
        with open(BASELINE_PATH, "w", encoding="utf-8") as f:
            json.dump(blob, f, indent=2)
        return {"status": "BASELINE_CREATED", "path": BASELINE_PATH, "compact": compact}
    with open(BASELINE_PATH, encoding="utf-8") as f:
        old = json.load(f)["compact"]
    broke = []
    for k, st in compact["anims"].items():
        prev = old.get("anims", {}).get(k, "PASS")
        if st == "FAIL" and prev != "FAIL":
            broke.append(f"{k}: {prev} -> {st}")
    if compact["static_status"] == "FAIL" and old.get("static_status") != "FAIL":
        broke.append(f"static: {old.get('static_status')} -> FAIL")
    new_fails = sorted(set(compact["fails"]) - set(old.get("fails", [])))
    return {
        "status": "FAIL" if broke or new_fails else "PASS",
        "broke": broke,
        "new_fails": new_fails,
        "path": BASELINE_PATH,
    }


def _bar(pct: float, width=10) -> str:
    n = int(round(pct / 100.0 * width))
    return "█" * n + "░" * (width - n)


def report_print(rep: dict):
    st = rep["static"]
    print("")
    print("╔════════════════════════════════════════════╗")
    print("║       WEAPON RIG VALIDATION                ║")
    print("╚════════════════════════════════════════════╝")
    print(f"File: {st['measure']['file']}")
    print(f"Setup: parent={st['measure']['setup']['grip_parent']}  world_locked={st['measure']['setup']['world_locked']}")
    print("")
    print("STATIC  frame", st["measure"]["frame"], st["measure"]["action"], st["verdict"]["status"])
    m = st["measure"]
    print(f"  Right hand contact   {m['contact']['right_status']:4}  {m['contact']['right_grip_err_cm']:.2f} cm  palm_on={m['zones'][f'{PALMA}_R']['on']:.1f}%")
    print(f"  Left hand contact    {m['contact']['left_status']:4}  {m['contact']['left_grip_err_cm']:.2f} cm  palm_on={m['zones'][f'{PALMA}_L']['on']:.1f}%")
    print(f"  Finger wrap          R {m['wrap']['right']:.0f}%  L {m['wrap']['left']:.0f}%")
    print(f"  Clipping palma/dedos R {m['zones'][f'{PALMA}_R']['inside']:.1f}%/{m['zones'][f'{DEDOS}_R']['inside']:.1f}%  L {m['zones'][f'{PALMA}_L']['inside']:.1f}%/{m['zones'][f'{DEDOS}_L']['inside']:.1f}%")
    print(f"  Culata/torso         {m['culata_in']}/{m['culata_n']}")
    print(f"  Stock/shoulder       {m['stock']['shoulder_status']:4}  {m['stock']['shoulder_cm']:.1f} cm")
    print(f"  Rifle/chest          {m['stock']['chest_status']:4}  {m['stock']['chest_cm']:.1f} cm")
    print(f"  Palm orient          R {m['orient']['right_palm_deg']:.1f}° {m['orient']['right_status']}  L {m['orient']['left_palm_deg']:.1f}° {m['orient']['left_status']}")
    print(f"  Wrist-palm-grip      R {m['order']['right']['status']} t={m['order']['right']['t']:.2f}  L {m['order']['left']['status']} t={m['order']['left']['t']:.2f}")
    print("")
    print("ANATOMY")
    ar = m["anatomy"]["right_elbow"]
    al = m["anatomy"]["left_elbow"]
    print(f"  Right elbow          {ar['status']:4}  {ar['angle']:.1f}°  reach {ar['reach_cm']:.1f}/{ar['max_cm']:.1f} cm  ik={ar['ik_status']}")
    print(f"  Left elbow           {al['status']:4}  {al['angle']:.1f}°  reach {al['reach_cm']:.1f}/{al['max_cm']:.1f} cm  ik={al['ik_status']}")
    print(f"  Right shoulder       {m['anatomy']['right_shoulder']['status']:4}  elev {m['anatomy']['right_shoulder']['elev_deg']:.1f}°")
    print(f"  Left shoulder        {m['anatomy']['left_shoulder']['status']:4}  elev {m['anatomy']['left_shoulder']['elev_deg']:.1f}°")
    print(f"  Muzzle pitch         {m['aim']['pitch_deg']:.1f}°   sight {m['aim']['sight_deg']:.1f}°")
    print("")
    print("FINGERS")
    for side in ("right", "left"):
        bits = "  ".join(f"{r['finger'][:2]}:{r['status'][0]} az={r['az']:.0f}" for r in m["wrap"][f"{side}_fingers"])
        print(f"  {side:5} {bits}")
    print("")
    print("ANIMATION")
    for s in rep["anims_compact"]:
        print(f"  {s['label']:6} {s['status']:4} {_bar(s['pass_pct'])} {s['pass_pct']:.0f}%  {s['heatmap']}")
        if s["spikes"]:
            print(f"         jitter {s['spikes'][:3]}")
        if s["drifts"]:
            print(f"         drift  {s['drifts'][:3]}")
    print("")
    print("TRANSITIONS")
    for t in rep["transitions"]:
        print(f"  {t['from']} -> {t['to']:22} {t['status']:4}  dR={t['dR_cm']:.1f} dL={t['dL_cm']:.1f} dG={t['dG_cm']:.1f} cm")
    print("")
    print("WORST FRAMES")
    for w in rep["worst5"]:
        print(
            f"  {w['anim']:6} #{w['frame']:<4} {w['status']:4} score={w['score']:.1f}  "
            f"grip L/R {w['left_grip_cm']:.1f}/{w['right_grip_cm']:.1f}  "
            f"Lelbow {w['left_elbow']:.0f}°  clipR {w['clip_R']:.1f}%  {w['fails'][:4]}"
        )
    print("")
    print("REGRESSION", rep["regression"]["status"])
    if rep["regression"].get("broke"):
        print("  broke", rep["regression"]["broke"])
    if rep["regression"].get("new_fails"):
        print("  new_fails", rep["regression"]["new_fails"][:12])
    if rep.get("snapshot"):
        print("SNAPSHOT", rep["snapshot"])
    print("")
    print("[WeaponCalib] RESULT", rep["result"])


def run_static(correct: bool = False) -> dict:
    m = measure_frame()
    fire = (m.get("action") or "").startswith("Firing")
    v = verdict_frame(m, fire=fire)
    print("[WeaponCalib] STATIC", m["action"], "frame", m["frame"], v["status"], v["fails"])
    for k, z in m["zones"].items():
        print(f"  {k:22} on={z['on']:5.1f}% in={z['inside']:5.1f}% mean_cm={z['mean_cm']:4.1f} n={z['n']}")
    print(f"  wrap_R {m['wrap']['right']:5.1f}%  wrap_L {m['wrap']['left']:5.1f}%")
    print(f"  grip_err R/L {m['contact']['right_grip_err_cm']:.2f}/{m['contact']['left_grip_err_cm']:.2f} cm")
    if correct and any("inside" in f for f in v["fails"]):
        print("[WeaponCalib] correct: push inside fingertips")
        push_inside_fingertips()
        m = measure_frame()
        v = verdict_frame(m, fire=fire)
        print("[WeaponCalib] STATIC", v["status"], v["fails"])
    return {"measure": m, "verdict": v}


def run_full() -> dict:
    arm = bpy.data.objects["Armature"]
    scene = bpy.context.scene
    prev_action = arm.animation_data.action if arm.animation_data else None
    prev_frame = scene.frame_current
    nla_mutes = []
    if arm.animation_data:
        nla_mutes = [(t, t.mute) for t in arm.animation_data.nla_tracks]

    static = run_static(correct=False)
    sweeps = []
    try:
        for act, label in ANIMS:
            print(f"[WeaponCalib] sweep {label} {act}")
            sweeps.append(sweep_action(act, label))
        transitions = sweep_transitions()
    finally:
        if arm.animation_data:
            for t, muted in nla_mutes:
                t.mute = muted
            arm.animation_data.action = prev_action
        scene.frame_set(prev_frame)
        bpy.context.view_layer.update()

    compact = [_compact_sweep(s) for s in sweeps]
    worst5 = _worst_list(sweeps)
    snapshot = None
    # snapshot the global worst FAIL (or worst WARN)
    fail_samples = []
    for sw in sweeps:
        for s in sw["samples"]:
            if s["verdict"]["status"] == "FAIL":
                fail_samples.append((sw["label"], s))
    if fail_samples:
        lab, samp = max(fail_samples, key=lambda x: x[1]["verdict"]["score"])
        act = next(a for a, l in ANIMS if l == lab)
        try:
            _set_action(arm, act)
            scene.frame_set(samp["frame"])
            bpy.context.view_layer.update()
            snapshot = _write_snapshot(lab, samp)
        finally:
            if arm.animation_data:
                for t, muted in nla_mutes:
                    t.mute = muted
                arm.animation_data.action = prev_action
            scene.frame_set(prev_frame)
            bpy.context.view_layer.update()

    anim_overall = "PASS"
    for s in compact:
        anim_overall = _worse(anim_overall, s["status"])
    trans_st = "PASS"
    for t in transitions:
        trans_st = _worse(trans_st, t["status"])
    result = _worse(_worse(static["verdict"]["status"], anim_overall), trans_st)

    rep = {
        "static": static,
        "anims_compact": compact,
        "transitions": transitions,
        "worst5": worst5,
        "snapshot": snapshot,
        "result": result,
    }
    # keep samples out of regression payload
    reg_in = {
        "static": {"verdict": static["verdict"]},
        "anims_compact": compact,
    }
    # verdict_frame status only
    static["verdict"] = {k: static["verdict"][k] for k in ("status", "score", "fails", "warns")}
    rep["static"]["verdict"] = static["verdict"]
    # restore full static measure already in static['measure'] — trim checks from memory in print path
    rep["regression"] = regression_compare(
        {"static": {"verdict": static["verdict"]}, "anims_compact": compact}
    )
    if rep["regression"]["status"] == "FAIL":
        rep["result"] = "FAIL"
    report_print(rep)
    os.makedirs(os.path.abspath(OUT_DIR), exist_ok=True)
    summary_path = os.path.abspath(os.path.join(OUT_DIR, "last_report.json"))
    slim = {
        "result": rep["result"],
        "static": {
            "frame": rep["static"]["measure"]["frame"],
            "action": rep["static"]["measure"]["action"],
            "verdict": rep["static"]["verdict"],
            "contact": rep["static"]["measure"]["contact"],
            "wrap": {
                "right": rep["static"]["measure"]["wrap"]["right"],
                "left": rep["static"]["measure"]["wrap"]["left"],
            },
            "setup": rep["static"]["measure"]["setup"],
            "aim": rep["static"]["measure"]["aim"],
            "stock": rep["static"]["measure"]["stock"],
        },
        "anims": compact,
        "transitions": transitions,
        "worst5": worst5,
        "regression": rep["regression"],
        "snapshot": snapshot,
    }
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(slim, f, indent=2)
    print("[WeaponCalib] wrote", summary_path)
    return rep


if __name__ == "__main__":
    run_full()
elif __name__ == "autoseat":
    run_static(correct=True)
