#!/usr/bin/env python3
"""Loads the web build in a real browser and reports what happened.

Serves build/web on localhost, opens it in headless Chrome, waits for the
engine to start and the first screen to draw, then saves build/web_smoke.png and fails if the page
logged an error. Look at the picture: a black canvas passes the log check too.

    mise run export && mise run web-smoke

Needs Chrome or Chromium and `pip install playwright` (the browser itself is
the one already installed; nothing is downloaded).
"""
import functools
import http.server
import pathlib
import shutil
import sys
import threading

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "build" / "web"
SHOT = ROOT / "build" / "web_smoke.png"
WAIT_MS = 90_000
SETTLE_MS = 20_000
BAD = ("SCRIPT ERROR", "USER ERROR", "ERROR:", "Uncaught", "abort(")


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def main() -> int:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("WEB SMOKE SKIPPED: pip install playwright", file=sys.stderr)
        return 2
    chrome = next((p for p in map(shutil.which, ("google-chrome", "chromium", "chromium-browser")) if p), None)
    if chrome is None:
        print("WEB SMOKE SKIPPED: no Chrome or Chromium on this machine", file=sys.stderr)
        return 2
    if not (WEB / "index.html").exists():
        print("WEB SMOKE FAILED: run mise run export first", file=sys.stderr)
        return 1

    handler = functools.partial(Quiet, directory=str(WEB))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = "http://127.0.0.1:%d/index.html" % server.server_address[1]

    logs = []
    with sync_playwright() as p:
        browser = p.chromium.launch(
            executable_path=chrome,
            args=["--no-sandbox", "--no-proxy-server", "--use-angle=swiftshader",
                  "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
        )
        page = browser.new_page(viewport={"width": 1280, "height": 720})
        page.on("console", lambda m: logs.append("%s: %s" % (m.type, m.text)))
        page.on("pageerror", lambda e: logs.append("pageerror: %s" % e))
        started = True
        try:
            # The engine prints its version once it runs; then let the title draw.
            with page.expect_console_message(lambda m: "Godot Engine v" in m.text, timeout=WAIT_MS):
                page.goto(url)
            page.wait_for_timeout(SETTLE_MS)
        except Exception as error:  # the picture and the log say why
            started = False
            logs.append("timeout: %s" % str(error).splitlines()[0])
        page.screenshot(path=str(SHOT))
        browser.close()
    server.shutdown()

    (ROOT / "build" / "web_smoke.log").write_text("\n".join(logs), encoding="utf-8")
    errors = [line for line in logs if line.startswith(("error", "pageerror", "timeout")) or any(b in line for b in BAD)]
    if errors or not started:
        print("\n".join(errors[:12]), file=sys.stderr)
        print("WEB SMOKE FAILED: see build/web_smoke.log and build/web_smoke.png", file=sys.stderr)
        return 1
    print("WEB SMOKE OK: %d console lines, picture in build/web_smoke.png" % len(logs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
