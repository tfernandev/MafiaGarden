import "./styles.css";
import { AssaultScene } from "./assaultScene";
import { logAlways } from "./debugLog";
import { VirtualJoystick } from "./joystick";

logAlways("MafiaGarden asalto proto — consola F12 para logs");

const joystick = new VirtualJoystick("joystick-zone", "joystick-knob");
const scene = new AssaultScene("game", "status");
scene.start(joystick.output);
