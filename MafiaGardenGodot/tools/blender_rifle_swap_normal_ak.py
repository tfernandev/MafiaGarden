"""Swap in the CC0 Lamoot AK (real pistol-grip width) and seat palms.

Does NOT use fingertip IK. Collision-stop curl only.
"""
from __future__ import annotations

import bpy
from mathutils import Matrix, Quaternion, Vector

from blender_rifle_finger_contact import (
    FINGERS,
    curl_finger,
    diagnose,
    mute_finger_ik,
    restore_mixamo_fingers,
    _bvh_world,
    _palm_bvh,
)


def _bw(arm, name):
    return arm.matrix_world @ arm.pose.bones[name].head


def palm_centroids():
    mesh = bpy.data.objects["SoldadoMesh"]
    arm = bpy.data.objects["Armature"]
    deps = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(deps)
    me = ev.to_mesh()
    mw = ev.matrix_world
    rh = _bw(arm, "mixamorig:RightHand")
    lh = _bw(arm, "mixamorig:LeftHand")
    matn = [m.name if m else "" for m in mesh.data.materials]
    idx = matn.index("HANDCOL_Palma")
    R, L = [], []
    for poly in me.polygons:
        if poly.material_index != idx:
            continue
        c = Vector()
        for vi in poly.vertices:
            c += me.vertices[vi].co
        p = mw @ (c / len(poly.vertices))
        if (p - lh).length < (p - rh).length:
            L.append(p)
        else:
            R.append(p)
    ev.to_mesh_clear()
    return sum(R, Vector()) / len(R), sum(L, Vector()) / len(L)


def _cluster(obj, y0, y1, zmax):
    """Barrel is local +Y on the imported AK (before/after object rotation)."""
    pts = []
    for v in obj.data.vertices:
        p = v.co
        if y0 <= p.y <= y1 and p.z <= zmax:
            pts.append(obj.matrix_world @ p)
    if not pts:
        raise RuntimeError(f"empty cluster {y0} {y1}")
    c = sum(pts, Vector()) / len(pts)
    return c, pts


def paint_parts(obj):
    """Tag faces by Y-bin so autoseat still has mango/handguard names."""
    names = [
        "AKCOL_Culata",
        "AKCOL_Mango",
        "AKCOL_Cargador",
        "AKCOL_Cuerpo",
        "AKCOL_Guardamanos",
        "AKCOL_Punta",
    ]
    colors = {
        "AKCOL_Culata": (0.82, 0.74, 0.55, 1),
        "AKCOL_Mango": (1.0, 0.45, 0.1, 1),
        "AKCOL_Cargador": (0.85, 0.12, 0.12, 1),
        "AKCOL_Cuerpo": (0.35, 0.35, 0.38, 1),
        "AKCOL_Guardamanos": (0.2, 0.45, 0.9, 1),
        "AKCOL_Punta": (0.9, 0.2, 0.85, 1),
    }
    obj.data.materials.clear()
    for n in names:
        mat = bpy.data.materials.get(n) or bpy.data.materials.new(n)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = colors[n]
        obj.data.materials.append(mat)
    def slot_for(y, z):
        t = (y - y0) / max(1e-6, y1 - y0)
        if t < 0.18:
            return 0
        if -0.22 <= y <= -0.13 and z < 0.02:
            return 1
        if 0.04 <= y <= 0.13 and z < 0.02:
            return 2
        if 0.16 <= y <= 0.36:
            return 4
        if t > 0.88:
            return 5
        return 3

    ys = [v.co.y for v in obj.data.vertices]
    y0, y1 = min(ys), max(ys)
    for poly in obj.data.polygons:
        c = Vector()
        for vi in poly.vertices:
            c += obj.data.vertices[vi].co
        loc = c / len(poly.vertices)
        poly.material_index = slot_for(loc.y, loc.z)


def align_to_palms(ak, palm_r, palm_l):
    cg, _ = _cluster(ak, -0.22, -0.13, 0.02)
    ch, _ = _cluster(ak, 0.16, 0.34, 0.20)
    src = (ch - cg)
    dst = (palm_l - palm_r)
    if src.length < 1e-6 or dst.length < 1e-6:
        raise RuntimeError("align degenerate")
    rot = src.normalized().rotation_difference(dst.normalized())
    # rotate around grip centroid, then snap grip to right palm
    R = rot.to_matrix().to_4x4()
    T1 = Matrix.Translation(-cg)
    T2 = Matrix.Translation(palm_r)
    ak.matrix_world = T2 @ R @ T1 @ ak.matrix_world
    bpy.context.view_layer.update()
    cg2, _ = _cluster(ak, -0.22, -0.13, 0.02)
    ch2, _ = _cluster(ak, 0.16, 0.34, 0.20)
    print("[WeaponCalib] aligned grip", [round(x, 3) for x in cg2], "hg", [round(x, 3) for x in ch2])
    print("[WeaponCalib] palms R", [round(x, 3) for x in palm_r], "L", [round(x, 3) for x in palm_l])
    return cg2, ch2


def retarget_sockets(grip_pt, hg_pt, muzzle_pt):
    grip = bpy.data.objects["Grip"]
    mw = grip.matrix_world.copy()
    # keep current rotation (hand-owned), move origin to pistol grip
    grip.matrix_world.translation = grip_pt
    bpy.context.view_layer.update()
    for name, pt in (("Foregrip", hg_pt), ("Muzzle", muzzle_pt), ("DEBUG_Trigger_Mango", grip_pt), ("DEBUG_Guardamanos", hg_pt), ("DEBUG_Punta_Disparo", muzzle_pt)):
        o = bpy.data.objects.get(name)
        if o is None:
            continue
        o.matrix_world.translation = pt
    return mw


def run():
    ak = bpy.data.objects.get("AK_Normal")
    if ak is None:
        raise RuntimeError("AK_Normal missing — import first")
    old = bpy.data.objects.get("AK_Body")
    if old:
        old.hide_viewport = True
        old.hide_render = True
        old.name = "AK_Body_Old"
    scope = bpy.data.objects.get("AK_Scope")
    if scope:
        scope.hide_viewport = True
        scope.hide_render = True
    ak.name = "AK_Body"
    ak.hide_viewport = False

    palm_r, palm_l = palm_centroids()
    cg, ch = align_to_palms(ak, palm_r, palm_l)
    # muzzle = max Y after align (barrel was +Y)
    ymax_v = max(ak.data.vertices, key=lambda v: v.co.y)
    mz = ak.matrix_world @ ymax_v.co
    retarget_sockets(cg, ch, mz)

    # parent new AK under Grip keep world
    grip = bpy.data.objects["Grip"]
    mw = ak.matrix_world.copy()
    ak.parent = grip
    ak.matrix_world = mw
    bpy.context.view_layer.update()
    paint_parts(ak)
    bpy.context.view_layer.update()

    mute_finger_ik()
    frame = int(bpy.context.scene.frame_current)
    restore_mixamo_fingers(frame)
    _, _, _, bvh_ak = _bvh_world(ak)
    mesh = bpy.data.objects["SoldadoMesh"]
    print("[WeaponCalib] CURL on normal AK (no yema IK)")
    for side, is_l, max_per, contact in (
        ("Right", False, (40.0, 22.0, 12.0), 1.2),
        ("Left", True, (30.0, 16.0, 8.0), 2.5),
    ):
        ev, me, bvh_pal = _palm_bvh(mesh, is_l)
        for f in FINGERS:
            curl_finger(
                side,
                f,
                bvh_ak,
                bvh_pal,
                max_per=max_per,
                contact_cm=contact,
                allow_y=(f == "Thumb"),
            )
        ev.to_mesh_clear()
    diagnose()
    bpy.ops.wm.save_mainfile()
    print("[WeaponCalib] saved", bpy.data.filepath)


if __name__ == "__main__":
    run()
