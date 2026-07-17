"""Exporta recortes desde city_map_zones.png usando el layout de 3 columnas."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "textures" / "map" / "city" / "city_map_zones.png"
OUT_DIR = ROOT / "textures" / "map" / "city" / "districts"
DEBUG_OUT = OUT_DIR / "_debug_polygons.png"

DISTRICT_RECTS: dict[str, tuple[float, float, float, float]] = {
    "barrio_viejo": (0.000, 0.000, 0.333, 0.480),
    "villa_roja": (0.000, 0.480, 0.333, 1.000),
    "mansion_norte": (0.333, 0.000, 0.667, 0.260),
    "centro": (0.333, 0.260, 0.667, 0.540),
    "mercado_sur": (0.333, 0.540, 0.667, 1.000),
    "puerto_norte": (0.667, 0.000, 1.000, 1.000),
}

COLORS: dict[str, tuple[int, int, int, int]] = {
    "barrio_viejo": (200, 140, 80, 90),
    "mansion_norte": (120, 200, 80, 90),
    "centro": (120, 120, 255, 90),
    "villa_roja": (255, 80, 80, 90),
    "mercado_sur": (255, 200, 60, 90),
    "puerto_norte": (80, 160, 255, 90),
}


def norm_rect_to_pixels(
    rect: tuple[float, float, float, float], w: int, h: int
) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = rect
    return (
        int(round(x0 * w)),
        int(round(y0 * h)),
        int(round(x1 * w)),
        int(round(y1 * h)),
    )


def export_debug(source: Image.Image) -> None:
    w, h = source.size
    debug = source.convert("RGBA").copy()
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for district_id, rect in DISTRICT_RECTS.items():
        left, top, right, bottom = norm_rect_to_pixels(rect, w, h)
        poly = [(left, top), (right, top), (right, bottom), (left, bottom)]
        color = COLORS.get(district_id, (255, 255, 255, 80))
        draw.polygon(poly, fill=color, outline=(255, 255, 255, 220))
        cx = (left + right) // 2
        cy = (top + bottom) // 2
        draw.text((cx - 45, cy - 8), district_id, fill=(255, 255, 255, 255))
    debug = Image.alpha_composite(debug, overlay)
    debug.save(DEBUG_OUT, "PNG")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"No existe {SOURCE}. Corré stitch_city_map.py primero.")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE)
    w, h = source.size
    for district_id, rect in DISTRICT_RECTS.items():
        box = norm_rect_to_pixels(rect, w, h)
        cropped = source.crop(box)
        cropped.save(OUT_DIR / f"{district_id}.png", "PNG")
        print(f"  -> {district_id}.png {cropped.size}")
    export_debug(source)
    print(f"  -> _debug_polygons.png")


if __name__ == "__main__":
    main()
