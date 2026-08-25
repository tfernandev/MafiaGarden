# SwarmForge for JuegosMobile

This is a project-local SwarmForge configuration for the Blender → Godot animation
feature. SwarmForge coordinates role-based Codex agents in separate Git worktrees;
it does not replace Blender, Godot, or their MCP connections.

## Roles

- `animation-director`: specification and safe sequencing.
- `blender-rigger`: the only role that writes through Blender MCP.
- `godot-integrator`: creates the modular runtime lab and reusable attachment code.
- `visual-qa`: reviews Godot captures and logs, then accepts or rejects results.

## Before the first run

1. Create a clean, committed baseline. SwarmForge worktrees start from commits and
   cannot see uncommitted Blender/Godot changes in the main working tree.
2. Configure one dedicated Blender lab server on a different port from any other
   Blender chat, for example `9877`, and configure a distinct Codex MCP entry for
   that port. Confirm the two MCP entries return different `.blend` paths.
3. Keep the lab asset separate from production assets. The rigger creates
   candidates; the integrator only consumes candidates handed off by Git.
4. From Ubuntu/WSL at the repository root, run `./swarm` after the SwarmForge
   launcher scripts have been installed.

## Why the baseline is mandatory

The current repository contains active uncommitted art, calibration, and Godot
changes. Launching a swarm now would give its worktree agents an older committed
snapshot and could lead to incompatible edits. Do not launch it until the operator
chooses a checkpoint commit or explicitly authorizes a disposable clean branch.
