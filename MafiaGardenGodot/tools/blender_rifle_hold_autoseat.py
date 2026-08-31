"""Back-compat: current-frame seat check + optional inside push.

Full 5-layer sweep lives in blender_rifle_hold_validate.py
  run_name='__main__'  → static + Idle/Walk/Fire + transitions + regression
  run_name='autoseat'  → this file's behaviour
"""
from __future__ import annotations

import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).with_name("blender_rifle_hold_validate.py")), run_name="autoseat")
