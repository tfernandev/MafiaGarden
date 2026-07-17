"""Une los 4 cuadrantes de obeliscofinal en city_map_isometric.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(r"C:\Users\Usuario\Downloads\obeliscofinal")
OUT = ROOT / "textures" / "map" / "city" / "city_map_isometric.png"

TILE_W = 1536
TILE_H = 1024

QUADRANTS = [
    ("SuperiorIzquierda.png", 0, 0),
    ("SuperiorDerecha.png", TILE_W, 0),
    ("InferiorIzquierda.png", 0, TILE_H),
    ("InferiorDerecha.png", TILE_W, TILE_H),
]


def load_tile(name: str) -> Image.Image:
    path = SRC / name
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGB").resize((TILE_W, TILE_H), Image.Resampling.LANCZOS)


def main() -> None:
    canvas = Image.new("RGB", (TILE_W * 2, TILE_H * 2), (8, 12, 24))
    for filename, x, y in QUADRANTS:
        tile = load_tile(filename)
        canvas.paste(tile, (x, y))
        print(f"  {filename} -> ({x}, {y})")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, "PNG", optimize=True)
    print(f"\nMapa: {OUT} ({canvas.size[0]}x{canvas.size[1]})")


if __name__ == "__main__":
    main()
