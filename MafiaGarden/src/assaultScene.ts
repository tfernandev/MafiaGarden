import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import type { JoystickOutput } from "./joystick";
import { debugEnabled, error, log, logAlways, warn } from "./debugLog";

const MODEL_URL = "/models/soldado_anim.glb";
const TARGET_HEIGHT = 2.2;
/** Mixamo/Blender suele exportar el personaje mirando 90° respecto al movimiento del juego. */
const MODEL_Y_ROTATION = -Math.PI / 2;

export class AssaultScene {
  private readonly container: HTMLElement;
  private readonly statusEl: HTMLElement;
  private readonly renderer: THREE.WebGLRenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera: THREE.PerspectiveCamera;
  private readonly cameraLookAhead = new THREE.Vector3();
  private readonly cameraDesiredPos = new THREE.Vector3();
  private readonly squad = new THREE.Group();
  /** Pivot para balanceo al caminar (sin rig en el GLB) */
  private readonly modelPivot = new THREE.Group();
  private readonly clock = new THREE.Clock();
  private readonly bounds = { minX: -7, maxX: 7, minZ: -2, maxZ: 18 };
  private animId = 0;
  private loaded = false;
  private debugHelpers: THREE.Object3D[] = [];
  private walkPhase = 0;
  private mixer: THREE.AnimationMixer | null = null;
  private walkAction: THREE.AnimationAction | null = null;
  private idleAction: THREE.AnimationAction | null = null;
  private activeLocomotion: THREE.AnimationAction | null = null;

  constructor(containerId: string, statusId: string) {
    const container = document.getElementById(containerId);
    const statusEl = document.getElementById(statusId);
    if (!container || !statusEl) {
      throw new Error("Contenedor o HUD no encontrado");
    }
    this.container = container;
    this.statusEl = statusEl;

    logAlways("Iniciando escena 3D", { debug: debugEnabled, model: MODEL_URL });
    if (debugEnabled) {
      logAlways("Modo debug ON — agregá ?debug=1 o localStorage mafia-debug=1");
    }

    this.scene.background = new THREE.Color(0x2a2d38);
    this.scene.fog = new THREE.Fog(0x2a2d38, 28, 55);

    this.camera = new THREE.PerspectiveCamera(50, 1, 0.1, 120);
    this.updateCamera(1);

    this.renderer = new THREE.WebGLRenderer({
      antialias: true,
      powerPreference: "high-performance",
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.55;
    container.appendChild(this.renderer.domElement);

    this.setupLights();
    this.setupStreet();
    this.squad.add(this.modelPivot);
    this.scene.add(this.squad);
    this.addSpawnMarker();

    window.addEventListener("resize", () => this.onResize());
    this.onResize();
    void this.loadModel();
  }

  private addSpawnMarker(): void {
    if (!debugEnabled) return;
    const marker = new THREE.Mesh(
      new THREE.SphereGeometry(0.35, 12, 12),
      new THREE.MeshBasicMaterial({ color: 0xff6644, wireframe: true }),
    );
    marker.position.set(0, 0.35, 2);
    this.scene.add(marker);
    this.debugHelpers.push(marker);
    log("Marcador naranja = posición inicial del squad (0, 0, 2)");
  }

  private setupLights(): void {
    this.scene.add(new THREE.HemisphereLight(0xb8c4e8, 0x3a3540, 0.75));
    this.scene.add(new THREE.AmbientLight(0xffffff, 0.85));
    const sun = new THREE.DirectionalLight(0xfff8ee, 1.45);
    sun.position.set(6, 20, 8);
    this.scene.add(sun);
    const fill = new THREE.DirectionalLight(0xdde8ff, 0.65);
    fill.position.set(-10, 14, 12);
    this.scene.add(fill);
    const rim = new THREE.DirectionalLight(0xffeedd, 0.35);
    rim.position.set(0, 8, -6);
    this.scene.add(rim);
  }

  private setupStreet(): void {
    const road = new THREE.Mesh(
      new THREE.PlaneGeometry(16, 28),
      new THREE.MeshStandardMaterial({ color: 0x3d3d48, roughness: 0.88 }),
    );
    road.rotation.x = -Math.PI / 2;
    road.position.set(0, 0, 8);
    this.scene.add(road);

    const sidewalk = new THREE.Mesh(
      new THREE.PlaneGeometry(18, 3),
      new THREE.MeshStandardMaterial({ color: 0x4a4a55, roughness: 0.9 }),
    );
    sidewalk.rotation.x = -Math.PI / 2;
    sidewalk.position.set(0, 0.01, -0.5);
    this.scene.add(sidewalk);

    const grid = new THREE.GridHelper(16, 16, 0x5a5a6a, 0x353540);
    grid.position.set(0, 0.03, 8);
    this.scene.add(grid);
  }

  private fixMaterials(root: THREE.Object3D): number {
    let meshCount = 0;
    root.traverse((obj) => {
      if (!(obj instanceof THREE.Mesh)) return;
      meshCount++;
      const mats = Array.isArray(obj.material) ? obj.material : [obj.material];
      for (const mat of mats) {
        if (!mat) continue;
        mat.side = THREE.DoubleSide;
        if ("map" in mat && mat.map) {
          mat.map.colorSpace = THREE.SRGBColorSpace;
          mat.needsUpdate = true;
        }
        if (mat instanceof THREE.MeshStandardMaterial) {
          mat.roughness = Math.min(mat.roughness, 0.82);
          mat.metalness *= 0.35;
          mat.emissive.setHex(0x1a1a22);
          mat.emissiveIntensity = 0.22;
        }
      }
    });
    return meshCount;
  }

  private async loadModel(): Promise<void> {
    const loader = new GLTFLoader();
    logAlways("Cargando GLB…", MODEL_URL);
    this.setStatus("Cargando modelo…");

    try {
      const gltf = await loader.loadAsync(MODEL_URL);
      const model = gltf.scene;
      model.rotation.y = MODEL_Y_ROTATION;

      const boxBefore = new THREE.Box3().setFromObject(model);
      const sizeBefore = boxBefore.getSize(new THREE.Vector3());
      log("BBox antes de escalar", {
        min: boxBefore.min.toArray(),
        max: boxBefore.max.toArray(),
        size: sizeBefore.toArray(),
      });

      const scale = TARGET_HEIGHT / Math.max(sizeBefore.y, 0.001);
      model.scale.setScalar(scale);

      const box = new THREE.Box3().setFromObject(model);
      const center = box.getCenter(new THREE.Vector3());
      model.position.set(-center.x, -box.min.y, -center.z);

      const meshCount = this.fixMaterials(model);
      this.modelPivot.add(model);
      this.squad.position.set(0, 0, 2);

      this.setupGltfAnimations(gltf, model);

      const boxWorld = new THREE.Box3().setFromObject(this.squad);
      const animInfo =
        gltf.animations.length > 0
          ? `${gltf.animations.length} clip(s) GLB`
          : "bob procedural (GLB sin animación)";
      logAlways("Modelo cargado OK", {
        meshes: meshCount,
        scale: scale.toFixed(3),
        animations: gltf.animations.map((c) => c.name),
        animInfo,
        squadPos: this.squad.position.toArray(),
        modelPos: model.position.toArray(),
        worldBox: {
          min: boxWorld.min.toArray(),
          max: boxWorld.max.toArray(),
          size: boxWorld.getSize(new THREE.Vector3()).toArray(),
        },
      });

      if (debugEnabled) {
        const helper = new THREE.Box3Helper(boxWorld, 0x66ff88);
        this.scene.add(helper);
        this.debugHelpers.push(helper);
        const axes = new THREE.AxesHelper(2);
        axes.position.copy(this.squad.position);
        this.scene.add(axes);
        this.debugHelpers.push(axes);
      }

      if (meshCount === 0) {
        warn("GLB sin meshes — archivo vacío o corrupto");
      }

      this.loaded = true;
      this.setStatus(
        `Listo · ${meshCount} mesh · ${animInfo}${debugEnabled ? " · debug" : ""}`,
      );
    } catch (err) {
      error("Falló carga GLB", err);
      this.setStatus("Error GLB — ver consola (F12)");
    }
  }

  private setupGltfAnimations(
    gltf: { animations: THREE.AnimationClip[] },
    model: THREE.Object3D,
  ): void {
    if (gltf.animations.length === 0) {
      logAlways(
        "GLB sin animaciones — caminar con balanceo procedural. Para walk real: Tripo rig o Mixamo.com",
      );
      return;
    }

    this.mixer = new THREE.AnimationMixer(model);
    const names = gltf.animations.map((c) => c.name.toLowerCase());
    const isIdleClip = (n: string) => n.includes("idle") || n.includes("stand");
    const isWalkRunClip = (n: string) =>
      (n.includes("walk") || n.includes("run")) && !n.includes("turn");
    const isTurnClip = (n: string) => n.includes("turning") || n.includes("turn");

    const pickClip = (pred: (n: string, i: number) => boolean) =>
      names.findIndex(pred);

    const idleIdx = pickClip(
      (n) => (n === "idle" || n.includes("idlesoldado")) && !n.includes("mixamo"),
    );
    const idleFallback = idleIdx >= 0 ? idleIdx : pickClip(isIdleClip);

    let walkIdx = pickClip(
      (n, i) => i !== idleFallback && (n === "walking" || n.includes("walking")),
    );
    if (walkIdx < 0) {
      walkIdx = pickClip((n, i) => i !== idleFallback && isWalkRunClip(n));
    }
    if (walkIdx < 0) {
      walkIdx = pickClip((n, i) => i !== idleFallback && isTurnClip(n));
    }
    if (walkIdx < 0 && gltf.animations.length === 1) {
      walkIdx = 0;
    }

    const resolvedIdleIdx = idleFallback;

    if (walkIdx >= 0) {
      this.walkAction = this.mixer.clipAction(gltf.animations[walkIdx]);
      this.walkAction.setLoop(THREE.LoopRepeat, Infinity);
    }
    if (resolvedIdleIdx >= 0) {
      this.idleAction = this.mixer.clipAction(gltf.animations[resolvedIdleIdx]);
      this.idleAction.setLoop(THREE.LoopRepeat, Infinity);
    } else if (this.walkAction) {
      this.activeLocomotion = this.walkAction;
      this.walkAction.play();
    }

    for (const clip of gltf.animations) {
      logAlways("Clip GLB", {
        name: clip.name,
        duration: Number(clip.duration.toFixed(2)),
        tracks: clip.tracks.length,
      });
    }

    logAlways("AnimationMixer listo", {
      clips: gltf.animations.map((c) => c.name),
      idle: resolvedIdleIdx >= 0 ? gltf.animations[resolvedIdleIdx].name : null,
      locomotion: walkIdx >= 0 ? gltf.animations[walkIdx].name : null,
    });

    if (this.idleAction) {
      this.fadeLocomotion(this.idleAction, 0);
    }
  }

  /** Crossfade estándar Three.js (mismo patrón que @react-three/drei useAnimations). */
  private fadeLocomotion(next: THREE.AnimationAction, duration = 0.2): void {
    if (this.activeLocomotion === next) return;
    if (this.activeLocomotion) {
      this.activeLocomotion.fadeOut(duration);
    }
    next.reset().setEffectiveWeight(1).fadeIn(duration).play();
    this.activeLocomotion = next;
  }

  private updateLocomotionAnim(joystick: JoystickOutput, dt: number): void {
    const moving =
      joystick.active &&
      (Math.abs(joystick.x) > 0.08 || Math.abs(joystick.y) > 0.08);

    if (this.mixer) {
      this.mixer.update(dt);
      if (this.walkAction && this.idleAction) {
        const target = moving ? this.walkAction : this.idleAction;
        this.fadeLocomotion(target, 0.18);
        if (moving) {
          this.walkAction.timeScale = 1.15;
        }
      } else if (this.walkAction) {
        if (moving) {
          this.walkAction.setEffectiveWeight(1);
          this.walkAction.timeScale = 1.1;
          if (!this.walkAction.isRunning()) this.walkAction.play();
        } else {
          this.walkAction.setEffectiveWeight(0);
        }
      }
      return;
    }

    if (moving) {
      this.walkPhase += dt * 11;
      const bob = Math.abs(Math.sin(this.walkPhase)) * 0.09;
      this.modelPivot.position.y = bob;
      this.modelPivot.rotation.x = Math.sin(this.walkPhase) * 0.06;
      this.modelPivot.rotation.z = Math.sin(this.walkPhase * 0.5) * 0.03;
    } else {
      this.walkPhase *= 0.85;
      const t = this.clock.elapsedTime;
      this.modelPivot.position.y = Math.sin(t * 2.2) * 0.012;
      this.modelPivot.rotation.x = THREE.MathUtils.lerp(this.modelPivot.rotation.x, 0, dt * 6);
      this.modelPivot.rotation.z = THREE.MathUtils.lerp(this.modelPivot.rotation.z, 0, dt * 6);
    }
  }

  start(joystick: JoystickOutput): void {
    let frame = 0;
    const tick = (): void => {
      this.animId = requestAnimationFrame(tick);
      const dt = Math.min(this.clock.getDelta(), 0.05);
      frame++;

      let moving = false;
      if (this.loaded && joystick.active) {
        const speed = 5.5;
        const dx = joystick.x * speed * dt;
        const dz = -joystick.y * speed * dt;
        moving = Math.abs(dx) + Math.abs(dz) > 0.0001;
        this.squad.position.x = THREE.MathUtils.clamp(
          this.squad.position.x + dx,
          this.bounds.minX,
          this.bounds.maxX,
        );
        this.squad.position.z = THREE.MathUtils.clamp(
          this.squad.position.z + dz,
          this.bounds.minZ,
          this.bounds.maxZ,
        );
        if (moving) {
          this.squad.rotation.y = Math.atan2(dx, dz);
        }
      }

      if (this.loaded) {
        this.updateLocomotionAnim(joystick, dt);
        this.updateCamera(dt);
      }

      if (debugEnabled && frame % 120 === 0 && this.loaded) {
        log("Squad pos", this.squad.position.toArray());
      }

      this.renderer.render(this.scene, this.camera);
    };
    tick();
  }

  dispose(): void {
    cancelAnimationFrame(this.animId);
    this.renderer.dispose();
  }

  /**
   * Tercera persona: atrás y un poco más alto. La cámara sigue con suavizado
   * para que el personaje se vea moverse por la calle (no el mapa deslizándose bajo él).
   */
  private updateCamera(dt: number): void {
    const behind = 5.2;
    const height = 3.4;
    const lookHeight = 1.2;

    const offset = new THREE.Vector3(0, height, -behind);
    offset.applyQuaternion(this.squad.quaternion);
    this.cameraDesiredPos.copy(this.squad.position).add(offset);

    const follow = THREE.MathUtils.clamp(dt * 5.5, 0, 1);
    this.camera.position.lerp(this.cameraDesiredPos, follow);

    this.cameraLookAhead.set(
      this.squad.position.x,
      this.squad.position.y + lookHeight,
      this.squad.position.z,
    );
    this.camera.lookAt(this.cameraLookAhead);
  }

  private onResize(): void {
    const w = this.container.clientWidth;
    const h = this.container.clientHeight;
    log("Resize canvas", { w, h });
    if (w === 0 || h === 0) {
      warn("Canvas 0×0 — el contenedor #game no tiene altura");
      return;
    }
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
  }

  private setStatus(text: string): void {
    this.statusEl.textContent = text;
  }
}
