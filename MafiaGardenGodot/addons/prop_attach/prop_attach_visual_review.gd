extends RefCounted
## Veredicto automático genérico (métricas + alineación en pantalla).

const MAX_AXIS_ANGLE_DEG := 15.0
const MAX_PALM_SURF_M := 0.04
const MAX_VISUAL_GRIP_PALM_M := 0.05
const MAX_SCREEN_ALIGN_PX := 32.0


static func review(metrics: Dictionary, screen: Dictionary = {}) -> Dictionary:
	var issues: PackedStringArray = []
	var passed := true

	var angle: float = float(metrics.get("axis_angle_deg", metrics.get("barrel_angle_deg", 999.0)))
	if angle > MAX_AXIS_ANGLE_DEG:
		issues.append("axis_angle_deg=%.1f > %.1f" % [angle, MAX_AXIS_ANGLE_DEG])
		passed = false

	var palm_p: float = absf(float(metrics.get(
		"palm_primary_to_grip_surf_m",
		metrics.get("palm_r_to_grip_surf_m", 999.0)
	)))
	if palm_p > MAX_PALM_SURF_M:
		issues.append("palm_primary_to_grip_surf_m=%.3f" % palm_p)
		passed = false

	var palm_s: float = absf(float(metrics.get(
		"palm_secondary_to_hold_surf_m",
		metrics.get("palm_l_to_fore_surf_m", 999.0)
	)))
	if palm_s > MAX_PALM_SURF_M:
		issues.append("palm_secondary_to_hold_surf_m=%.3f" % palm_s)
		passed = false

	var vgp: float = float(metrics.get("visual_grip_to_palm_m", 999.0))
	if vgp > MAX_VISUAL_GRIP_PALM_M:
		issues.append("visual_grip_to_palm_m=%.3f" % vgp)
		passed = false

	if not screen.is_empty():
		var px_g: float = float(screen.get("grip_vs_palm_px", 999.0))
		var px_h: float = float(screen.get("hold_vs_palm_px", screen.get("fore_vs_palm_px", 999.0)))
		if px_g > MAX_SCREEN_ALIGN_PX:
			issues.append("screen grip↔palma=%.0fpx" % px_g)
			passed = false
		if px_h > MAX_SCREEN_ALIGN_PX:
			issues.append("screen hold↔palma=%.0fpx" % px_h)
			passed = false

	return {
		"pass": passed,
		"issues": issues,
		"summary": ("PASS" if passed else "FAIL: " + "; ".join(issues)),
		"thresholds": {
			"max_axis_angle_deg": MAX_AXIS_ANGLE_DEG,
			"max_palm_surf_m": MAX_PALM_SURF_M,
			"max_visual_grip_palm_m": MAX_VISUAL_GRIP_PALM_M,
			"max_screen_align_px": MAX_SCREEN_ALIGN_PX,
		},
	}
