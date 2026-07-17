#!/usr/bin/env python3
"""Generate ambient sprite assets for MafiaGardenGodot city map."""

import json
import math
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# Palette
COLOR_FOUNTAIN = (94, 184, 255)      # #5EB8FF
COLOR_FOUNTAIN_DEEP = (40, 120, 200)
COLOR_WARM = (255, 184, 77)          # #FFB84D
COLOR_SMOKE = (184, 188, 196)        # #B8BCC4
COLOR_BEAM = (255, 220, 100)

ROOT = Path(r"C:\Users\Usuario\source\JuegosMobile\MafiaGardenGodot\textures\map\city\ambient")
REF = Path(r"C:\Users\Usuario\Downloads\obeliscofinal")
QUAD = Path(r"C:\Users\Usuario\source\JuegosMobile\MafiaGardenGodot\textures\map\city\quadrants")

QUAD_FILES = {
    "superior_izquierda": ("SuperiorIzquierda.png", 1535),
    "superior_derecha": ("SuperiorDerecha.png", 1536),
    "inferior_izquierda": ("InferiorIzquierda.png", 1535),
    "inferior_derecha": ("InferiorDerecha.png", 1535),
}


def ensure_dirs() -> None:
    for sub in [
        "superior_izquierda",
        "superior_derecha",
        "inferior_izquierda",
        "inferior_derecha",
        "shared",
        "debug",
    ]:
        (ROOT / sub).mkdir(parents=True, exist_ok=True)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def rgba(c: tuple, a: float) -> tuple:
    return (c[0], c[1], c[2], int(max(0, min(255, a * 255))))


def soft_ellipse(draw: ImageDraw.ImageDraw, bbox, fill, blur_radius: int = 2) -> None:
    tmp = Image.new("RGBA", (bbox[2] - bbox[0] + blur_radius * 4, bbox[3] - bbox[1] + blur_radius * 4), (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    ox, oy = blur_radius * 2, blur_radius * 2
    td.ellipse((ox, oy, ox + bbox[2] - bbox[0], oy + bbox[3] - bbox[1]), fill=fill)
    if blur_radius > 0:
        tmp = tmp.filter(ImageFilter.GaussianBlur(blur_radius))
    return tmp, (bbox[0] - blur_radius * 2, bbox[1] - blur_radius * 2)


def paste_soft(canvas: Image.Image, patch: Image.Image, pos: tuple) -> None:
    canvas.alpha_composite(patch, pos)


def make_fountain_frame(w: int, h: int, frame_idx: int, frame_count: int = 4, large: bool = False) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w // 2, h // 2 + (2 if large else 1)
    # Isometric pool: wider than tall
    rx = int(w * 0.38)
    ry = int(h * 0.22)
    phase = (frame_idx / frame_count) * math.tau

    # Stone basin shadow
    draw = ImageDraw.Draw(img)
    basin = (cx - rx - 2, cy - ry - 1, cx + rx + 2, cy + ry + 3)
    draw.ellipse(basin, fill=(50, 55, 65, 90))

    # Water pool
    water_alpha = 170 + int(20 * math.sin(phase))
    patch, pos = soft_ellipse(draw, (cx - rx, cy - ry, cx + rx, cy + ry), rgba(COLOR_FOUNTAIN, water_alpha / 255), 3)
    paste_soft(img, patch, pos)

    # Inner glow
    irx, iry = int(rx * 0.65), int(ry * 0.55)
    patch2, pos2 = soft_ellipse(
        draw,
        (cx - irx, cy - iry - 2, cx + irx, cy + iry),
        rgba(COLOR_FOUNTAIN, 0.55 + 0.15 * math.sin(phase + 0.5)),
        2,
    )
    paste_soft(img, patch2, pos2)

    # Central splash
    splash_h = int(h * (0.22 + 0.06 * math.sin(phase)))
    splash_w = max(3, int(w * 0.06))
    sx0 = cx - splash_w // 2
    sy0 = cy - ry - splash_h
    splash = Image.new("RGBA", (splash_w + 8, splash_h + 8), (0, 0, 0, 0))
    sd = ImageDraw.Draw(splash)
    sd.ellipse((4, 4, splash_w + 4, splash_h + 4), fill=rgba((200, 235, 255), 0.7))
    splash = splash.filter(ImageFilter.GaussianBlur(1))
    paste_soft(img, splash, (sx0 - 4, sy0 - 4))

    # Ripple rings
    for ring in range(2):
        t = (frame_idx + ring * 0.5) / frame_count
        rr = rx * (0.5 + t * 0.35)
        rry = ry * (0.5 + t * 0.35)
        alpha = int(80 * (1.0 - t))
        if alpha > 5:
            draw.ellipse(
                (cx - rr, cy - rry, cx + rr, cy + rry),
                outline=(140, 210, 255, alpha),
                width=1,
            )

    if large:
        # Tiered center pedestal hint
        draw.ellipse((cx - 6, cy - 8, cx + 6, cy + 2), fill=(90, 95, 105, 120))

    return img


def make_fountain_sheet(fw: int, fh: int, frames: int = 4, large: bool = False) -> Image.Image:
    sheet = Image.new("RGBA", (fw * frames, fh), (0, 0, 0, 0))
    for i in range(frames):
        frame = make_fountain_frame(fw, fh, i, frames, large)
        sheet.paste(frame, (i * fw, 0))
    return sheet


def make_smoke_frame(w: int, h: int, frame_idx: int, frame_count: int = 6, seed: int = 0) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    t = frame_idx / max(1, frame_count - 1)
    base_x = w // 2 + int(4 * math.sin(seed + frame_idx * 0.7))
    base_y = h - 8

    # Multiple wisps rising
    for wisp in range(4):
        phase = seed * 1.3 + wisp * 1.7 + frame_idx * 0.9
        rise = t * (h * 0.55) + wisp * 6
        drift = math.sin(phase) * (8 + wisp * 3)
        cx = base_x + drift
        cy = base_y - rise - wisp * 12
        radius = lerp(6, 14, t) + wisp * 2
        alpha = lerp(0.38, 0.08, t) * (1.0 - wisp * 0.15)
        patch, pos = soft_ellipse(
            draw,
            (int(cx - radius), int(cy - radius * 1.4), int(cx + radius), int(cy + radius * 0.8)),
            rgba(COLOR_SMOKE, alpha),
            3,
        )
        paste_soft(img, patch, pos)

    # Thin base puff at chimney
    patch, pos = soft_ellipse(draw, (base_x - 8, base_y - 6, base_x + 8, base_y + 4), rgba(COLOR_SMOKE, 0.35), 2)
    paste_soft(img, patch, pos)
    return img


def make_smoke_sheet(w: int, h: int, frames: int = 6, seed: int = 0) -> Image.Image:
    sheet = Image.new("RGBA", (w * frames, h), (0, 0, 0, 0))
    for i in range(frames):
        sheet.paste(make_smoke_frame(w, h, i, frames, seed), (i * w, 0))
    return sheet


def make_lighthouse_beam(size: int = 256) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy = size // 2, size // 2
    arr = np.zeros((size, size, 4), dtype=np.uint8)

    # Cone pointing right from center (pivot = center, rotates in Godot)
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < 4 or dist > size * 0.48:
                continue
            angle = math.atan2(dy, dx)
            # Narrow cone ~35 degrees
            cone_half = math.radians(18)
            if abs(angle) > cone_half:
                continue
            # Fade along length and across width
            along = dx / (size * 0.48)
            if along < 0:
                continue
            across = abs(angle) / cone_half
            alpha = (1.0 - along**1.2) * (1.0 - across**1.5) * 0.45
            if alpha < 0.02:
                continue
            arr[y, x] = (COLOR_BEAM[0], COLOR_BEAM[1], COLOR_BEAM[2], int(alpha * 255))

    beam = Image.fromarray(arr, "RGBA")
    beam = beam.filter(ImageFilter.GaussianBlur(2))
    # Hot core near pivot
    draw = ImageDraw.Draw(beam)
    patch, pos = soft_ellipse(draw, (cx - 10, cy - 10, cx + 10, cy + 10), rgba(COLOR_WARM, 0.55), 3)
    paste_soft(beam, patch, pos)
    return beam


def make_lighthouse_glow_sheet(fw: int = 48, frames: int = 3) -> Image.Image:
    sheet = Image.new("RGBA", (fw * frames, fw), (0, 0, 0, 0))
    for i in range(frames):
        frame = Image.new("RGBA", (fw, fw), (0, 0, 0, 0))
        pulse = 0.65 + 0.35 * math.sin((i / frames) * math.tau)
        r = int(fw * 0.35 * pulse)
        patch, pos = soft_ellipse(
            ImageDraw.Draw(frame),
            (fw // 2 - r, fw // 2 - r, fw // 2 + r, fw // 2 + r),
            rgba(COLOR_WARM, 0.5 * pulse),
            4,
        )
        paste_soft(frame, patch, pos)
        sheet.paste(frame, (i * fw, 0))
    return sheet


def make_window_warm(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = 1 if size > 8 else 0
    draw.rectangle((margin, margin, size - 1 - margin, size - 1 - margin), fill=rgba(COLOR_WARM, 0.85))
    img = img.filter(ImageFilter.GaussianBlur(0.8 if size <= 8 else 1.2))
    return img


def make_window_off(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 2, size - 3, size - 3), fill=(30, 32, 38, 18))
    return img


def detect_water_mask(ref_path: Path, width: int, height: int, seed_rect: tuple, feather: int = 3) -> Image.Image:
    """Build grayscale water mask from reference image blue-channel heuristic + seed rect."""
    src = Image.open(ref_path).convert("RGB")
    if src.size != (width, height):
        src = src.resize((width, height), Image.Resampling.LANCZOS)
    arr = np.array(src, dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    # Water: dark navy, blue-dominant, low green
    lum = (r + g + b) / 3.0
    blue_dom = b - np.maximum(r, g)
    water_score = np.clip(
        blue_dom * 0.35 + (120.0 - lum) * 0.6 - np.abs(r - g) * 0.08,
        0,
        255,
    )

    rx, ry, rw, rh = seed_rect
    mask = np.zeros((height, width), dtype=np.float32)
    x0 = int(rx * width)
    y0 = int(ry * height)
    x1 = int((rx + rw) * width)
    y1 = int((ry + rh) * height)
    region = water_score[y0:y1, x0:x1]
    thresh = np.percentile(region, 48)
    local = (region > thresh).astype(np.float32) * 255.0
    mask[y0:y1, x0:x1] = local

    from scipy import ndimage

    mask_bool = mask > 127
    mask_bool = ndimage.binary_opening(mask_bool, iterations=1)
    mask_bool = ndimage.binary_closing(mask_bool, iterations=4)
    # Fill holes inside water bodies
    mask_bool = ndimage.binary_fill_holes(mask_bool)
    mask = mask_bool.astype(np.float32) * 255.0

    img = Image.fromarray(mask.astype(np.uint8), mode="L")
    if feather > 0:
        img = img.filter(ImageFilter.GaussianBlur(feather))
    return img


def make_window_spawn_mask(ref_path: Path, width: int, height: int) -> Image.Image:
    """Residential zones: warm-lit building areas for random window spawns."""
    src = Image.open(ref_path).convert("RGB")
    if src.size != (width, height):
        src = src.resize((width, height), Image.Resampling.LANCZOS)
    arr = np.array(src, dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    lum = (r + g + b) / 3.0
    warmth = r - b
    # Roofs and walls with warm window glow nearby
    score = np.clip((lum - 25) * 0.4 + warmth * 0.25, 0, 255)
    mask = (score > np.percentile(score, 62)).astype(np.float32) * 255.0
    from scipy import ndimage

    mask = ndimage.binary_opening(mask > 127, iterations=2)
    mask = ndimage.binary_erosion(mask, iterations=1)
    img = Image.fromarray((mask.astype(np.float32) * 255).astype(np.uint8), mode="L")
    return img.filter(ImageFilter.GaussianBlur(2))


def make_simple_water_mask(width: int, height: int, seed_rect: tuple, feather: int = 3) -> Image.Image:
    """Fallback without scipy - rectangular feathered region."""
    img = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(img)
    rx, ry, rw, rh = seed_rect
    x0, y0 = int(rx * width), int(ry * height)
    x1, y1 = int((rx + rw) * width), int((ry + rh) * height)
    draw.rectangle((x0, y0, x1, y1), fill=255)
    return img.filter(ImageFilter.GaussianBlur(feather))


def try_water_mask(ref_name: str, width: int, seed_rect: tuple) -> Image.Image:
    ref_path = REF / ref_name
    try:
        return detect_water_mask(ref_path, width, 1024, seed_rect)
    except Exception:
        return make_simple_water_mask(width, 1024, seed_rect)


def save_debug_overlay(quadrant: str, sprites: list, suffix: str = "") -> None:
    ref_name, w = QUAD_FILES[quadrant]
    map_path = REF / ref_name
    if not map_path.exists():
        map_path = QUAD / f"{quadrant}.png"
    base = Image.open(map_path).convert("RGBA")
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    colors = {
        "fountain": (94, 184, 255, 180),
        "smoke": (184, 188, 196, 160),
        "lighthouse_beam": (255, 220, 100, 140),
        "lighthouse_glow": (255, 184, 77, 200),
        "water_mask": (0, 200, 255, 80),
    }

    for sp in sprites:
        kind = sp.get("type", "fountain")
        pos = sp["position"]
        px = int(pos[0] * base.size[0])
        py = int(pos[1] * base.size[1])
        fs = sp.get("frame_size", [96, 96])
        fw, fh = fs[0], fs[1]
        color = colors.get(kind, (255, 0, 0, 160))
        x0 = px - fw // 2
        y0 = py - fh // 2
        draw.rectangle((x0, y0, x0 + fw, y0 + fh), outline=color, width=2)
        draw.line((px - 4, py, px + 4, py), fill=color, width=1)
        draw.line((px, py - 4, px, py + 4), fill=color, width=1)
        draw.text((x0, y0 - 14), sp["id"], fill=color)

    out = Image.alpha_composite(base, overlay)
    out.save(ROOT / "debug" / f"{quadrant}_sprites_debug{suffix}.png")


def generate_all() -> None:
    ensure_dirs()

    # --- superior_izquierda ---
    make_fountain_sheet(96, 96).save(ROOT / "superior_izquierda" / "fountain_plaza_sheet.png")

    # --- superior_derecha ---
    make_fountain_sheet(80, 80).save(ROOT / "superior_derecha" / "fountain_garden_sheet.png")
    make_fountain_sheet(80, 80).save(ROOT / "superior_derecha" / "fountain_park_sheet.png")
    make_smoke_sheet(64, 96, seed=1).save(ROOT / "superior_derecha" / "smoke_chimney_a_sheet.png")
    make_smoke_sheet(64, 96, seed=7).save(ROOT / "superior_derecha" / "smoke_chimney_b_sheet.png")
    try_water_mask("SuperiorDerecha.png", 1536, (0.72, 0.15, 0.26, 0.35)).save(
        ROOT / "superior_derecha" / "water_mask.png"
    )

    # --- inferior_izquierda ---
    make_lighthouse_beam(256).save(ROOT / "inferior_izquierda" / "lighthouse_beam.png")
    make_lighthouse_glow_sheet(48, 3).save(ROOT / "inferior_izquierda" / "lighthouse_glow_sheet.png")
    make_smoke_sheet(80, 120, seed=3).save(ROOT / "inferior_izquierda" / "smoke_port_a_sheet.png")
    make_smoke_sheet(80, 120, seed=11).save(ROOT / "inferior_izquierda" / "smoke_port_b_sheet.png")
    try_water_mask("InferiorIzquierda.png", 1535, (0.45, 0.20, 0.52, 0.78)).save(
        ROOT / "inferior_izquierda" / "water_mask.png"
    )

    # --- inferior_derecha ---
    make_fountain_sheet(192, 192, large=True).save(ROOT / "inferior_derecha" / "fountain_market_sheet.png")
    make_fountain_sheet(96, 96).save(ROOT / "inferior_derecha" / "fountain_plaza_small_sheet.png")

    # --- shared ---
    make_window_warm(8).save(ROOT / "shared" / "window_warm_8.png")
    make_window_warm(12).save(ROOT / "shared" / "window_warm_12.png")
    make_window_off(8).save(ROOT / "shared" / "window_off_8.png")
    try:
        make_window_spawn_mask(REF / "SuperiorIzquierda.png", 1535, 1024).save(
            ROOT / "superior_izquierda" / "window_spawn_mask.png"
        )
    except Exception:
        pass

    manifest = {
        "version": 1,
        "sprites": [
            {
                "id": "fountain_plaza",
                "quadrant": "superior_izquierda",
                "file": "superior_izquierda/fountain_plaza_sheet.png",
                "type": "animated_sheet",
                "frame_size": [96, 96],
                "frame_count": 4,
                "fps": 8,
                "position": [0.48, 0.42],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "fountain_garden",
                "quadrant": "superior_derecha",
                "file": "superior_derecha/fountain_garden_sheet.png",
                "type": "animated_sheet",
                "frame_size": [80, 80],
                "frame_count": 4,
                "fps": 8,
                "position": [0.62, 0.28],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "fountain_park",
                "quadrant": "superior_derecha",
                "file": "superior_derecha/fountain_park_sheet.png",
                "type": "animated_sheet",
                "frame_size": [80, 80],
                "frame_count": 4,
                "fps": 8,
                "position": [0.38, 0.52],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "smoke_a",
                "quadrant": "superior_derecha",
                "file": "superior_derecha/smoke_chimney_a_sheet.png",
                "type": "animated_sheet",
                "frame_size": [64, 96],
                "frame_count": 6,
                "fps": 6,
                "position": [0.78, 0.22],
                "pivot": [0.5, 0.92],
            },
            {
                "id": "smoke_b",
                "quadrant": "superior_derecha",
                "file": "superior_derecha/smoke_chimney_b_sheet.png",
                "type": "animated_sheet",
                "frame_size": [64, 96],
                "frame_count": 6,
                "fps": 6,
                "position": [0.88, 0.35],
                "pivot": [0.5, 0.92],
            },
            {
                "id": "water_mask_superior_derecha",
                "quadrant": "superior_derecha",
                "file": "superior_derecha/water_mask.png",
                "type": "water_mask",
                "frame_size": [1536, 1024],
                "frame_count": 1,
                "fps": 0,
                "position": [0.0, 0.0],
                "pivot": [0.0, 0.0],
                "water_region": [0.72, 0.15, 0.26, 0.35],
            },
            {
                "id": "lighthouse_beam",
                "quadrant": "inferior_izquierda",
                "file": "inferior_izquierda/lighthouse_beam.png",
                "type": "rotating_sprite",
                "frame_size": [256, 256],
                "frame_count": 1,
                "fps": 0,
                "position": [0.82, 0.55],
                "pivot": [0.5, 0.5],
                "rotation_period_sec": 5.5,
            },
            {
                "id": "lighthouse_glow",
                "quadrant": "inferior_izquierda",
                "file": "inferior_izquierda/lighthouse_glow_sheet.png",
                "type": "animated_sheet",
                "frame_size": [48, 48],
                "frame_count": 3,
                "fps": 4,
                "position": [0.82, 0.55],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "smoke_port_a",
                "quadrant": "inferior_izquierda",
                "file": "inferior_izquierda/smoke_port_a_sheet.png",
                "type": "animated_sheet",
                "frame_size": [80, 120],
                "frame_count": 6,
                "fps": 6,
                "position": [0.62, 0.18],
                "pivot": [0.5, 0.92],
            },
            {
                "id": "smoke_port_b",
                "quadrant": "inferior_izquierda",
                "file": "inferior_izquierda/smoke_port_b_sheet.png",
                "type": "animated_sheet",
                "frame_size": [80, 120],
                "frame_count": 6,
                "fps": 6,
                "position": [0.72, 0.12],
                "pivot": [0.5, 0.92],
            },
            {
                "id": "water_mask_inferior_izquierda",
                "quadrant": "inferior_izquierda",
                "file": "inferior_izquierda/water_mask.png",
                "type": "water_mask",
                "frame_size": [1535, 1024],
                "frame_count": 1,
                "fps": 0,
                "position": [0.0, 0.0],
                "pivot": [0.0, 0.0],
                "water_region": [0.45, 0.20, 0.52, 0.78],
            },
            {
                "id": "fountain_market",
                "quadrant": "inferior_derecha",
                "file": "inferior_derecha/fountain_market_sheet.png",
                "type": "animated_sheet",
                "frame_size": [192, 192],
                "frame_count": 4,
                "fps": 8,
                "position": [0.72, 0.68],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "fountain_plaza_small",
                "quadrant": "inferior_derecha",
                "file": "inferior_derecha/fountain_plaza_small_sheet.png",
                "type": "animated_sheet",
                "frame_size": [96, 96],
                "frame_count": 4,
                "fps": 8,
                "position": [0.22, 0.18],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "window_warm_8",
                "quadrant": "shared",
                "file": "shared/window_warm_8.png",
                "type": "window_tile",
                "frame_size": [8, 8],
                "frame_count": 1,
                "fps": 0,
                "position": [0.0, 0.0],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "window_warm_12",
                "quadrant": "shared",
                "file": "shared/window_warm_12.png",
                "type": "window_tile",
                "frame_size": [12, 12],
                "frame_count": 1,
                "fps": 0,
                "position": [0.0, 0.0],
                "pivot": [0.5, 0.5],
            },
            {
                "id": "window_off_8",
                "quadrant": "shared",
                "file": "shared/window_off_8.png",
                "type": "window_tile",
                "frame_size": [8, 8],
                "frame_count": 1,
                "fps": 0,
                "position": [0.0, 0.0],
                "pivot": [0.5, 0.5],
            },
        ],
    }

    with open(ROOT / "shared" / "ambient_sprites.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    # Debug overlays per quadrant
    by_quad: dict = {}
    for sp in manifest["sprites"]:
        if sp["type"] == "water_mask":
            continue
        q = sp["quadrant"]
        if q == "shared":
            continue
        by_quad.setdefault(q, []).append(sp)

    for q, items in by_quad.items():
        save_debug_overlay(q, items)
        # Overlay on in-game quadrant texture when available (may differ for inferior tiles)
        game_map = QUAD / f"{q}.png"
        if game_map.exists() and game_map.resolve() != (REF / QUAD_FILES[q][0]).resolve():
            save_debug_overlay(q, items, suffix="_game_texture")

    print("Generated ambient sprites in", ROOT)


if __name__ == "__main__":
    generate_all()
