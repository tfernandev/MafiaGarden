const PREFIX = "[MafiaGarden]";

export const debugEnabled =
  import.meta.env.DEV &&
  (new URLSearchParams(location.search).has("debug") ||
    localStorage.getItem("mafia-debug") === "1");

export function log(...args: unknown[]): void {
  if (!debugEnabled) return;
  console.log(PREFIX, ...args);
}

export function logAlways(...args: unknown[]): void {
  console.log(PREFIX, ...args);
}

export function warn(...args: unknown[]): void {
  console.warn(PREFIX, ...args);
}

export function error(...args: unknown[]): void {
  console.error(PREFIX, ...args);
}
