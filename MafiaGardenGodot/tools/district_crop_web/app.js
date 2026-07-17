const DISTRICTS = [
  { id: "barrio_viejo", name: "Barrio Viejo", color: "#c88c50" },
  { id: "mansion_norte", name: "Mansión Norte", color: "#78c850" },
  { id: "centro", name: "Centro", color: "#7878ff" },
  { id: "villa_roja", name: "Villa Roja", color: "#ff5050" },
  { id: "mercado_sur", name: "Mercado Sur", color: "#ffc83c" },
  { id: "puerto_norte", name: "Puerto Norte", color: "#50a0ff" },
];

const DEFAULT_POLYGONS = {
  barrio_viejo: [[0.02, 0.02], [0.48, 0.02], [0.48, 0.48], [0.02, 0.48]],
  mansion_norte: [[0.52, 0.02], [0.98, 0.02], [0.98, 0.40], [0.52, 0.40]],
  centro: [[0.02, 0.52], [0.45, 0.52], [0.45, 0.95], [0.02, 0.95]],
  villa_roja: [[0.50, 0.52], [0.64, 0.52], [0.64, 0.98], [0.50, 0.98]],
  mercado_sur: [[0.62, 0.58], [0.98, 0.58], [0.98, 0.98], [0.62, 0.98]],
  puerto_norte: [[0.48, 0.38], [0.98, 0.38], [0.98, 0.98], [0.48, 0.98]],
};

const state = {
  image: null,
  imageName: "",
  polygons: structuredClone(DEFAULT_POLYGONS),
  activeId: DISTRICTS[0].id,
  zoom: 1,
  panX: 0,
  panY: 0,
  dragVertex: null,
  panning: false,
  panStart: null,
  spaceDown: false,
};

const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
const wrap = document.getElementById("canvasWrap");
const statusEl = document.getElementById("status");
const districtList = document.getElementById("districtList");
const featherEl = document.getElementById("feather");
const showAllEl = document.getElementById("showAll");

function setStatus(msg) {
  statusEl.textContent = msg;
}

function hexAlpha(hex, a) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${a})`;
}

function buildDistrictList() {
  districtList.innerHTML = "";
  DISTRICTS.forEach((d, i) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "district-btn" + (d.id === state.activeId ? " active" : "");
    btn.dataset.id = d.id;
    const count = (state.polygons[d.id] || []).length;
    btn.innerHTML = `
      <span class="swatch" style="background:${d.color}"></span>
      <span>
        <div>${i + 1}. ${d.name}</div>
        <div class="meta">${count} vértices</div>
      </span>`;
    btn.addEventListener("click", () => selectDistrict(d.id));
    districtList.appendChild(btn);
  });
}

function selectDistrict(id) {
  state.activeId = id;
  const d = DISTRICTS.find((x) => x.id === id);
  setStatus(`Editando: ${d.name}`);
  buildDistrictList();
  draw();
}

function resizeCanvas() {
  const rect = wrap.getBoundingClientRect();
  canvas.width = Math.max(1, Math.floor(rect.width * devicePixelRatio));
  canvas.height = Math.max(1, Math.floor(rect.height * devicePixelRatio));
  ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  draw();
}

function fitImage() {
  if (!state.image) return;
  const rect = wrap.getBoundingClientRect();
  const iw = state.image.width;
  const ih = state.image.height;
  state.zoom = Math.min(rect.width / iw, rect.height / ih) * 0.95;
  state.panX = (rect.width - iw * state.zoom) / 2;
  state.panY = (rect.height - ih * state.zoom) / 2;
}

function imgToScreen(x, y) {
  return [x * state.zoom + state.panX, y * state.zoom + state.panY];
}

function screenToImg(sx, sy) {
  return [(sx - state.panX) / state.zoom, (sy - state.panY) / state.zoom];
}

function normToImg(points) {
  if (!state.image) return [];
  const w = state.image.width;
  const h = state.image.height;
  return points.map(([nx, ny]) => [nx * w, ny * h]);
}

function imgToNorm(points) {
  if (!state.image) return [];
  const w = state.image.width;
  const h = state.image.height;
  return points.map(([x, y]) => [round5(x / w), round5(y / h)]);
}

function round5(n) {
  return Math.round(n * 100000) / 100000;
}

function getCanvasPoint(e) {
  const rect = canvas.getBoundingClientRect();
  return [e.clientX - rect.left, e.clientY - rect.top];
}

function nearestVertex(sx, sy, threshold = 10) {
  let best = null;
  let bestD = threshold;
  const list = showAllEl.checked ? DISTRICTS : DISTRICTS.filter((d) => d.id === state.activeId);
  for (const d of list) {
    const pts = normToImg(state.polygons[d.id] || []);
    pts.forEach(([ix, iy], i) => {
      const [cx, cy] = imgToScreen(ix, iy);
      const dist = Math.hypot(cx - sx, cy - sy);
      if (dist < bestD) {
        bestD = dist;
        best = { id: d.id, index: i };
      }
    });
  }
  return best;
}

function draw() {
  const rect = wrap.getBoundingClientRect();
  ctx.clearRect(0, 0, rect.width, rect.height);
  if (!state.image) {
    ctx.fillStyle = "#555";
    ctx.font = "16px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Abrí un mapa (PNG/JPG)", rect.width / 2, rect.height / 2);
    return;
  }

  const iw = state.image.width;
  const ih = state.image.height;
  const [dx, dy] = imgToScreen(0, 0);
  ctx.drawImage(state.image, dx, dy, iw * state.zoom, ih * state.zoom);

  const order = showAllEl.checked ? DISTRICTS : DISTRICTS.filter((d) => d.id === state.activeId);
  for (const d of order) {
    const pts = normToImg(state.polygons[d.id] || []);
    if (pts.length < 2) continue;
    const active = d.id === state.activeId;
    const screenPts = pts.map(([x, y]) => imgToScreen(x, y));

    ctx.beginPath();
    screenPts.forEach(([x, y], i) => (i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)));
    if (pts.length >= 3) {
      ctx.closePath();
      ctx.fillStyle = hexAlpha(d.color, active ? 0.35 : 0.18);
      ctx.fill();
    }
    ctx.strokeStyle = active ? "#fff" : d.color;
    ctx.lineWidth = active ? 2 : 1;
    ctx.stroke();

    screenPts.forEach(([x, y], i) => {
      ctx.beginPath();
      ctx.arc(x, y, active ? 5 : 3.5, 0, Math.PI * 2);
      ctx.fillStyle = "#fff";
      ctx.fill();
      ctx.strokeStyle = d.color;
      ctx.lineWidth = 2;
      ctx.stroke();
      if (active) {
        ctx.fillStyle = "#fff";
        ctx.font = "10px sans-serif";
        ctx.fillText(String(i), x + 8, y - 6);
      }
    });
  }
}

function loadImage(file) {
  const reader = new FileReader();
  reader.onload = () => {
    const img = new Image();
    img.onload = () => {
      state.image = img;
      state.imageName = file.name;
      fitImage();
      setStatus(`Mapa: ${file.name} (${img.width}×${img.height})`);
      draw();
    };
    img.src = reader.result;
  };
  reader.readAsDataURL(file);
}

function serialize() {
  return {
    version: 1,
    source_image: state.imageName,
    image_size: state.image ? [state.image.width, state.image.height] : [0, 0],
    districts: Object.fromEntries(
      DISTRICTS.map((d) => [
        d.id,
        {
          display_name: d.name,
          color: d.color,
          points_norm: state.polygons[d.id] || [],
        },
      ])
    ),
  };
}

function loadFromJson(data) {
  const districts = data.districts || {};
  for (const d of DISTRICTS) {
    const entry = districts[d.id];
    if (!entry) continue;
    const pts = entry.points_norm || entry.points;
    if (Array.isArray(pts)) state.polygons[d.id] = pts.map((p) => [...p]);
  }
  buildDistrictList();
  draw();
  setStatus("Polígonos cargados desde JSON");
}

function downloadBlob(blob, filename) {
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function polygonBBox(pts) {
  const xs = pts.map((p) => p[0]);
  const ys = pts.map((p) => p[1]);
  return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
}

function exportDistrict(districtId, feather) {
  const ptsNorm = state.polygons[districtId] || [];
  if (ptsNorm.length < 3 || !state.image) return null;

  const w = state.image.width;
  const h = state.image.height;
  const pts = normToImg(ptsNorm);
  const [x0, y0, x1, y1] = polygonBBox(pts);
  const pad = Math.max(feather, 2);
  const bx0 = Math.max(0, Math.floor(x0 - pad));
  const by0 = Math.max(0, Math.floor(y0 - pad));
  const bx1 = Math.min(w, Math.ceil(x1 + pad));
  const by1 = Math.min(h, Math.ceil(y1 + pad));
  const cw = bx1 - bx0;
  const ch = by1 - by0;

  const mask = document.createElement("canvas");
  mask.width = w;
  mask.height = h;
  const mctx = mask.getContext("2d");
  mctx.fillStyle = "#000";
  mctx.fillRect(0, 0, w, h);
  mctx.fillStyle = "#fff";
  mctx.beginPath();
  pts.forEach(([x, y], i) => (i === 0 ? mctx.moveTo(x, y) : mctx.lineTo(x, y)));
  mctx.closePath();
  mctx.fill();
  if (feather > 0) {
    mctx.filter = `blur(${feather}px)`;
    mctx.globalCompositeOperation = "source-in";
    mctx.drawImage(mask, 0, 0);
    mctx.filter = "none";
    mctx.globalCompositeOperation = "source-over";
  }

  const out = document.createElement("canvas");
  out.width = cw;
  out.height = ch;
  const octx = out.getContext("2d");
  octx.drawImage(state.image, bx0, by0, cw, ch, 0, 0, cw, ch);
  octx.globalCompositeOperation = "destination-in";
  octx.drawImage(mask, bx0, by0, cw, ch, 0, 0, cw, ch);

  return {
    canvas: out,
    bbox_px: [bx0, by0, bx1, by1],
    bbox_norm: ptsNorm.length ? [round5(bx0 / w), round5(by0 / h), round5(bx1 / w), round5(by1 / h)] : [],
    anchor_norm: [round5((bx0 + bx1) / 2 / w), round5((by0 + by1) / 2 / h)],
  };
}

async function exportAll() {
  if (!state.image) {
    alert("Abrí un mapa primero.");
    return;
  }
  const feather = parseInt(featherEl.value, 10) || 0;
  const manifest = {
    version: 1,
    source_image: state.imageName,
    image_size: [state.image.width, state.image.height],
    districts: {},
  };
  let count = 0;
  for (const d of DISTRICTS) {
    const result = exportDistrict(d.id, feather);
    if (!result) continue;
    const blob = await new Promise((res) => result.canvas.toBlob(res, "image/png"));
    downloadBlob(blob, `${d.id}.png`);
    manifest.districts[d.id] = {
      display_name: d.name,
      file: `${d.id}.png`,
      size: [result.canvas.width, result.canvas.height],
      bbox_px: result.bbox_px,
      bbox_norm: result.bbox_norm,
      anchor_norm: result.anchor_norm,
      points_norm: state.polygons[d.id],
    };
    count++;
    await new Promise((r) => setTimeout(r, 120));
  }
  const jsonBlob = new Blob([JSON.stringify(manifest, null, 2)], { type: "application/json" });
  downloadBlob(jsonBlob, "district_manifest.json");
  exportPreview("_preview_polygons.png");
  setStatus(`Exportados ${count} distritos + manifest`);
}

function exportPreview(filename) {
  if (!state.image) return;
  const w = state.image.width;
  const h = state.image.height;
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  const cctx = c.getContext("2d");
  cctx.drawImage(state.image, 0, 0);
  for (const d of DISTRICTS) {
    const pts = normToImg(state.polygons[d.id] || []);
    if (pts.length < 3) continue;
    cctx.beginPath();
    pts.forEach(([x, y], i) => (i === 0 ? cctx.moveTo(x, y) : cctx.lineTo(x, y)));
    cctx.closePath();
    cctx.fillStyle = hexAlpha(d.color, 0.35);
    cctx.fill();
    cctx.strokeStyle = "#fff";
    cctx.lineWidth = 2;
    cctx.stroke();
    const cx = pts.reduce((s, p) => s + p[0], 0) / pts.length;
    const cy = pts.reduce((s, p) => s + p[1], 0) / pts.length;
    cctx.fillStyle = "#fff";
    cctx.font = "bold 18px sans-serif";
    cctx.fillText(d.id, cx - 40, cy);
  }
  c.toBlob((blob) => downloadBlob(blob, filename));
}

// Events
document.getElementById("fileInput").addEventListener("change", (e) => {
  const file = e.target.files?.[0];
  if (file) loadImage(file);
});

document.getElementById("jsonInput").addEventListener("change", (e) => {
  const file = e.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      loadFromJson(JSON.parse(reader.result));
    } catch (err) {
      alert("JSON inválido: " + err.message);
    }
  };
  reader.readAsText(file);
  e.target.value = "";
});

document.getElementById("btnLoadJson").addEventListener("click", () => document.getElementById("jsonInput").click());

document.getElementById("btnSaveJson").addEventListener("click", () => {
  const blob = new Blob([JSON.stringify(serialize(), null, 2)], { type: "application/json" });
  downloadBlob(blob, "district_polygons.json");
  setStatus("JSON guardado");
});

document.getElementById("btnExportAll").addEventListener("click", exportAll);
document.getElementById("btnPreview").addEventListener("click", () => exportPreview("_preview_polygons.png"));
document.getElementById("btnClear").addEventListener("click", () => {
  state.polygons[state.activeId] = [];
  buildDistrictList();
  draw();
});

showAllEl.addEventListener("change", draw);
featherEl.addEventListener("input", draw);
window.addEventListener("resize", resizeCanvas);

canvas.addEventListener("contextmenu", (e) => e.preventDefault());

canvas.addEventListener("wheel", (e) => {
  e.preventDefault();
  if (!state.image) return;
  const [sx, sy] = getCanvasPoint(e);
  const [ix, iy] = screenToImg(sx, sy);
  const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1;
  state.zoom = Math.max(0.05, Math.min(20, state.zoom * factor));
  state.panX = sx - ix * state.zoom;
  state.panY = sy - iy * state.zoom;
  draw();
}, { passive: false });

canvas.addEventListener("mousedown", (e) => {
  const [sx, sy] = getCanvasPoint(e);

  if (e.button === 2) {
    const hit = nearestVertex(sx, sy, 12);
    if (!hit) return;
    const pts = state.polygons[hit.id];
    if (pts.length <= 3) return;
    pts.splice(hit.index, 1);
    buildDistrictList();
    draw();
    return;
  }

  if (state.spaceDown || e.button === 1) {
    state.panning = true;
    state.panStart = [sx - state.panX, sy - state.panY];
    wrap.classList.add("panning");
    return;
  }
  if (!state.image || e.button !== 0) return;

  const hit = nearestVertex(sx, sy);
  if (hit) {
    state.dragVertex = hit;
    return;
  }

  const [ix, iy] = screenToImg(sx, sy);
  const w = state.image.width;
  const h = state.image.height;
  if (ix < 0 || iy < 0 || ix >= w || iy >= h) return;
  if (!state.polygons[state.activeId]) state.polygons[state.activeId] = [];
  state.polygons[state.activeId].push([round5(ix / w), round5(iy / h)]);
  buildDistrictList();
  draw();
});

canvas.addEventListener("mousemove", (e) => {
  const [sx, sy] = getCanvasPoint(e);
  if (state.panning && state.panStart) {
    state.panX = sx - state.panStart[0];
    state.panY = sy - state.panStart[1];
    draw();
    return;
  }
  if (!state.dragVertex || !state.image) return;
  const [ix, iy] = screenToImg(sx, sy);
  const w = state.image.width;
  const h = state.image.height;
  const { id, index } = state.dragVertex;
  state.polygons[id][index] = [
    round5(Math.max(0, Math.min(w - 1, ix)) / w),
    round5(Math.max(0, Math.min(h - 1, iy)) / h),
  ];
  draw();
});

canvas.addEventListener("mouseup", () => {
  state.dragVertex = null;
  state.panning = false;
  state.panStart = null;
  wrap.classList.remove("panning");
  buildDistrictList();
});

window.addEventListener("keydown", (e) => {
  if (e.code === "Space") {
    state.spaceDown = true;
    wrap.classList.add("panning");
  }
  if (e.key >= "1" && e.key <= "6") {
    const idx = parseInt(e.key, 10) - 1;
    if (DISTRICTS[idx]) selectDistrict(DISTRICTS[idx].id);
  }
  if (e.key === "Delete" || e.key === "Backspace") {
    state.polygons[state.activeId] = [];
    buildDistrictList();
    draw();
  }
  if (e.ctrlKey && e.key === "s") {
    e.preventDefault();
    document.getElementById("btnSaveJson").click();
  }
});

window.addEventListener("keyup", (e) => {
  if (e.code === "Space") {
    state.spaceDown = false;
    wrap.classList.remove("panning");
  }
});

// Init
buildDistrictList();
resizeCanvas();
selectDistrict(state.activeId);

// Cargar JSON embebido si existe (opcional vía fetch local)
fetch("district_polygons.json")
  .then((r) => (r.ok ? r.json() : null))
  .then((data) => data && loadFromJson(data))
  .catch(() => {});
