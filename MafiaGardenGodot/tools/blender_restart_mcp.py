import bpy
import blender_mcp
import importlib

LAB_PORT = 9877
LAB_HOST = "0.0.0.0"

print("=== Blender MCP Restart Script ===")

# Step 1: Stop existing server
existing = getattr(bpy.types, "blendermcp_server", None)
if existing:
    if getattr(existing, "running", False):
        existing.stop()
        print("✓ Stopped existing MCP server")
    else:
        print("✓ Server exists but not running")
else:
    print("✓ No existing server found")

# Step 2: Unregister addon
try:
    blender_mcp.unregister()
    print("✓ Unregistered BlenderMCP addon")
except:
    print("✓ Addon already unregistered")

# Step 3: Modify addon preferences to use correct port
if hasattr(bpy, "context") and hasattr(bpy.context, "preferences"):
    prefs = bpy.context.preferences.addons.get("blender_mcp")
    if prefs and hasattr(prefs, "preferences"):
        prefs.preferences.port = LAB_PORT
        prefs.preferences.host = LAB_HOST
        print(f"✓ Set addon preferences to {LAB_HOST}:{LAB_PORT}")

# Step 4: Re-register addon with new settings
try:
    blender_mcp.register()
    print("✓ Registered BlenderMCP addon")
except Exception as e:
    print(f"✗ Failed to register addon: {e}")

# Step 5: Start new server
try:
    server = blender_mcp.BlenderMCPServer(port=LAB_PORT, host=LAB_HOST)
    server.start()
    bpy.types.blendermcp_server = server
    print(f"✓ Started MCP server on {LAB_HOST}:{LAB_PORT}")
except Exception as e:
    print(f"✗ Failed to start server: {e}")

print("=== Script Complete ===")
