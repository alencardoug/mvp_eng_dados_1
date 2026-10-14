/* Relógio de estudo da trilha — o README desta pasta explica o método.
 *
 * Um minuto conta quando a aba está visível e houve rolagem, clique ou tecla nos últimos 5 minutos.
 * window.RELOGIO_MODO diz para onde vai o minuto:
 *   "local"    → o coletor do study_clock.py (POST /estudo/batida), que grava em data/estudo/pagina.jsonl;
 *   "artifact" → o banco do próprio Artifact no claude.ai (coleção "estudo", um documento por dia UTC),
 *                só quando quem vê é o dono da página.
 * Sem modo, o relógio não liga. Nada além do minuto e da seção na tela é registrado.
 * window.RELOGIO_PREFIXO, quando existe, antecede o id da seção: o complemento da trilha usa "cq-".
 */
(() => {
  "use strict";
  const MODE = window.RELOGIO_MODO;
  if (MODE !== "local" && MODE !== "artifact") return;
  const PREFIX = typeof window.RELOGIO_PREFIXO === "string" ? window.RELOGIO_PREFIXO : "";

  const IDLE_MS = 5 * 60 * 1000;
  const BEAT_MS = 60 * 1000;
  const FLUSH_MS = 2 * 60 * 1000;  // grava a cada 2 min e ao trocar de aba: fechar a página perde no máximo isso
  let lastUse = Date.now();
  for (const ev of ["scroll", "wheel", "mousemove", "mousedown", "keydown", "touchstart"]) {
    addEventListener(ev, () => { lastUse = Date.now(); }, { passive: true, capture: true });
  }
  const active = () => document.visibilityState === "visible" && Date.now() - lastUse < IDLE_MS;

  // A seção na tela: o último roteiro, capítulo (no complemento) ou título com id acima de um terço da janela.
  const anchors = () => Array.from(document.querySelectorAll("section.roteiro[id], section.chapter[id], h2[id], h3[id]"));
  function section() {
    const line = innerHeight / 3;
    let current = "";
    for (const el of anchors()) {
      if (el.getBoundingClientRect().top <= line) current = el.id; else break;
    }
    const tagged = current ? PREFIX + current : "";
    return /^[A-Za-z0-9_-]{1,60}$/.test(tagged) ? tagged : "";
  }

  // O selo no canto: quanto já foi somado.
  const badge = document.createElement("div");
  badge.id = "relogio-estudo";
  badge.setAttribute("aria-label", "Relógio de estudo");
  badge.style.cssText = [
    "position:fixed", "right:12px", "bottom:12px", "z-index:2147483000", "padding:5px 10px",
    "border-radius:99px", "font:600 12px/1.3 system-ui,sans-serif", "pointer-events:auto",
    "background:var(--bg-2,#1f2328)", "color:var(--fg-2,#c9d1d9)", "border:1px solid var(--line,#444c56)",
    "box-shadow:0 1px 4px rgba(0,0,0,.25)", "opacity:.92",
  ].join(";");
  badge.title = "Relógio de estudo: conta um minuto quando a aba está visível e houve uso nos últimos 5 minutos.";
  const fmt = (min) => `${Math.floor(min / 60)}h${String(min % 60).padStart(2, "0")}`;
  let todayMin = null;
  let totalMin = null;
  let state = "";
  let off = "";  // a página não conta: o selo diz isso e não mostra um "hoje" que não avança
  function paint() {
    if (off) { badge.textContent = off; return; }
    const parts = [`⏱ hoje ${todayMin == null ? "…" : fmt(todayMin)}`];
    if (totalMin != null) parts.push(`total ${fmt(totalMin)}`);
    if (state) parts.push(state);
    else if (!active()) parts.push("pausado");
    badge.textContent = parts.join(" · ");
  }
  const mount = () => { document.body.appendChild(badge); paint(); };
  if (document.body) mount(); else addEventListener("DOMContentLoaded", mount);
  // Redesenha ao voltar à aba e ao primeiro uso depois de uma pausa (no máximo a cada 5 s).
  let lastPaint = 0;
  const repaint = () => { if (Date.now() - lastPaint > 5000) { lastPaint = Date.now(); paint(); } };
  addEventListener("visibilitychange", paint);
  for (const ev of ["scroll", "mousedown", "keydown", "touchstart"]) {
    addEventListener(ev, repaint, { passive: true, capture: true });
  }

  // ── modo local ─────────────────────────────────────────────────────────────────────────────
  if (MODE === "local") {
    const refresh = () => fetch("/estudo/total", { cache: "no-store" })
      .then((r) => r.json()).then((t) => { todayMin = t.hoje; totalMin = t.total; state = ""; paint(); })
      .catch(() => { state = "coletor parado"; paint(); });
    refresh();
    setInterval(() => {
      if (!active()) { paint(); return; }
      fetch("/estudo/batida", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ section: section() }),
      }).then(refresh).catch(() => { state = "coletor parado"; paint(); });
    }, BEAT_MS);
    return;
  }

  // ── modo Artifact ──────────────────────────────────────────────────────────────────────────
  const pending = new Map(); // "AAAA-MM-DD|HH:MM" (UTC) → seção
  let db = null;
  let flushing = false;
  const utcParts = (d) => [d.toISOString().slice(0, 10), d.toISOString().slice(11, 16)];

  async function countToday() {
    // O dia local (−03:00) cobre dois documentos UTC: o do dia e o seguinte.
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const end = new Date(start.getTime() + 86400000);
    const days = new Set([utcParts(start)[0], utcParts(new Date(end.getTime() - 1))[0]]);
    let n = 0;
    for (const day of days) {
      const snap = await db.collection("estudo").doc(day).get();
      const minutes = (snap.exists && snap.data().minutos) || {};
      for (const hhmm of Object.keys(minutes)) {
        const t = new Date(`${day}T${hhmm}:00Z`);
        if (t >= start && t < end) n += 1;
      }
    }
    return n;
  }

  async function flush() {
    if (flushing || pending.size === 0 || !db) return;
    flushing = true;
    const batch = new Map(pending);
    const perDay = new Map();
    for (const [key, sec] of batch) {
      const [day, hhmm] = key.split("|");
      if (!perDay.has(day)) perDay.set(day, {});
      perDay.get(day)[hhmm] = sec;
    }
    try {
      for (const [day, minutos] of perDay) {
        const ref = db.collection("estudo").doc(day);
        const snap = await ref.get();
        if (snap.exists) await ref.update({ minutos });
        else await ref.set({ minutos });
      }
      for (const key of batch.keys()) pending.delete(key);
      state = "";
    } catch (e) {
      state = e && e.code === "quota_exceeded" ? "banco cheio" : "sem gravar — tento de novo";
    } finally {
      flushing = false;
      paint();
    }
  }

  (async () => {
    if (!window.claude || typeof window.claude.use !== "function") {
      off = "⏱ esta página não conta no relógio"; paint(); return;
    }
    const [dbNs, user] = await Promise.all([window.claude.use("db"), window.claude.use("user")]);
    if (!user || !(await user.isOwner())) { badge.remove(); return; }
    if (!dbNs) { off = "⏱ esta página não conta no relógio"; paint(); return; }
    db = dbNs;
    try { todayMin = await countToday(); } catch (e) { todayMin = 0; }
    paint();
    let firstFlushDone = false;
    setInterval(() => {
      if (!active()) { paint(); return; }
      const [day, hhmm] = utcParts(new Date());
      const key = `${day}|${hhmm}`;
      if (!pending.has(key)) { pending.set(key, section()); todayMin = (todayMin || 0) + 1; }
      paint();
      if (!firstFlushDone) { firstFlushDone = true; flush(); }
    }, BEAT_MS);
    setInterval(flush, FLUSH_MS);
    addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") flush(); });
    addEventListener("pagehide", flush);
  })();
})();
