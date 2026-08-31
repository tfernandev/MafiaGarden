#!/usr/bin/env python3
"""Test Blender MCP connection from WSL2"""
import socket
import json

HOST = "192.168.112.1"
PORT = 9877

def test_connection():
    print(f"Testing connection to Blender MCP at {HOST}:{PORT}...")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        sock.connect((HOST, PORT))
        print("✓ Connected to Blender MCP")
        
        # Send a simple command
        command = {
            "tool": "get_addon_status",
            "arguments": {}
        }
        
        sock.sendall(json.dumps(command).encode() + b"\n")
        print("✓ Sent command: get_addon_status")
        
        # Receive response
        response = sock.recv(4096).decode()
        print(f"✓ Received response: {response[:200]}...")
        
        sock.close()
        print("\n✓ MCP connection test PASSED")
        return True
        
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    exit(0 if success else 1)
