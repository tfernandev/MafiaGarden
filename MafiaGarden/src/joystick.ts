export type JoystickOutput = {
  x: number;
  y: number;
  active: boolean;
};

export class VirtualJoystick {
  readonly output: JoystickOutput = { x: 0, y: 0, active: false };

  private readonly zone: HTMLElement;
  private readonly knob: HTMLElement;
  private readonly maxRadius = 42;
  private pointerId: number | null = null;
  private originX = 0;
  private originY = 0;

  constructor(zoneId: string, knobId: string) {
    const zone = document.getElementById(zoneId);
    const knob = document.getElementById(knobId);
    if (!zone || !knob) {
      throw new Error("Joystick DOM no encontrado");
    }
    this.zone = zone;
    this.knob = knob;

    zone.addEventListener("pointerdown", (e) => this.onDown(e));
    zone.addEventListener("pointermove", (e) => this.onMove(e));
    zone.addEventListener("pointerup", (e) => this.onUp(e));
    zone.addEventListener("pointercancel", (e) => this.onUp(e));
  }

  private onDown(e: PointerEvent): void {
    if (this.pointerId !== null) return;
    this.pointerId = e.pointerId;
    this.zone.setPointerCapture(e.pointerId);
    const rect = this.zone.getBoundingClientRect();
    this.originX = rect.left + rect.width / 2;
    this.originY = rect.top + rect.height / 2;
    this.output.active = true;
    this.updateFromClient(e.clientX, e.clientY);
  }

  private onMove(e: PointerEvent): void {
    if (this.pointerId !== e.pointerId) return;
    this.updateFromClient(e.clientX, e.clientY);
  }

  private onUp(e: PointerEvent): void {
    if (this.pointerId !== e.pointerId) return;
    this.pointerId = null;
    this.output.active = false;
    this.output.x = 0;
    this.output.y = 0;
    this.knob.style.transform = "translate(0px, 0px)";
  }

  private updateFromClient(clientX: number, clientY: number): void {
    let dx = clientX - this.originX;
    let dy = clientY - this.originY;
    const len = Math.hypot(dx, dy);
    if (len > this.maxRadius) {
      const s = this.maxRadius / len;
      dx *= s;
      dy *= s;
    }
    this.output.x = dx / this.maxRadius;
    this.output.y = dy / this.maxRadius;
    this.knob.style.transform = `translate(${dx}px, ${dy}px)`;
  }
}
