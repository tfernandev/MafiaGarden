#!/usr/bin/env python3
"""
Herramienta visual para recortar distritos del mapa con polígonos (no cuadrados).

Uso:
  python tools/district_crop_tool.py
  python tools/district_crop_tool.py "C:/ruta/mapa.png"

Controles:
  - Clic izquierdo en el mapa: agrega vértice al distrito seleccionado
  - Arrastrar vértice: mover punto
  - Clic derecho en vértice: eliminar punto
  - Rueda del mouse: zoom · botón medio o Shift+arrastrar: pan
  - 1-6: cambiar distrito · Supr: borrar polígono del distrito activo
  - Ctrl+S: guardar JSON · Ctrl+E: exportar PNG recortados · Ctrl+O: abrir mapa
"""
from __future__ import annotations

import json
import math
import sys
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from PIL import Image, ImageDraw, ImageTk

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP_CANDIDATES = [
    ROOT / "textures" / "map" / "city" / "city_map_districts_routes_4k.png",
    Path(r"C:\Users\Usuario\Downloads\obeliscofinal\city_map_districts_routes_4k.png"),
    Path(r"C:\Users\Usuario\Downloads\obeliscofinal\city_map_districts_routes.png"),
    ROOT / "textures" / "map" / "city" / "city_map_zones.png",
]

DISTRICTS: list[dict] = [
    {"id": "barrio_viejo", "name": "Barrio Viejo", "color": "#c88c50"},
    {"id": "mansion_norte", "name": "Mansión Norte", "color": "#78c850"},
    {"id": "centro", "name": "Centro", "color": "#7878ff"},
    {"id": "villa_roja", "name": "Villa Roja", "color": "#ff5050"},
    {"id": "mercado_sur", "name": "Mercado Sur", "color": "#ffc83c"},
    {"id": "puerto_norte", "name": "Puerto Norte", "color": "#50a0ff"},
]

# Polígonos iniciales normalizados (0–1) sobre mapa completo — editables en la herramienta.
DEFAULT_POLYGONS: dict[str, list[list[float]]] = {
    "barrio_viejo": [[0.02, 0.02], [0.48, 0.02], [0.48, 0.48], [0.02, 0.48]],
    "mansion_norte": [[0.52, 0.02], [0.98, 0.02], [0.98, 0.40], [0.52, 0.40]],
    "centro": [[0.02, 0.52], [0.45, 0.52], [0.45, 0.95], [0.02, 0.95]],
    "villa_roja": [[0.50, 0.52], [0.64, 0.52], [0.64, 0.98], [0.50, 0.98]],
    "mercado_sur": [[0.62, 0.58], [0.98, 0.58], [0.98, 0.98], [0.62, 0.98]],
    "puerto_norte": [[0.48, 0.38], [0.98, 0.38], [0.98, 0.98], [0.48, 0.98]],
}


def hex_to_rgba(hex_color: str, alpha: int = 140) -> tuple[int, int, int, int]:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha


def norm_to_px(points: list[list[float]], w: int, h: int) -> list[tuple[int, int]]:
    return [(int(round(p[0] * w)), int(round(p[1] * h))) for p in points]


def px_to_norm(points: list[tuple[int, int]], w: int, h: int) -> list[list[float]]:
    return [[round(x / w, 5), round(y / h, 5)] for x, y in points]


def polygon_bbox(points: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)


def dist(a: tuple[float, float], b: tuple[float, float]) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


class DistrictCropTool(tk.Tk):
    def __init__(self, image_path: Path | None = None) -> None:
        super().__init__()
        self.title("MafiaGarden — Recorte por distrito (polígono)")
        self.geometry("1280x820")
        self.minsize(900, 600)

        self.image_path: Path | None = None
        self.pil_image: Image.Image | None = None
        self.photo: ImageTk.PhotoImage | None = None
        self.polygons: dict[str, list[list[float]]] = {
            d["id"]: [p[:] for p in DEFAULT_POLYGONS.get(d["id"], [])] for d in DISTRICTS
        }
        self.json_path = ROOT / "tools" / "district_polygons.json"
        self.export_dir = ROOT / "textures" / "map" / "city" / "districts"
        self.feather_var = tk.IntVar(value=2)

        self.active_id = DISTRICTS[0]["id"]
        self.zoom = 1.0
        self.pan_x = 0.0
        self.pan_y = 0.0
        self.drag_vertex: tuple[str, int] | None = None
        self.pan_drag_start: tuple[float, float] | None = None
        self.show_all_var = tk.BooleanVar(value=True)

        self._build_ui()
        self._bind_keys()

        if self.json_path.exists():
            self._load_json(self.json_path, quiet=True)

        path = image_path or self._find_default_map()
        if path and path.exists():
            self._open_image(path)
        else:
            self.status.set("Abrí un mapa con Ctrl+O")

    def _find_default_map(self) -> Path | None:
        for p in DEFAULT_MAP_CANDIDATES:
            if p.exists():
                return p
        return None

    def _build_ui(self) -> None:
        self.status = tk.StringVar(value="Listo")
        toolbar = ttk.Frame(self, padding=6)
        toolbar.pack(fill=tk.X)

        ttk.Button(toolbar, text="Abrir mapa (Ctrl+O)", command=self._menu_open).pack(side=tk.LEFT, padx=2)
        ttk.Button(toolbar, text="Guardar polígonos (Ctrl+S)", command=self._menu_save).pack(side=tk.LEFT, padx=2)
        ttk.Button(toolbar, text="Exportar distritos (Ctrl+E)", command=self._menu_export).pack(side=tk.LEFT, padx=2)
        ttk.Button(toolbar, text="Vista previa debug", command=self._export_debug).pack(side=tk.LEFT, padx=2)
        ttk.Checkbutton(toolbar, text="Mostrar todos", variable=self.show_all_var, command=self._redraw).pack(
            side=tk.LEFT, padx=8
        )
        ttk.Label(toolbar, text="Suavizado borde:").pack(side=tk.LEFT, padx=(12, 2))
        ttk.Spinbox(toolbar, from_=0, to=8, width=4, textvariable=self.feather_var, command=self._redraw).pack(
            side=tk.LEFT
        )
        ttk.Label(toolbar, textvariable=self.status).pack(side=tk.RIGHT, padx=8)

        body = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        body.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)

        sidebar = ttk.Frame(body, width=220, padding=8)
        body.add(sidebar, weight=0)

        ttk.Label(sidebar, text="Distritos", font=("", 11, "bold")).pack(anchor=tk.W, pady=(0, 6))
        self.district_list = tk.Listbox(sidebar, height=10, exportselection=False)
        self.district_list.pack(fill=tk.X)
        for i, d in enumerate(DISTRICTS):
            self.district_list.insert(tk.END, f"{i + 1}. {d['name']}")
        self.district_list.selection_set(0)
        self.district_list.bind("<<ListboxSelect>>", self._on_district_select)

        ttk.Button(sidebar, text="Borrar polígono (Supr)", command=self._clear_active_polygon).pack(
            fill=tk.X, pady=(8, 2)
        )
        ttk.Button(sidebar, text="Duplicar desde otro…", command=self._duplicate_from).pack(fill=tk.X, pady=2)

        help_text = (
            "Clic izq: agregar vértice\n"
            "Arrastrar vértice: mover\n"
            "Clic der en vértice: borrar\n"
            "Rueda: zoom\n"
            "Shift+arrastrar: mover vista\n"
            "Teclas 1-6: distrito"
        )
        ttk.Label(sidebar, text=help_text, justify=tk.LEFT, wraplength=200).pack(anchor=tk.W, pady=(16, 0))

        canvas_frame = ttk.Frame(body)
        body.add(canvas_frame, weight=1)
        self.canvas = tk.Canvas(canvas_frame, bg="#1a1a22", highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)
        self.canvas.bind("<Configure>", lambda _e: self._redraw())
        self.canvas.bind("<ButtonPress-1>", self._on_left_down)
        self.canvas.bind("<B1-Motion>", self._on_left_drag)
        self.canvas.bind("<ButtonRelease-1>", self._on_left_up)
        self.canvas.bind("<ButtonPress-3>", self._on_right_down)
        self.canvas.bind("<MouseWheel>", self._on_wheel)
        self.canvas.bind("<Shift-ButtonPress-1>", self._on_pan_start)
        self.canvas.bind("<Shift-B1-Motion>", self._on_pan_move)

    def _bind_keys(self) -> None:
        self.bind("<Control-o>", lambda _e: self._menu_open())
        self.bind("<Control-s>", lambda _e: self._menu_save())
        self.bind("<Control-e>", lambda _e: self._menu_export())
        self.bind("<Delete>", lambda _e: self._clear_active_polygon())
        for i in range(min(6, len(DISTRICTS))):
            self.bind(str(i + 1), lambda _e, idx=i: self._select_district_index(idx))

    def _district_by_id(self, district_id: str) -> dict:
        for d in DISTRICTS:
            if d["id"] == district_id:
                return d
        return DISTRICTS[0]

    def _select_district_index(self, index: int) -> None:
        self.district_list.selection_clear(0, tk.END)
        self.district_list.selection_set(index)
        self.district_list.see(index)
        self.active_id = DISTRICTS[index]["id"]
        self.status.set(f"Editando: {self._district_by_id(self.active_id)['name']}")
        self._redraw()

    def _on_district_select(self, _event: tk.Event | None = None) -> None:
        sel = self.district_list.curselection()
        if not sel:
            return
        self._select_district_index(int(sel[0]))

    def _menu_open(self) -> None:
        path = filedialog.askopenfilename(
            title="Abrir mapa",
            filetypes=[("Imágenes", "*.png *.jpg *.jpeg *.webp"), ("Todos", "*.*")],
        )
        if path:
            self._open_image(Path(path))

    def _open_image(self, path: Path) -> None:
        self.image_path = path
        self.pil_image = Image.open(path).convert("RGBA")
        self.zoom = 1.0
        self.pan_x = 0.0
        self.pan_y = 0.0
        self._fit_image()
        self.status.set(f"Mapa: {path.name} ({self.pil_image.size[0]}×{self.pil_image.size[1]})")
        self._redraw()

    def _fit_image(self) -> None:
        if self.pil_image is None:
            return
        cw = max(self.canvas.winfo_width(), 400)
        ch = max(self.canvas.winfo_height(), 300)
        iw, ih = self.pil_image.size
        self.zoom = min(cw / iw, ch / ih) * 0.95
        self.pan_x = (cw - iw * self.zoom) / 2
        self.pan_y = (ch - ih * self.zoom) / 2

    def _img_to_canvas(self, x: float, y: float) -> tuple[float, float]:
        return x * self.zoom + self.pan_x, y * self.zoom + self.pan_y

    def _canvas_to_img(self, cx: float, cy: float) -> tuple[float, float]:
        return (cx - self.pan_x) / self.zoom, (cy - self.pan_y) / self.zoom

    def _nearest_vertex(self, cx: float, cy: float, threshold: float = 10.0) -> tuple[str, int] | None:
        best: tuple[str, int] | None = None
        best_d = threshold
        districts = DISTRICTS if self.show_all_var.get() else [self._district_by_id(self.active_id)]
        for d in districts:
            did = d["id"]
            pts = self.polygons.get(did, [])
            for i, p in enumerate(norm_to_px(pts, *self._image_size())):
                vx, vy = self._img_to_canvas(p[0], p[1])
                dpt = dist((cx, cy), (vx, vy))
                if dpt < best_d:
                    best_d = dpt
                    best = (did, i)
        return best

    def _image_size(self) -> tuple[int, int]:
        assert self.pil_image is not None
        return self.pil_image.size

    def _on_left_down(self, event: tk.Event) -> None:
        if self.pil_image is None:
            return
        hit = self._nearest_vertex(event.x, event.y)
        if hit:
            self.drag_vertex = hit
            return
        ix, iy = self._canvas_to_img(event.x, event.y)
        w, h = self._image_size()
        ix = max(0, min(w - 1, ix))
        iy = max(0, min(h - 1, iy))
        self.polygons.setdefault(self.active_id, []).append([round(ix / w, 5), round(iy / h, 5)])
        self._redraw()

    def _on_left_drag(self, event: tk.Event) -> None:
        if self.drag_vertex is None or self.pil_image is None:
            return
        did, idx = self.drag_vertex
        w, h = self._image_size()
        ix, iy = self._canvas_to_img(event.x, event.y)
        ix = max(0, min(w - 1, ix))
        iy = max(0, min(h - 1, iy))
        self.polygons[did][idx] = [round(ix / w, 5), round(iy / h, 5)]
        self._redraw()

    def _on_left_up(self, _event: tk.Event) -> None:
        self.drag_vertex = None

    def _on_right_down(self, event: tk.Event) -> None:
        hit = self._nearest_vertex(event.x, event.y, threshold=12)
        if hit:
            did, idx = hit
            if len(self.polygons.get(did, [])) > 3:
                self.polygons[did].pop(idx)
                self._redraw()

    def _on_pan_start(self, event: tk.Event) -> None:
        self.pan_drag_start = (event.x, event.y)

    def _on_pan_move(self, event: tk.Event) -> None:
        if self.pan_drag_start is None:
            return
        dx = event.x - self.pan_drag_start[0]
        dy = event.y - self.pan_drag_start[1]
        self.pan_x += dx
        self.pan_y += dy
        self.pan_drag_start = (event.x, event.y)
        self._redraw()

    def _on_wheel(self, event: tk.Event) -> None:
        if self.pil_image is None:
            return
        factor = 1.1 if event.delta > 0 else 1 / 1.1
        mx, my = event.x, event.y
        ix, iy = self._canvas_to_img(mx, my)
        self.zoom = max(0.05, min(20.0, self.zoom * factor))
        self.pan_x = mx - ix * self.zoom
        self.pan_y = my - iy * self.zoom
        self._redraw()

    def _clear_active_polygon(self) -> None:
        self.polygons[self.active_id] = []
        self._redraw()

    def _duplicate_from(self) -> None:
        names = [d["name"] for d in DISTRICTS if d["id"] != self.active_id]
        if not names:
            return
        win = tk.Toplevel(self)
        win.title("Copiar polígono")
        ttk.Label(win, text="Copiar desde:").pack(padx=12, pady=8)
        var = tk.StringVar(value=names[0])
        combo = ttk.Combobox(win, textvariable=var, values=names, state="readonly")
        combo.pack(padx=12, pady=4)

        def apply() -> None:
            src = next(d for d in DISTRICTS if d["name"] == var.get())
            self.polygons[self.active_id] = [p[:] for p in self.polygons.get(src["id"], [])]
            win.destroy()
            self._redraw()

        ttk.Button(win, text="Copiar", command=apply).pack(pady=10)

    def _redraw(self) -> None:
        self.canvas.delete("all")
        if self.pil_image is None:
            return
        w, h = self.pil_image.size
        disp = self.pil_image.resize(
            (max(1, int(w * self.zoom)), max(1, int(h * self.zoom))), Image.Resampling.BILINEAR
        )
        self.photo = ImageTk.PhotoImage(disp)
        self.canvas.create_image(self.pan_x, self.pan_y, image=self.photo, anchor=tk.NW)

        draw_order = DISTRICTS if self.show_all_var.get() else [self._district_by_id(self.active_id)]
        for d in draw_order:
            did = d["id"]
            pts = self.polygons.get(did, [])
            if len(pts) < 2:
                continue
            canvas_pts: list[float] = []
            for px, py in norm_to_px(pts, w, h):
                cx, cy = self._img_to_canvas(px, py)
                canvas_pts.extend([cx, cy])
            is_active = did == self.active_id
            fill = d["color"] + ("55" if is_active else "33")
            outline = "#ffffff" if is_active else d["color"]
            width = 2 if is_active else 1
            if len(pts) >= 3:
                self.canvas.create_polygon(canvas_pts, fill=fill, outline=outline, width=width)
            else:
                self.canvas.create_line(*canvas_pts, fill=outline, width=width)
            for i, (px, py) in enumerate(norm_to_px(pts, w, h)):
                cx, cy = self._img_to_canvas(px, py)
                r = 5 if is_active else 3
                self.canvas.create_oval(cx - r, cy - r, cx + r, cy + r, fill="#fff", outline=d["color"], width=2)
                if is_active:
                    self.canvas.create_text(cx + 10, cy - 10, text=str(i), fill="#fff", font=("", 9))

    def _serialize(self) -> dict:
        w, h = self._image_size() if self.pil_image else (0, 0)
        return {
            "version": 1,
            "source_image": str(self.image_path) if self.image_path else "",
            "image_size": [w, h],
            "districts": {
                d["id"]: {
                    "display_name": d["name"],
                    "color": d["color"],
                    "points_norm": self.polygons.get(d["id"], []),
                }
                for d in DISTRICTS
            },
        }

    def _menu_save(self) -> None:
        path = filedialog.asksaveasfilename(
            title="Guardar polígonos",
            initialdir=self.json_path.parent,
            initialfile=self.json_path.name,
            defaultextension=".json",
            filetypes=[("JSON", "*.json")],
        )
        if path:
            self._save_json(Path(path))

    def _save_json(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self._serialize(), indent=2, ensure_ascii=False), encoding="utf-8")
        self.json_path = path
        self.status.set(f"Guardado: {path.name}")

    def _load_json(self, path: Path, quiet: bool = False) -> None:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            districts = data.get("districts", {})
            for d in DISTRICTS:
                entry = districts.get(d["id"], {})
                pts = entry.get("points_norm") or entry.get("points")
                if pts:
                    self.polygons[d["id"]] = [p[:] for p in pts]
            self.json_path = path
            if not quiet:
                self.status.set(f"Cargado: {path.name}")
            self._redraw()
        except Exception as exc:
            if not quiet:
                messagebox.showerror("Error", f"No se pudo cargar JSON:\n{exc}")

    def _export_district_png(self, district_id: str, feather: int) -> dict | None:
        if self.pil_image is None:
            return None
        pts_norm = self.polygons.get(district_id, [])
        if len(pts_norm) < 3:
            return None
        w, h = self.pil_image.size
        pts_px = norm_to_px(pts_norm, w, h)
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).polygon(pts_px, fill=255)
        if feather > 0:
            from PIL import ImageFilter

            mask = mask.filter(ImageFilter.GaussianBlur(feather))
        rgba = self.pil_image.copy()
        rgba.putalpha(mask)
        x0, y0, x1, y1 = polygon_bbox(pts_px)
        pad = max(feather, 2)
        x0 = max(0, x0 - pad)
        y0 = max(0, y0 - pad)
        x1 = min(w, x1 + pad)
        y1 = min(h, y1 + pad)
        cropped = rgba.crop((x0, y0, x1, y1))
        return {
            "image": cropped,
            "bbox_px": [x0, y0, x1, y1],
            "bbox_norm": [round(x0 / w, 5), round(y0 / h, 5), round(x1 / w, 5), round(y1 / h, 5)],
            "anchor_norm": [round((x0 + x1) / 2 / w, 5), round((y0 + y1) / 2 / h, 5)],
        }

    def _menu_export(self) -> None:
        if self.pil_image is None:
            messagebox.showwarning("Sin mapa", "Abrí una imagen primero.")
            return
        out = filedialog.askdirectory(
            title="Carpeta de salida para distritos",
            initialdir=str(self.export_dir),
        )
        if not out:
            return
        out_path = Path(out)
        out_path.mkdir(parents=True, exist_ok=True)
        feather = int(self.feather_var.get())
        manifest: dict = {"version": 1, "source_image": str(self.image_path), "districts": {}}
        exported = 0
        for d in DISTRICTS:
            result = self._export_district_png(d["id"], feather)
            if result is None:
                continue
            result["image"].save(out_path / f"{d['id']}.png", "PNG")
            manifest["districts"][d["id"]] = {
                "display_name": d["name"],
                "file": f"{d['id']}.png",
                "size": list(result["image"].size),
                "bbox_px": result["bbox_px"],
                "bbox_norm": result["bbox_norm"],
                "anchor_norm": result["anchor_norm"],
                "points_norm": self.polygons.get(d["id"], []),
            }
            exported += 1
        (out_path / "district_manifest.json").write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        self._export_debug_to(out_path / "_preview_polygons.png")
        self.status.set(f"Exportados {exported} distritos → {out_path}")
        messagebox.showinfo("Exportación", f"Listo: {exported} PNG + district_manifest.json")

    def _export_debug(self) -> None:
        if self.pil_image is None:
            return
        path = filedialog.asksaveasfilename(
            title="Guardar vista previa",
            initialfile="_preview_polygons.png",
            defaultextension=".png",
            filetypes=[("PNG", "*.png")],
        )
        if path:
            self._export_debug_to(Path(path))
            self.status.set("Vista previa guardada")

    def _export_debug_to(self, path: Path) -> None:
        if self.pil_image is None:
            return
        w, h = self.pil_image.size
        debug = self.pil_image.convert("RGBA").copy()
        overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        for d in DISTRICTS:
            pts = norm_to_px(self.polygons.get(d["id"], []), w, h)
            if len(pts) < 3:
                continue
            color = hex_to_rgba(d["color"], 100)
            draw.polygon(pts, fill=color, outline=(255, 255, 255, 220))
            cx = sum(p[0] for p in pts) // len(pts)
            cy = sum(p[1] for p in pts) // len(pts)
            draw.text((cx - 40, cy), d["id"], fill=(255, 255, 255, 255))
        debug = Image.alpha_composite(debug, overlay)
        path.parent.mkdir(parents=True, exist_ok=True)
        debug.save(path, "PNG")


def main() -> None:
    img_arg = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    app = DistrictCropTool(img_arg)
    app.mainloop()


if __name__ == "__main__":
    main()
