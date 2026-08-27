# Rifle animation MCP connection gate

## Result

**Blocked — connection gate not passed.** No Blender or project asset was
opened, edited, or written.

## Endpoint evidence

- Configured MCP tool namespace: `blender_lab`.
- Read-only probes attempted: `get_addon_status` and `get_scene_info`.
- Both probes failed with `Transport closed`.
- Lab file identity: unavailable because the endpoint could not be reached.
- Endpoint port: unavailable and therefore not proven distinct.
- Conflicting active ports checked: the local process table and TCP listener
  table exposed no Blender/MCP process or listener to compare.
- Screenshot: unavailable because the viewport endpoint shares the closed
  transport. No screenshot call was made after the connection failure.

## Gate disposition

The configured `blender_lab` name suggests intended lab isolation, but a name is
not sufficient evidence of a dedicated Blender instance or a distinct port.
Before the inspection gate can be authorized, start/connect the dedicated lab
Blender instance and provide a verifiable lab file identity and port that can be
compared with other active Blender chats.
