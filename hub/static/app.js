/* Qadam clinician dashboard — vanilla JS, no build step, works offline (served by the hub). */
(() => {
  "use strict";

  // ------------------------------------------------------------------ utilities
  const root = document.getElementById("root");
  const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const store = {
    get() { try { return sessionStorage.getItem("qadam.token"); } catch { return null; } },
    set(v) { try { v ? sessionStorage.setItem("qadam.token", v) : sessionStorage.removeItem("qadam.token"); } catch { /* storage blocked */ } },
  };
  let me = null;
  let timers = [];
  let charts = [];
  let openAlertCount = 0;

  function cleanup() {
    timers.forEach(clearInterval);
    timers = [];
    charts.forEach((c) => c.destroy());
    charts = [];
  }

  class ApiError extends Error {
    constructor(status, message) { super(message); this.status = status; }
  }

  async function api(path, opts = {}) {
    const headers = { "Content-Type": "application/json" };
    const tok = store.get();
    if (tok) headers.Authorization = `Bearer ${tok}`;
    let res;
    try {
      res = await fetch(path, { ...opts, headers: { ...headers, ...(opts.headers || {}) } });
    } catch {
      throw new ApiError(0, "Hub injoignable. Vérifiez que le serveur Qadam tourne.");
    }
    if (res.status === 401 && !path.startsWith("/api/auth")) {
      store.set(null);
      me = null;
      location.hash = "#/login";
      throw new ApiError(401, "Session expirée");
    }
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new ApiError(res.status, body.detail || `Erreur ${res.status}`);
    return body;
  }

  function toast(msg, err = false) {
    const t = document.createElement("div");
    t.className = "toast" + (err ? " err" : "");
    t.setAttribute("role", err ? "alert" : "status");
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 3800);
  }

  const fmtDate = (ts) => new Date(ts * 1000).toLocaleDateString("fr-FR", { day: "2-digit", month: "short" });
  const fmtDateTime = (ts) => new Date(ts * 1000).toLocaleString("fr-FR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
  function ago(ts) {
    if (!ts) return "jamais";
    const s = Math.max(0, Date.now() / 1000 - ts);
    if (s < 60) return `il y a ${Math.round(s)} s`;
    if (s < 3600) return `il y a ${Math.round(s / 60)} min`;
    if (s < 86400) return `il y a ${Math.round(s / 3600)} h`;
    return `il y a ${Math.round(s / 86400)} j`;
  }
  const num = (v, d = 1) => (v === null || v === undefined || Number.isNaN(v) ? "—" : Number(v).toFixed(d).replace(".", ","));
  const LEVEL = { green: "Normal", amber: "À surveiller", red: "Alerte" };
  const lv = (level) => `<span class="lv ${esc(level || "none")}">${esc(LEVEL[level] || "Aucun scan")}</span>`;
  const SITE = { mth1: "1re tête métatarsienne", mth5: "5e tête métatarsienne", hallux: "Hallux", heel: "Talon" };
  const SIDE = { left: "gauche", right: "droit" };
  const TYPE = { t1: "Type 1", t2: "Type 2", gest: "Gestationnel", other: "Autre" };
  const RISK = { low: "Risque bas", moderate: "Risque modéré", high: "Risque élevé" };
  const KIND = { foot: "Pied", glucose_low: "Hypoglycémie", glucose_high: "Glycémie élevée" };
  const STATE = { online: "En ligne", stale: "Données anciennes", sensor_fault: "Capteur en défaut", offline: "Hors ligne", error: "Erreur", unknown: "Jamais connecté" };
  function sourceChip(src) {
    switch (src) {
      case "hardware": return '<span class="chip hw" title="Mesure issue du banc Arduino réel">Matériel réel</span>';
      case "simulated": return '<span class="chip sim" title="Données générées par le simulateur — pas une mesure">Simulation</span>';
      case "synthetic": return '<span class="chip syn" title="Jeu de données synthétique de démonstration">Synthétique</span>';
      case "app": return '<span class="chip app">App patient</span>';
      default: return `<span class="chip neutral">${esc(src || "manuel")}</span>`;
    }
  }

  const ICON = {
    overview: '<path d="M3 13h8V3H3zM13 21h8V11h-8zM3 21h8v-6H3zM13 3v6h8V3z"/>',
    alert: '<path d="M12 3 2 21h20L12 3z"/><path d="M12 10v5M12 18h.01"/>',
    patients: '<circle cx="9" cy="8" r="4"/><path d="M2 21c0-4 3-6 7-6s7 2 7 6M17 11a3 3 0 1 0 0-6M22 21c0-3-2-5-5-5.5"/>',
    device: '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 10h.01M7 14h4M15 10h2M15 14h2"/>',
    audit: '<path d="M9 3h6l4 4v14H5V3h4"/><path d="M9 12l2 2 4-4"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5h.01"/>',
    shield: '<path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z"/>',
    back: '<path d="M15 6l-6 6 6 6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    download: '<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>',
    logout: '<path d="M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10"/>',
  };
  const icon = (k) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[k]}</svg>`;

  // ------------------------------------------------------------------ shell
  function shell(active, title, body, actions = "") {
    const nav = [
      ["overview", "#/overview", "Vue d'ensemble"],
      ["alert", "#/alerts", "Alertes"],
      ["patients", "#/patients", "Patients"],
      ["device", "#/devices", "Appareils"],
      ["audit", "#/audit", "Journal d'audit"],
      ["info", "#/about", "Sécurité & limites"],
    ];
    root.innerHTML = `
      <div class="shell">
        <aside class="side">
          <a href="#/overview" aria-label="Accueil Qadam"><img class="logo" src="/static/qadam-logo.png" alt="Qadam"></a>
          <nav class="nav" aria-label="Navigation principale">
            ${nav.map(([k, href, label]) => `<a href="${href}" class="${k === active ? "active" : ""}" ${k === active ? 'aria-current="page"' : ""}>${icon(k)}<span class="lbl">${label}</span>${k === "alert" && openAlertCount ? `<span class="count">${openAlertCount}</span>` : ""}</a>`).join("")}
          </nav>
          <div class="foot">
            <div><strong>${esc(me?.display_name || "")}</strong></div>
            <div class="small">Prototype HackCure — pas un dispositif médical.</div>
          </div>
        </aside>
        <div class="main">
          <header class="topbar">
            <div class="title">${esc(title)}</div>
            <div class="spacer"></div>
            ${actions}
            <button class="btn ghost" id="logout" title="Se déconnecter">${icon("logout")}<span class="sr">Se déconnecter</span></button>
          </header>
          <main class="content" id="content">${body}</main>
        </div>
      </div>`;
    document.getElementById("logout").addEventListener("click", async () => {
      try { await api("/api/auth/logout", { method: "POST" }); } catch { /* ignore */ }
      store.set(null); me = null; location.hash = "#/login";
    });
    return document.getElementById("content");
  }

  const loading = () => '<div class="stack" aria-busy="true"><div class="skeleton"></div><div class="skeleton"></div><div class="skeleton"></div></div>';
  function failure(content, e) {
    content.innerHTML = `<div class="error-box" role="alert"><strong>Impossible de charger cette page.</strong> ${esc(e.message)}</div>`;
  }

  // ------------------------------------------------------------------ charts
  function chart(canvas, config) {
    if (!window.Chart) return null;
    Chart.defaults.font.family = "Rubik, system-ui, sans-serif";
    Chart.defaults.color = "#4a5b6e";
    const c = new Chart(canvas, config);
    charts.push(c);
    return c;
  }
  const LEVEL_COLOR = { green: "#1e7a4f", amber: "#f2a93b", red: "#b42318" };

  function dtTrend(canvas, scans) {
    return chart(canvas, {
      type: "line",
      data: {
        labels: scans.map((s) => fmtDate(s.ts)),
        datasets: [
          { label: "Écart gauche/droite max (°C)", data: scans.map((s) => s.max_dt), borderColor: "#1f4c78", borderWidth: 2, tension: 0.25,
            pointRadius: 4, pointBackgroundColor: scans.map((s) => LEVEL_COLOR[s.level]), pointBorderColor: "#fff", pointBorderWidth: 1.5 },
          { label: "Seuil 2,2 °C", data: scans.map(() => 2.2), borderColor: "#b42318", borderDash: [6, 4], borderWidth: 1.5, pointRadius: 0 },
        ],
      },
      options: { maintainAspectRatio: false, animation: false, interaction: { mode: "index", intersect: false },
        scales: { y: { min: 0, suggestedMax: 3.5, title: { display: true, text: "°C" }, grid: { color: "#efebe4" } }, x: { grid: { display: false } } },
        plugins: { legend: { position: "bottom", labels: { boxWidth: 12 } },
          tooltip: { callbacks: { afterLabel: (ctx) => (ctx.datasetIndex === 0 ? `${LEVEL[scans[ctx.dataIndex].level]} · ${SITE[scans[ctx.dataIndex].site] || ""} · ${scans[ctx.dataIndex].source}` : "") } } } },
    });
  }

  function glucoseChart(canvas, gl) {
    return chart(canvas, {
      type: "line",
      data: {
        labels: gl.map((g) => fmtDateTime(g.ts)),
        datasets: [
          { label: "Glycémie (g/L)", data: gl.map((g) => g.g_l), borderColor: "#1f4c78", borderWidth: 1.5, pointRadius: 3,
            pointBackgroundColor: gl.map((g) => (g.band === "low" ? "#b42318" : g.band === "very_high" ? "#f2a93b" : "#1f4c78")), tension: 0.2 },
          { label: "Hypoglycémie 0,70", data: gl.map(() => 0.7), borderColor: "#b42318", borderDash: [5, 4], borderWidth: 1, pointRadius: 0 },
          { label: "Cible post-prandiale 1,80", data: gl.map(() => 1.8), borderColor: "#8dbadb", borderDash: [5, 4], borderWidth: 1, pointRadius: 0 },
        ],
      },
      options: { maintainAspectRatio: false, animation: false, scales: { y: { min: 0.4, suggestedMax: 3, grid: { color: "#efebe4" } }, x: { ticks: { maxTicksLimit: 8 }, grid: { display: false } } },
        plugins: { legend: { position: "bottom", labels: { boxWidth: 12 } } } },
    });
  }

  function liveChart(canvas) {
    return chart(canvas, {
      type: "line",
      data: { labels: [], datasets: [
        { label: "Pied gauche (°C)", data: [], borderColor: "#1f4c78", borderWidth: 2, pointRadius: 0, tension: 0.2 },
        { label: "Pied droit (°C)", data: [], borderColor: "#8dbadb", borderWidth: 2, pointRadius: 0, tension: 0.2 },
      ] },
      options: { maintainAspectRatio: false, animation: false, scales: { y: { grace: 1, grid: { color: "#efebe4" } }, x: { ticks: { maxTicksLimit: 6 }, grid: { display: false } } },
        plugins: { legend: { position: "bottom", labels: { boxWidth: 12 } } } },
    });
  }
  function updateLive(c, readings) {
    if (!c) return;
    const site = (r) => Object.keys(r.left || {})[0] || Object.keys(r.right || {})[0] || "mth1";
    c.data.labels = readings.map((r) => new Date(r.ts * 1000).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit", second: "2-digit" }));
    c.data.datasets[0].data = readings.map((r) => r.left?.[site(r)] ?? null);
    c.data.datasets[1].data = readings.map((r) => r.right?.[site(r)] ?? null);
    c.update("none");
  }

  // ------------------------------------------------------------------ device card (shared)
  function deviceCard(d) {
    if (!d) return '<div class="empty">Aucun appareil connecté.</div>';
    const f = d.last_frame || {};
    const site = Object.keys(f.left || {})[0] || Object.keys(f.right || {})[0];
    const l = site ? f.left?.[site] : null;
    const r = site ? f.right?.[site] : null;
    const dt = l != null && r != null ? Math.abs(l - r) : null;
    const faults = (f.faults || []).map((x) => (x === "left_sensor" ? "capteur gauche" : x === "right_sensor" ? "capteur droit" : x));
    return `
      <div class="device">
        <div class="row"><span class="state"><span class="dot ${esc(d.state)}"></span>${esc(STATE[d.state] || d.state)}</span>${sourceChip(d.source)}<span class="muted small">${esc(d.id)}</span></div>
        ${d.state === "stale" ? '<div class="banner warn">Aucune trame depuis plus de 15 s : les valeurs affichées ne sont pas à jour.</div>' : ""}
        ${faults.length ? `<div class="banner warn">Défaut ${esc(faults.join(", "))} : la valeur manquante n'est pas estimée.</div>` : ""}
        <div class="lr"><div><div class="muted small">Gauche</div><div class="big">${num(l, 2)} °C</div></div>
          <div><div class="muted small">Droite</div><div class="big">${num(r, 2)} °C</div></div>
          <div><div class="muted small">Écart</div><div class="big">${num(dt, 2)} °C</div></div></div>
        <dl class="kv"><dt>Dernière trame</dt><dd>${esc(ago(d.last_seen))}</dd><dt>Capteur</dt><dd>${esc(d.sensor || "—")}</dd>
          <dt>Port</dt><dd>${esc(d.port || "—")}</dd><dt>Trames / rejets CRC</dt><dd>${esc(d.counters?.frames ?? "—")} / ${esc(d.counters?.bad_checksum ?? "—")}</dd>
          ${d.detail ? `<dt>Détail</dt><dd>${esc(d.detail)}</dd>` : ""}</dl>
      </div>`;
  }

  // ------------------------------------------------------------------ pages
  async function pageLogin() {
    cleanup();
    root.innerHTML = `
      <div class="login">
        <section class="brand">
          <img src="/static/qadam-logo.png" alt="Qadam — قدم">
          <p class="pitch">Repérer l'inflammation du pied diabétique avant la plaie, et laisser le soignant décider.</p>
          <ul>
            <li>Alertes expliquées : écart de température, site, seuil, persistance, indice de confiance.</li>
            <li>Validation ou rejet de chaque alerte en 3 étapes, tracée dans un journal infalsifiable.</li>
            <li>Données pseudonymisées (code patient), champs sensibles chiffrés AES-256.</li>
          </ul>
        </section>
        <form id="f" novalidate>
          <h1>Espace soignant</h1>
          <p class="muted">Connectez-vous pour accéder au suivi de vos patients.</p>
          <label class="field">Identifiant<input type="text" name="u" autocomplete="username" required></label>
          <label class="field">Mot de passe<input type="password" name="p" autocomplete="current-password" required></label>
          <div id="err" class="error-box hidden" role="alert"></div>
          <button class="btn primary" type="submit">Se connecter</button>
          <div class="demo-creds"><strong>Compte de démonstration</strong> (données synthétiques) : <span class="mono">dr.demo</span> / <span class="mono">qadam-demo-2026</span></div>
        </form>
      </div>`;
    const f = document.getElementById("f");
    f.addEventListener("submit", async (ev) => {
      ev.preventDefault();
      const err = document.getElementById("err");
      err.classList.add("hidden");
      const btn = f.querySelector("button");
      btn.disabled = true;
      try {
        const r = await api("/api/auth/login", { method: "POST", body: JSON.stringify({ username: f.u.value.trim(), password: f.p.value }) });
        store.set(r.token);
        me = r;
        location.hash = "#/overview";
      } catch (e) {
        err.textContent = e.message;
        err.classList.remove("hidden");
      } finally { btn.disabled = false; }
    });
  }

  async function pageOverview() {
    const content = shell("overview", "Vue d'ensemble", loading());
    const draw = async (first) => {
      let ov, alerts;
      try { [ov, alerts] = await Promise.all([api("/api/overview"), api("/api/alerts?status=open")]); }
      catch (e) { if (first) failure(content, e); return; }
      openAlertCount = alerts.length;
      const bench = ov.devices.find((d) => d.patient_ref) || ov.devices[0];
      content.innerHTML = `
        <div class="page-head"><div><h1>Triage du jour</h1><p class="sub">Les patients qui ont besoin de vous apparaissent en premier.</p></div></div>
        <div class="grid g-4">
          <div class="card kpi alert"><span class="v">${ov.alerts_open.red}</span><span class="l">Alertes rouges ouvertes</span></div>
          <div class="card kpi watch"><span class="v">${ov.alerts_open.amber}</span><span class="l">Alertes « à surveiller »</span></div>
          <div class="card kpi"><span class="v">${ov.patients}</span><span class="l">Patients suivis</span></div>
          <div class="card kpi"><span class="v">${ov.patients_scanned_today}</span><span class="l">Patients scannés aujourd'hui</span></div>
        </div>
        <div class="grid g-main">
          <section class="card" aria-labelledby="tri">
            <div class="card-head"><h2 id="tri">File de triage</h2><span class="hint">Rouge d'abord, puis le plus récent</span></div>
            ${alerts.length ? `<div class="list">${alerts.slice(0, 8).map((a) => `
              <a class="item" href="#/alerts/${a.id}">
                <span>${lv(a.level)}</span>
                <span><span class="t">${esc(a.title)}</span><br><span class="ref">${esc(a.patient_ref)}</span> <span class="muted small">· ${esc(a.patient_label)} · ${esc(KIND[a.kind])}</span></span>
                <span class="row"><span class="muted small">${esc(ago(a.created_at))}</span>${sourceChip(a.source)}</span>
              </a>`).join("")}</div>` : '<div class="empty">Aucune alerte ouverte. Tout est sous contrôle.</div>'}
            ${alerts.length > 8 ? `<p><a href="#/alerts">Voir les ${alerts.length} alertes</a></p>` : ""}
          </section>
          <div class="stack">
            <section class="card" aria-labelledby="bench"><div class="card-head"><h2 id="bench">Banc de mesure</h2><a class="hint" href="#/devices">Tous les appareils</a></div>${deviceCard(bench)}</section>
            <section class="card" aria-labelledby="sys"><div class="card-head"><h2 id="sys">État du système</h2></div>
              <dl class="kv">
                <dt>Broker MQTT</dt><dd>${ov.ingest.mqtt_connected ? '<span class="chip ok">connecté</span>' : '<span class="chip bad">déconnecté</span>'} <span class="muted small">${esc(ov.ingest.broker)}</span></dd>
                <dt>Trames reçues</dt><dd>${ov.ingest.frames} <span class="muted small">(${ov.ingest.rejected} rejetées)</span></dd>
                <dt>Assistant IA</dt><dd>${ov.ai_configured ? `<span class="chip ok">activé</span> <span class="muted small">${esc(ov.ai_model)}</span>` : '<span class="chip neutral">désactivé — bibliothèque vérifiée</span>'}</dd>
                <dt>Mode démo</dt><dd>${ov.demo_mode ? '<span class="chip warn">1 scan = 1 jour</span>' : '<span class="chip neutral">calendrier réel</span>'}</dd>
              </dl>
              ${ov.ingest.last_error ? `<p class="small muted">Dernier rejet : ${esc(ov.ingest.last_error)}</p>` : ""}
            </section>
          </div>
        </div>`;
    };
    await draw(true);
    timers.push(setInterval(() => draw(false), 4000));
  }

  async function pageAlerts(tab = "open") {
    const content = shell("alert", "Alertes", loading());
    let rows;
    try { rows = await api(`/api/alerts?status=${encodeURIComponent(tab)}`); } catch (e) { return failure(content, e); }
    if (tab === "open") openAlertCount = rows.length;
    content.innerHTML = `
      <div class="page-head"><div><h1>Alertes</h1><p class="sub">Chaque alerte est une recommandation consultative : vous la confirmez ou la rejetez.</p></div>
        <div class="actions"><div class="seg" role="tablist">${[["open", "À traiter"], ["confirmed", "Confirmées"], ["dismissed", "Rejetées"], ["all", "Toutes"]]
          .map(([k, l]) => `<button role="tab" aria-selected="${k === tab}" class="${k === tab ? "on" : ""}" data-tab="${k}">${l}</button>`).join("")}</div></div></div>
      <section class="card">
        ${rows.length ? `<div class="table-wrap"><table>
          <thead><tr><th>Niveau</th><th>Patient</th><th>Motif</th><th>Type</th><th>Source</th><th>Créée</th><th>Statut</th></tr></thead>
          <tbody>${rows.map((a) => `<tr class="link" data-href="#/alerts/${a.id}" tabindex="0">
            <td>${lv(a.level)}</td><td><span class="ref">${esc(a.patient_ref)}</span><br><span class="small muted">${esc(a.patient_label)}</span></td>
            <td>${esc(a.title)}</td><td>${esc(KIND[a.kind])}</td><td>${sourceChip(a.source)}</td><td class="num">${esc(fmtDateTime(a.created_at))}</td>
            <td>${a.status === "open" ? '<span class="chip warn">À traiter</span>' : a.status === "confirmed" ? '<span class="chip bad">Confirmée</span>' : '<span class="chip neutral">Rejetée</span>'}${a.patient_ack_at ? ' <span class="chip ok" title="Le patient a pris connaissance">vu par le patient</span>' : ""}</td></tr>`).join("")}</tbody></table></div>`
          : '<div class="empty">Aucune alerte dans cette catégorie.</div>'}
      </section>`;
    content.querySelectorAll("[data-tab]").forEach((b) => b.addEventListener("click", () => { location.hash = `#/alerts?tab=${b.dataset.tab}`; }));
    bindRowLinks(content);
  }

  function bindRowLinks(scope) {
    scope.querySelectorAll("tr[data-href]").forEach((tr) => {
      tr.addEventListener("click", () => { location.hash = tr.dataset.href; });
      tr.addEventListener("keydown", (e) => { if (e.key === "Enter") location.hash = tr.dataset.href; });
    });
  }

  async function pageAlert(id) {
    const content = shell("alert", "Examen d'une alerte", loading());
    let d;
    try { d = await api(`/api/alerts/${encodeURIComponent(id)}`); } catch (e) { return failure(content, e); }
    const a = d.alert, x = a.explanation || {}, p = d.patient, s = d.scan;
    const isFoot = a.kind === "foot";
    const site = s?.site;
    const l = s?.left?.[site], r = s?.right?.[site];
    const reviewed = a.status !== "open";
    content.innerHTML = `
      <div class="page-head"><div><a href="#/alerts" class="row small">${icon("back")} Retour aux alertes</a>
        <h1 class="row">${lv(a.level)} <span>${esc(a.title)}</span></h1>
        <p class="sub"><a href="#/patients/${esc(a.patient_ref)}" class="ref">${esc(a.patient_ref)}</a> · ${esc(p.label)} · ${esc(fmtDateTime(a.created_at))} · ${sourceChip(a.source)}</p></div></div>
      <div class="banner">${icon("shield")}<div><strong>Recommandation algorithmique consultative.</strong> Qadam signale un paramètre mesuré ; il ne pose pas de diagnostic. La décision clinique vous appartient. Les mesures proviennent d'un prototype non validé cliniquement.</div></div>
      <div class="grid g-main">
        <div class="stack">
          <section class="card" aria-labelledby="ev"><div class="card-head"><h2 id="ev">Pourquoi cette alerte ?</h2><span class="hint">${isFoot ? "Règle : écart gauche/droite ≥ 2,2 °C au même site, 2 jours de suite" : "Règle : &lt; 0,70 g/L hypoglycémie · &gt; 2,50 g/L très élevée"}</span></div>
            ${isFoot ? `
              <div class="evidence">
                <div class="e"><div class="k">Écart max</div><div class="v">${num(x.max_dt_c, 1)} °C</div></div>
                <div class="e"><div class="k">Seuil</div><div class="v">${num(x.threshold_c, 1)} °C</div></div>
                <div class="e"><div class="k">Site</div><div class="v small">${esc(SITE[x.site] || x.site)}</div></div>
                <div class="e"><div class="k">Jours consécutifs</div><div class="v">${esc(x.consecutive_days)}</div></div>
              </div>
              <div class="feet">
                <div class="foot ${x.warmer_side === "left" ? "warm" : ""}"><div class="muted small">Pied gauche · ${esc(SITE[site] || site)}</div><div class="temp">${num(l, 2)} °C</div></div>
                <div class="foot ${x.warmer_side === "right" ? "warm" : ""}"><div class="muted small">Pied droit · ${esc(SITE[site] || site)}</div><div class="temp">${num(r, 2)} °C</div></div>
              </div>
              <div><div class="row"><strong>Indice de confiance de la mesure : ${esc(x.confidence)}/100</strong><span class="chip ${x.confidence_label === "high" ? "ok" : x.confidence_label === "medium" ? "warn" : "bad"}">${x.confidence_label === "high" ? "élevé" : x.confidence_label === "medium" ? "moyen" : "faible — refaire la mesure"}</span></div>
                <div class="meter" aria-hidden="true"><i id="meter"></i></div>
                <div class="factors"><div>Échantillons<b>${num(x.confidence_factors?.samples * 100, 0)} %</b></div><div>Stabilité capteurs<b>${num(x.confidence_factors?.stability * 100, 0)} %</b></div><div>Distance au seuil<b>${num(x.confidence_factors?.margin * 100, 0)} %</b></div></div>
                <p class="small muted">L'indice mesure la fiabilité de la mesure (nombre de lectures, stabilité, marge au seuil). Ce n'est pas une probabilité de maladie.</p></div>`
              : `<dl class="kv"><dt>Valeur</dt><dd>${num(x.value_g_l, 2)} g/L</dd><dt>Contexte</dt><dd>${esc({ fasting: "à jeun", after_meal: "après repas", other: "autre" }[x.context] || x.context)}</dd></dl>`}
          </section>
          ${isFoot ? '<section class="card"><div class="card-head"><h2>Évolution sur 14 jours</h2><span class="hint">Point coloré = niveau du scan</span></div><div class="chart-box"><canvas id="trend" aria-label="Évolution de l\'écart de température"></canvas></div></section>' : ""}
        </div>
        <div class="stack">
          <section class="card" aria-labelledby="dec"><div class="card-head"><h2 id="dec">Votre décision</h2></div>
            ${reviewed ? `
              <p>${a.status === "confirmed" ? '<span class="chip bad">Alerte confirmée</span>' : '<span class="chip neutral">Alerte rejetée</span>'}</p>
              <dl class="kv"><dt>Par</dt><dd>${esc(a.reviewer)}</dd><dt>Le</dt><dd>${esc(fmtDateTime(a.reviewed_at))}</dd><dt>Note</dt><dd>${esc(a.review_note || "—")}</dd>
              <dt>Patient</dt><dd>${a.patient_ack_at ? `a pris connaissance ${esc(ago(a.patient_ack_at))}` : "pas encore consulté"}</dd></dl>`
            : `
              <div class="steps"><span class="on">1 · Examiner</span><span id="st2">2 · Décider</span><span id="st3">3 · Valider</span></div>
              <form id="rev" class="stack">
                <div class="choice" role="radiogroup" aria-label="Décision">
                  <label><input type="radio" name="d" value="confirmed"><span><b>Confirmer</b><span class="small muted">Je contacte ou convoque le patient.</span></span></label>
                  <label><input type="radio" name="d" value="dismissed"><span><b>Rejeter</b><span class="small muted">Artefact, faux positif ou déjà pris en charge.</span></span></label>
                </div>
                <label class="field">Note clinique <span class="help">Visible par le patient dans son application. Chiffrée au repos.</span><textarea name="note" maxlength="1000" placeholder="Ex. : consultation demain 9 h, décharge du pied droit en attendant."></textarea></label>
                <button class="btn primary" type="submit" disabled>Enregistrer la décision</button>
              </form>`}
          </section>
          <section class="card" aria-labelledby="pt"><div class="card-head"><h2 id="pt">Patient</h2><a class="hint" href="#/patients/${esc(p.ref)}">Dossier complet</a></div>
            <dl class="kv"><dt>Code</dt><dd class="ref">${esc(p.ref)}</dd><dt>Âge</dt><dd>${esc(p.age ?? "—")} ans</dd><dt>Diabète</dt><dd>${esc(TYPE[p.diabetes_type] || "—")}</dd>
              <dt>Risque pied</dt><dd>${esc(RISK[p.foot_risk] || "—")}</dd><dt>Dernière glycémie</dt><dd>${p.last_glucose ? `${num(p.last_glucose.g_l, 2)} g/L · ${esc(ago(p.last_glucose.ts))}` : "—"}</dd>
              <dt>Observance 7 j</dt><dd>${p.adherence_7d ?? "—"} %</dd></dl></section>
        </div>
      </div>`;
    const meter = document.getElementById("meter");
    if (meter) meter.style.width = `${Math.max(2, x.confidence || 0)}%`;
    if (isFoot && d.trend.length) dtTrend(document.getElementById("trend"), d.trend);
    const form = document.getElementById("rev");
    if (form) {
      const btn = form.querySelector("button");
      form.addEventListener("change", () => {
        const chosen = form.querySelector("input[name=d]:checked");
        btn.disabled = !chosen;
        document.getElementById("st2").classList.toggle("on", !!chosen);
        document.getElementById("st3").classList.toggle("on", !!chosen);
      });
      form.addEventListener("submit", async (ev) => {
        ev.preventDefault();
        const decision = form.querySelector("input[name=d]:checked")?.value;
        if (!decision) return;
        btn.disabled = true;
        try {
          await api(`/api/alerts/${a.id}/review`, { method: "POST", body: JSON.stringify({ decision, note: form.note.value }) });
          toast(decision === "confirmed" ? "Alerte confirmée. Le patient verra votre note." : "Alerte rejetée.");
          pageAlert(id);
        } catch (e) { toast(e.message, true); btn.disabled = false; }
      });
    }
  }

  async function pagePatients() {
    const content = shell("patients", "Patients", loading(), `<button class="btn primary" id="enroll">${icon("plus")} Inscrire un patient</button>`);
    let rows;
    try { rows = await api("/api/patients"); } catch (e) { return failure(content, e); }
    content.innerHTML = `
      <div class="page-head"><div><h1>Patients</h1><p class="sub">Identifiés par un code (pseudonymisation). Le nom reste sur le téléphone du patient.</p></div></div>
      <section class="card"><div class="table-wrap"><table>
        <thead><tr><th>Code</th><th>Libellé</th><th>Âge</th><th>Diabète</th><th>Risque pied</th><th>Dernier scan</th><th>Écart</th><th>Glycémie</th><th>Obs. 7 j</th><th>Alertes</th></tr></thead>
        <tbody>${rows.map((p) => `<tr class="link" tabindex="0" data-href="#/patients/${esc(p.ref)}">
          <td class="ref">${esc(p.ref)}</td><td>${esc(p.label)} ${p.synthetic ? sourceChip("synthetic") : p.paired ? '<span class="chip app">app appairée</span>' : ""}</td>
          <td class="num">${esc(p.age ?? "—")}</td><td>${esc(TYPE[p.diabetes_type] || "—")}</td><td>${esc(RISK[p.foot_risk] || "—")}</td>
          <td>${lv(p.last_scan?.level)}<br><span class="small muted">${p.last_scan ? esc(ago(p.last_scan.ts)) : ""}</span></td>
          <td class="num">${p.last_scan ? `${num(p.last_scan.max_dt, 1)} °C` : "—"}</td>
          <td class="num">${p.last_glucose ? `${num(p.last_glucose.g_l, 2)} g/L` : "—"}</td><td class="num">${p.adherence_7d ?? "—"}${p.adherence_7d != null ? " %" : ""}</td>
          <td>${p.open_alerts.red ? `<span class="chip bad">${p.open_alerts.red} rouge</span> ` : ""}${p.open_alerts.amber ? `<span class="chip warn">${p.open_alerts.amber} orange</span>` : ""}${!p.open_alerts.red && !p.open_alerts.amber ? '<span class="muted">—</span>' : ""}</td></tr>`).join("")}
        </tbody></table></div></section>`;
    bindRowLinks(content);
    document.getElementById("enroll").addEventListener("click", enrollModal);
  }

  function enrollModal() {
    const back = document.createElement("div");
    back.className = "modal-back";
    back.innerHTML = `
      <form class="modal" role="dialog" aria-modal="true" aria-labelledby="mt">
        <h2 id="mt">Inscrire un patient</h2>
        <p class="muted small">Seul un libellé interne (ex. initiales) est enregistré, chiffré. Le patient saisira le code d'appairage dans son application, après avoir donné son consentement.</p>
        <label class="field">Libellé interne<input type="text" name="label" maxlength="60" required placeholder="Ex. : M. B."></label>
        <div class="grid g-2">
          <label class="field">Année de naissance<input type="number" name="by" min="1900" max="2026" placeholder="1962"></label>
          <label class="field">Diabète<select name="dt"><option value="t2">Type 2</option><option value="t1">Type 1</option><option value="gest">Gestationnel</option><option value="other">Autre</option></select></label>
        </div>
        <label class="field">Risque podologique<select name="risk"><option value="moderate">Modéré</option><option value="high">Élevé (antécédent d'ulcère)</option><option value="low">Bas</option></select></label>
        <div id="res"></div>
        <div class="row"><button type="button" class="btn" id="cancel">Fermer</button><button class="btn primary" type="submit">Générer le code</button></div>
      </form>`;
    document.body.appendChild(back);
    const form = back.querySelector("form");
    const close = () => { back.remove(); if (location.hash.startsWith("#/patients")) pagePatients(); };
    back.querySelector("#cancel").addEventListener("click", close);
    back.addEventListener("keydown", (e) => { if (e.key === "Escape") close(); });
    form.label.focus();
    form.addEventListener("submit", async (ev) => {
      ev.preventDefault();
      if (!form.label.value.trim()) { form.label.focus(); return; }
      try {
        const r = await api("/api/patients", { method: "POST", body: JSON.stringify({ label: form.label.value.trim(), birth_year: form.by.value ? Number(form.by.value) : null, diabetes_type: form.dt.value, foot_risk: form.risk.value }) });
        form.querySelector("#res").innerHTML = `<p>Patient <span class="ref">${esc(r.ref)}</span> créé. Code d'appairage (valide ${r.expires_in_h} h) :</p><div class="code">${esc(r.pairing_code)}</div>`;
        form.querySelector("button[type=submit]").remove();
      } catch (e) { toast(e.message, true); }
    });
  }

  async function pagePatient(ref) {
    const content = shell("patients", "Dossier patient", loading(),
      `<button class="btn" id="fhir">${icon("download")} Export FHIR</button>`);
    let d;
    try { d = await api(`/api/patients/${encodeURIComponent(ref)}`); } catch (e) { return failure(content, e); }
    const p = d.patient;
    const scans14 = d.scans.filter((s) => s.ts > Date.now() / 1000 - 14 * 86400);
    const maxDt = scans14.length ? Math.max(...scans14.map((s) => s.max_dt)) : null;
    const gl = d.glucose;
    const inTarget = gl.length ? Math.round((100 * gl.filter((g) => g.band === "in_target").length) / gl.length) : null;
    const consent = d.consent || {};
    content.innerHTML = `
      <div class="page-head"><div><a href="#/patients" class="row small">${icon("back")} Tous les patients</a>
        <h1><span class="ref">${esc(p.ref)}</span> · ${esc(p.label)}</h1>
        <div class="row"><span class="chip neutral">${esc(TYPE[p.diabetes_type] || "—")}</span><span class="chip ${p.foot_risk === "high" ? "bad" : p.foot_risk === "moderate" ? "warn" : "ok"}">${esc(RISK[p.foot_risk] || "")}</span>
          ${p.age ? `<span class="chip neutral">${p.age} ans</span>` : ""}${p.synthetic ? sourceChip("synthetic") : ""}
          ${p.paired ? '<span class="chip app">App patient appairée</span>' : '<span class="chip neutral">App non appairée</span>'}
          ${consent.share_with_care_team ? '<span class="chip ok">Consentement partage</span>' : ""}${consent.ai_assistant ? '<span class="chip ok">Assistant IA accepté</span>' : ""}</div></div></div>
      <div class="grid g-4">
        <div class="card kpi"><span class="v">${lv(p.last_scan?.level)}</span><span class="l">Dernier scan ${p.last_scan ? esc(ago(p.last_scan.ts)) : ""}</span></div>
        <div class="card kpi"><span class="v">${num(maxDt, 1)} °C</span><span class="l">Écart maximal sur 14 jours</span></div>
        <div class="card kpi"><span class="v">${inTarget ?? "—"}${inTarget != null ? " %" : ""}</span><span class="l">Glycémies dans la cible (30 j)</span></div>
        <div class="card kpi"><span class="v">${p.adherence_7d ?? "—"}${p.adherence_7d != null ? " %" : ""}</span><span class="l">Observance déclarée (7 j)</span></div>
      </div>
      <div class="grid g-main">
        <div class="stack">
          <section class="card"><div class="card-head"><h2>Asymétrie thermique plantaire</h2><span class="hint">Seuil 2,2 °C · 2 jours consécutifs</span></div>
            ${d.scans.length ? '<div class="chart-box"><canvas id="trend"></canvas></div>' : '<div class="empty">Aucun scan enregistré.</div>'}</section>
          ${d.device ? `<section class="card"><div class="card-head"><h2>Banc en direct</h2><span class="hint">10 dernières minutes · actualisé toutes les 3 s</span></div>
            <div id="dev">${deviceCard(d.device)}</div><div class="chart-box sm"><canvas id="live"></canvas></div></section>` : ""}
          <section class="card"><div class="card-head"><h2>Glycémie</h2><span class="hint">${gl.length} mesures · 30 jours</span></div>
            ${gl.length ? '<div class="chart-box"><canvas id="gl"></canvas></div>' : '<div class="empty">Aucune glycémie.</div>'}</section>
          <section class="card"><div class="card-head"><h2>Scans récents</h2></div><div class="table-wrap"><table>
            <thead><tr><th>Date</th><th>Niveau</th><th>Écart</th><th>Site</th><th>Confiance</th><th>Source</th></tr></thead>
            <tbody>${d.scans.slice(-10).reverse().map((s) => `<tr><td class="num">${esc(fmtDateTime(s.ts))}</td><td>${lv(s.level)}</td><td class="num">${num(s.max_dt, 1)} °C</td><td>${esc(SITE[s.site] || s.site)}</td><td class="num">${esc(s.confidence)}/100${s.mismatch ? ' <span class="chip warn" title="Le verdict de l\'app différait de celui du hub">écart app/hub</span>' : ""}</td><td>${sourceChip(s.source)}</td></tr>`).join("")}</tbody></table></div></section>
        </div>
        <div class="stack">
          <section class="card" aria-labelledby="sum"><div class="card-head"><h2 id="sum">Synthèse pour consultation</h2></div><div id="sumbox"></div></section>
          <section class="card"><div class="card-head"><h2>Alertes</h2></div>
            ${d.alerts.length ? `<div class="list">${d.alerts.slice(0, 8).map((a) => `<a class="item" href="#/alerts/${a.id}"><span>${lv(a.level)}</span><span><span class="t">${esc(a.title)}</span><br><span class="muted small">${esc(fmtDateTime(a.created_at))}</span></span><span>${a.status === "open" ? '<span class="chip warn">À traiter</span>' : a.status === "confirmed" ? '<span class="chip bad">Confirmée</span>' : '<span class="chip neutral">Rejetée</span>'}</span></a>`).join("")}</div>` : '<div class="empty">Aucune alerte.</div>'}</section>
          <section class="card"><div class="card-head"><h2>Observance (14 j)</h2></div>
            ${d.adherence.length ? `<table><tbody>${d.adherence.map((x) => `<tr><td class="num">${esc(x.day.slice(5))}</td><td><div class="meter"><i data-w="${x.planned ? Math.round((100 * x.taken) / x.planned) : 0}"></i></div></td><td class="num small">${x.taken}/${x.planned}</td></tr>`).join("")}</tbody></table>` : '<div class="empty">Pas de données.</div>'}</section>
        </div>
      </div>`;
    content.querySelectorAll("i[data-w]").forEach((i) => { i.style.width = `${i.dataset.w}%`; });
    if (d.scans.length) dtTrend(document.getElementById("trend"), d.scans);
    if (gl.length) glucoseChart(document.getElementById("gl"), gl);
    if (d.device) {
      const lc = liveChart(document.getElementById("live"));
      updateLive(lc, d.live);
      timers.push(setInterval(async () => {
        try {
          const r = await api(`/api/devices/${encodeURIComponent(d.device.id)}/live`);
          document.getElementById("dev").innerHTML = deviceCard(r.device);
          updateLive(lc, r.readings);
        } catch { /* keep last view; banner shows staleness */ }
      }, 3000));
    }
    renderSummary(document.getElementById("sumbox"), ref, d.summaries[0]);
    document.getElementById("fhir").addEventListener("click", async () => {
      try {
        const bundle = await api(`/fhir/Observation?patient=${encodeURIComponent(ref)}`);
        const blob = new Blob([JSON.stringify(bundle, null, 2)], { type: "application/fhir+json" });
        const a = document.createElement("a");
        a.href = URL.createObjectURL(blob);
        a.download = `qadam-${ref}-observations.fhir.json`;
        a.click();
        setTimeout(() => URL.revokeObjectURL(a.href), 2000);
        toast(`${bundle.total} observations FHIR exportées.`);
      } catch (e) { toast(e.message, true); }
    });
  }

  function renderSummary(box, ref, s) {
    const label = (x) => (x.source === "gemini" ? `<span class="chip warn">Rédigé par IA (${esc(x.model)}) — à vérifier</span>` : '<span class="chip neutral">Synthèse automatique déterministe (sans IA)</span>');
    if (!s) {
      box.innerHTML = `<p class="muted">Préparez une synthèse factuelle des 14 derniers jours (scans, glycémie, observance, alertes). Elle n'est versée au dossier qu'après votre validation.</p>
        <p><button class="btn primary" id="gen">Générer un brouillon</button></p>`;
    } else {
      box.innerHTML = `<div class="row">${label(s)}${s.status === "draft" ? '<span class="chip neutral">Brouillon</span>' : s.status === "validated" ? '<span class="chip ok">Validée</span>' : '<span class="chip bad">Rejetée</span>'}<span class="muted small">${esc(fmtDateTime(s.created_at))}</span></div>
        <div class="narrative">${esc(s.narrative)}</div>
        ${s.status === "draft" ? `<form id="sv" class="stack"><label class="field">Commentaire (optionnel)<textarea name="note" maxlength="1000"></textarea></label>
          <div class="row"><button class="btn primary" name="validated" type="submit">Valider</button><button class="btn" name="rejected" type="submit">Rejeter</button><button class="btn ghost" type="button" id="gen">Régénérer</button></div></form>`
          : `<p class="small muted">${s.status === "validated" ? "Validée" : "Rejetée"} par ${esc(s.reviewer)} ${esc(ago(s.reviewed_at))}${s.review_note ? ` — « ${esc(s.review_note)} »` : ""}</p><p><button class="btn" id="gen">Nouvelle synthèse</button></p>`}`;
      const form = box.querySelector("#sv");
      if (form) {
        let decision = "validated";
        form.querySelectorAll("button[type=submit]").forEach((b) => b.addEventListener("click", () => { decision = b.name; }));
        form.addEventListener("submit", async (ev) => {
          ev.preventDefault();
          try {
            const r = await api(`/api/summaries/${s.id}/review`, { method: "POST", body: JSON.stringify({ decision, note: form.note.value }) });
            renderSummary(box, ref, r);
            toast(decision === "validated" ? "Synthèse validée." : "Synthèse rejetée.");
          } catch (e) { toast(e.message, true); }
        });
      }
    }
    const gen = box.querySelector("#gen");
    if (gen) gen.addEventListener("click", async () => {
      gen.disabled = true;
      gen.textContent = "Génération…";
      try { renderSummary(box, ref, await api(`/api/patients/${encodeURIComponent(ref)}/summaries`, { method: "POST" })); }
      catch (e) { toast(e.message, true); gen.disabled = false; gen.textContent = "Générer un brouillon"; }
    });
  }

  async function pageDevices() {
    const content = shell("device", "Appareils", loading());
    const draw = async (first) => {
      let devs;
      try { devs = await api("/api/devices"); } catch (e) { if (first) failure(content, e); return; }
      content.innerHTML = `
        <div class="page-head"><div><h1>Appareils</h1><p class="sub">Chaque trame porte sa source : matériel réel ou simulation. Le pont ne bascule jamais seul en simulation.</p></div></div>
        ${devs.length ? `<div class="grid g-2">${devs.map((d) => `<section class="card"><div class="card-head"><h2>${esc(d.id)}</h2><span class="hint">${d.patient_ref ? `Patient <a href="#/patients/${esc(d.patient_ref)}" class="ref">${esc(d.patient_ref)}</a>` : "non attribué"}</span></div>${deviceCard(d)}</section>`).join("")}</div>`
          : '<div class="card empty">Aucun appareil n\'a encore publié. Lancez le pont : <span class="mono">python bridge/qadam_bridge.py --port COM5</span> ou <span class="mono">--simulate</span>.</div>'}`;
    };
    await draw(true);
    timers.push(setInterval(() => draw(false), 3000));
  }

  async function pageAudit() {
    const content = shell("audit", "Journal d'audit", loading(), '<button class="btn" id="verify">Vérifier l\'intégrité</button>');
    let rows;
    try { rows = await api("/api/audit?limit=150"); } catch (e) { return failure(content, e); }
    content.innerHTML = `
      <div class="page-head"><div><h1>Journal d'audit</h1><p class="sub">Chaque accès et chaque décision sont chaînés par hachage SHA-256 : toute modification a posteriori est détectée.</p></div></div>
      <div id="vres"></div>
      <section class="card"><div class="table-wrap"><table><thead><tr><th>#</th><th>Date</th><th>Acteur</th><th>Action</th><th>Cible</th><th>Détail</th><th>Empreinte</th></tr></thead>
      <tbody>${rows.map((r) => `<tr><td class="num">${r.id}</td><td class="num">${esc(fmtDateTime(r.ts))}</td><td>${esc(r.actor)}</td><td>${esc(r.action)}</td><td class="ref">${esc(r.target)}</td><td class="small">${esc(r.detail)}</td><td class="mono">${esc(r.hash.slice(0, 12))}…</td></tr>`).join("")}</tbody></table></div></section>`;
    document.getElementById("verify").addEventListener("click", async () => {
      try {
        const v = await api("/api/audit/verify");
        document.getElementById("vres").innerHTML = v.ok
          ? `<div class="banner">${icon("shield")}<div><strong>Chaîne intègre.</strong> ${v.entries} entrées vérifiées. Tête : <span class="mono">${esc(v.head.slice(0, 16))}…</span></div></div>`
          : `<div class="error-box" role="alert"><strong>Chaîne rompue à l'entrée #${esc(v.broken_at)}.</strong> Le journal a été modifié.</div>`;
      } catch (e) { toast(e.message, true); }
    });
  }

  function pageAbout() {
    shell("info", "Sécurité & limites", `
      <div class="page-head"><div><h1>Usage prévu, sécurité et limites</h1><p class="sub">À lire avant toute démonstration ou expérimentation.</p></div></div>
      <div class="grid g-2">
        <section class="card stack"><h2>Usage prévu</h2>
          <p>Qadam aide à repérer précocement une inflammation du pied chez une personne diabétique à risque, en comparant la température du même point plantaire des deux pieds. Un écart ≥ 2,2 °C deux jours de suite est le signal utilisé par les essais de télésurveillance thermique et recommandé par l'IWGDF (2023) pour les patients à risque modéré à élevé.</p>
          <p><strong>Qadam ne pose pas de diagnostic.</strong> Toute alerte est consultative et doit être confirmée ou rejetée par un soignant.</p></section>
        <section class="card stack"><h2>Limites du prototype</h2>
          <p>Le banc utilise deux capteurs DHT22 (température de l'air, ±0,5 °C). Ce ne sont pas des thermomètres cutanés : les valeurs servent à démontrer la chaîne de données, pas à évaluer un patient. Aucune validation clinique n'a été réalisée.</p>
          <p>Le mode démo compte chaque scan comme un jour afin de montrer l'escalade orange → rouge en quelques minutes.</p></section>
        <section class="card stack"><h2>Protection des données</h2>
          <p>Patients pseudonymisés (code QDM-xxxx). Libellés, notes et synthèses chiffrés AES-256-GCM au repos. Mots de passe PBKDF2-SHA256. Journal d'audit chaîné. Droit à l'effacement depuis l'app patient. Conformité INPDP/RGPD à instruire avant tout pilote (déclaration, hébergement des données de santé).</p>
          <p>Transport : le prototype tourne sur un réseau local isolé. Un profil TLS (HTTPS et MQTT 8883) est fourni dans la documentation pour le déploiement.</p></section>
        <section class="card stack"><h2>Intelligence artificielle</h2>
          <p>L'IA (Gemini, clé côté serveur uniquement) reformule des faits déterministes et répond aux questions d'éducation du patient. Les signes d'urgence sont filtrés par des règles fixes avant tout appel à l'IA ; les réponses contenant une posologie sont bloquées. Sans IA, Qadam utilise une bibliothèque de réponses vérifiées.</p></section>
      </div>`);
  }

  // ------------------------------------------------------------------ router
  async function route() {
    cleanup();
    const hash = location.hash || "#/overview";
    if (!store.get()) { if (hash !== "#/login") location.hash = "#/login"; return pageLogin(); }
    if (!me) {
      try { me = await api("/api/me"); } catch { return; }
    }
    const [path, query] = hash.slice(1).split("?");
    const parts = path.split("/").filter(Boolean);
    const params = new URLSearchParams(query || "");
    switch (parts[0]) {
      case "login": location.hash = "#/overview"; return undefined;
      case "alerts": return parts[1] ? pageAlert(parts[1]) : pageAlerts(params.get("tab") || "open");
      case "patients": return parts[1] ? pagePatient(decodeURIComponent(parts[1])) : pagePatients();
      case "devices": return pageDevices();
      case "audit": return pageAudit();
      case "about": return pageAbout();
      default: return pageOverview();
    }
  }
  window.addEventListener("hashchange", route);
  document.addEventListener("visibilitychange", () => { if (document.hidden) { timers.forEach(clearInterval); timers = []; } else route(); });
  route();
})();
