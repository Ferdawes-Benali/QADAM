"""Capture dashboard screenshots (used for docs/screenshots and the pitch deck). Requires a running hub."""
import sys
from playwright.sync_api import sync_playwright

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
OUT = sys.argv[2] if len(sys.argv) > 2 else "docs/screenshots"
W = int(sys.argv[3]) if len(sys.argv) > 3 else 1440

with sync_playwright() as p:
    b = p.chromium.launch(executable_path="/opt/pw-browsers/chromium-1194/chrome-linux/chrome" if False else None)
    pg = b.new_page(viewport={"width": W, "height": 900}, device_scale_factor=2 if W > 800 else 3)
    errors = []
    pg.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.goto(BASE + "/#/login"); pg.wait_for_timeout(600)
    pg.screenshot(path=f"{OUT}/dash-login-{W}.png")
    pg.fill("input[name=u]", "dr.demo"); pg.fill("input[name=p]", "qadam-demo-2026"); pg.click("button[type=submit]")
    pg.wait_for_timeout(1500)
    pg.screenshot(path=f"{OUT}/dash-overview-{W}.png", full_page=True)
    pg.goto(BASE + "/#/alerts"); pg.wait_for_timeout(900)
    pg.screenshot(path=f"{OUT}/dash-alerts-{W}.png", full_page=True)
    first = pg.locator("tr[data-href]").first.get_attribute("data-href")
    pg.goto(BASE + "/" + first); pg.wait_for_timeout(1200)
    pg.screenshot(path=f"{OUT}/dash-alert-detail-{W}.png", full_page=True)
    pg.goto(BASE + "/#/patients"); pg.wait_for_timeout(900)
    pg.screenshot(path=f"{OUT}/dash-patients-{W}.png", full_page=True)
    pg.goto(BASE + "/#/patients/QDM-2048"); pg.wait_for_timeout(4000)
    pg.screenshot(path=f"{OUT}/dash-patient-live-{W}.png", full_page=True)
    pg.goto(BASE + "/#/patients/QDM-1001"); pg.wait_for_timeout(1200)
    pg.click("#gen"); pg.wait_for_timeout(1200)
    pg.screenshot(path=f"{OUT}/dash-patient-summary-{W}.png", full_page=True)
    pg.goto(BASE + "/#/devices"); pg.wait_for_timeout(1200)
    pg.screenshot(path=f"{OUT}/dash-devices-{W}.png", full_page=True)
    pg.goto(BASE + "/#/audit"); pg.wait_for_timeout(900); pg.click("#verify"); pg.wait_for_timeout(600)
    pg.screenshot(path=f"{OUT}/dash-audit-{W}.png")
    print("console errors:", errors)
    b.close()
