import bpy
import blender_mcp
import time
import sys

LAB_PORT = 9877
LAB_HOST = "0.0.0.0"

print("=== Blender MCP Keep-Alive Script ===")

# Start MCP server
server = blender_mcp.BlenderMCPServer(port=LAB_PORT, host=LAB_HOST)
server.start()
bpy.types.blendermcp_server = server
print(f"MCP server started on {LAB_HOST}:{LAB_PORT}")

# Keep script running
print("Script will keep running. Press Ctrl+C in console to stop.")
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Stopping MCP server...")
    server.stop()
    print("MCP server stopped")
