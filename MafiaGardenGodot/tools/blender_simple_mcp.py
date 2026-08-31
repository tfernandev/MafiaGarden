import bpy
import blender_mcp

LAB_PORT = 9877
LAB_HOST = "0.0.0.0"

print("Starting Blender MCP on 0.0.0.0:9877...")

# Start server directly
server = blender_mcp.BlenderMCPServer(port=LAB_PORT, host=LAB_HOST)
server.start()
bpy.types.blendermcp_server = server

print(f"Blender MCP running on {LAB_HOST}:{LAB_PORT}")
