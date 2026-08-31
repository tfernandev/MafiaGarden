import bpy
import blender_mcp

LAB_PORT = 9877
LAB_HOST = "0.0.0.0"

# Stop existing server if running
existing = getattr(bpy.types, "blendermcp_server", None)
if existing and getattr(existing, "running", False):
    existing.stop()
    print("Stopped existing MCP server")

# Configure scene settings
scene = bpy.context.scene
scene.blendermcp_port = LAB_PORT
scene.blendermcp_auto_start_server = False  # Don't auto-start, we'll start manually
print(f"Configured MCP port: {LAB_PORT}")

# Start new server
server = blender_mcp.BlenderMCPServer(port=LAB_PORT, host=LAB_HOST)
server.start()
bpy.types.blendermcp_server = server
print(f"Blender Lab MCP listening on {LAB_HOST}:{LAB_PORT}")
