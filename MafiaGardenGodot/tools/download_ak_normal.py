"""Download CC0 AK-47 (Lamoot / OpenGameArt) for proportion-correct grip."""
from __future__ import annotations

import os
import re
import urllib.request

OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..",
    "models",
    "weapons",
    "ak_normal",
)
os.makedirs(OUT, exist_ok=True)

PAGE = "https://opengameart.org/content/high-poly-ak-47"
req = urllib.request.Request(PAGE, headers={"User-Agent": "Mozilla/5.0"})
html = urllib.request.urlopen(req, timeout=60).read().decode("utf-8", "replace")
urls = sorted(
    set(
        re.findall(
            r'https://opengameart.org/sites/default/files/[^"\s>]+\.(?:obj|blend|zip|mtl)',
            html,
        )
    )
)
print("found", urls)
if not urls:
    # known OGA paths
    urls = [
        "https://opengameart.org/sites/default/files/highpoly_ak47.obj",
        "https://opengameart.org/sites/default/files/highpoly_ak47.blend",
    ]

for url in urls:
    name = url.rsplit("/", 1)[-1].split("?", 1)[0]
    dest = os.path.join(OUT, name)
    print("GET", url, "->", dest)
    try:
        urllib.request.urlretrieve(url, dest)
        print("  bytes", os.path.getsize(dest))
    except Exception as e:
        print("  FAIL", e)
