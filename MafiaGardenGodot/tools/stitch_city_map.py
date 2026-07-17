"""Une las 6 piezas generadas en un mapa 1536x1024 con distribución 3 columnas iguales."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = Path(r"C:\Users\Usuario\.cursor\projects\c-Users-Usuario-source-JuegosMobile\assets")
OUT_MAP = ROOT / "textures" / "map" / "city" / "city_map_zones.png"
OUT_DIR = ROOT / "textures" / "map" / "city" / "districts"

CANVAS_W = 1536
CANVAS_H = 1024

# Columnas iguales (~33% cada una). Puerto = columna derecha, no mitad del mapa.
# Rectángulos normalizados (x0, y0, x1, y1)
LAYOUT: dict[str, tuple[float, float, float, float]] = {
    "barrio_viejo": (0.000, 0.000, 0.333, 0.480),
    "villa_roja": (0.000, 0.480, 0.333, 1.000),
    "mansion_norte": (0.333, 0.000, 0.667, 0.260),
    "centro": (0.333, 0.260, 0.667, 0.540),
    "mercado_sur": (0.333, 0.540, 0.667, 1.000),
    "puerto_norte": (0.667, 0.000, 1.000, 1.000),
}

SOURCE_NAMES: dict[str, str] = {
    "barrio_viejo": "district_barrio_viejo.png",
    "villa_roja": "district_villa_roja.png",
    "mansion_norte": "district_mansion_norte.png",
    "centro": "district_centro.png",
    "mercado_sur": "district_mercado_sur.png",
    "puerto_norte": "district_puerto_norte.png",
}


def rect_to_pixels(rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = rect
    return (
        int(round(x0 * CANVAS_W)),
        int(round(y0 * CANVAS_H)),
        int(round(x1 * CANVAS_W)),
        int(round(y1 * CANVAS_H)),
    )


def load_and_fit(district_id: str) -> Image.Image:
    path = ASSETS / SOURCE_NAMES[district_id]
    if not path.exists():
        raise FileNotFoundError(f"Falta asset: {path}")
    rect = LAYOUT[district_id]
    left, top, right, bottom = rect_to_pixels(rect)
    target_w = right - left
    target_h = bottom - top
    img = Image.open(path).convert("RGB")
    return img.resize((target_w, target_h), Image.Resampling.LANCZOS)


def paste_with_blend(canvas: Image.Image, tile: Image.Image, left: int, top: int, blend_px: int = 10) -> None:
    """Pega un tile suavizando el borde izquierdo y superior (excepto primera columna/fila)."""
    if left > 0 and blend_px > 0:
        w, h = tile.size
        for x in range(min(blend_px, w)):
            alpha = x / float(blend_px)
            for y in range(h):
                r, g, b = tile.getpixel((x, y))
                br, bg, bb = canvas.getpixel((left + x, top + y))
                tile.putpixel((x, y), (
                    int(br * (1 - alpha) + r * alpha),
                    int(bg * (1 - alpha) + g * alpha),
                    int(bb * (1 - alpha) + b * alpha),
                ))
    if top > 0 and blend_px > 0:
        w, h = tile.size
        for y in range(min(blend_px, h)):
            alpha = y / float(blend_px)
            for x in range(w):
                r, g, b = tile.getpixel((x, y))
                br, bg, bb = canvas.getpixel((left + x, top + y))
                tile.putpixel((x, y), (
                    int(br * (1 - alpha) + r * alpha),
                    int(bg * (1 - alpha) + g * alpha),
                    int(bb * (1 - alpha) + b * alpha),
                ))
    canvas.paste(tile, (left, top))


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), (12, 18, 32))

    for district_id, rect in LAYOUT.items():
        tile = load_and_fit(district_id)
        left, top, right, bottom = rect_to_pixels(rect)
        paste_with_blend(canvas, tile, left, top, blend_px=12)
        tile.save(OUT_DIR / f"{district_id}.png", "PNG")
        print(f"  {district_id}: {tile.size[0]}x{tile.size[1]} -> ({left},{top})")

    canvas.save(OUT_MAP, "PNG")
    print(f"\nMapa unido: {OUT_MAP} ({CANVAS_W}x{CANVAS_H})")


if __name__ == "__main__":
    main()
