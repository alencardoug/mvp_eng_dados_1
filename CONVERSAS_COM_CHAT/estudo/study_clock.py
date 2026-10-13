#!/usr/bin/env python3
"""Relógio de estudo da trilha da fase local: registra, soma e audita as horas do aprendizado.

Uso, da raiz do repositório (o método e os limites estão no README.md desta pasta):

    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py serve            # a trilha com o relógio, em http://127.0.0.1:8770/
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py import           # minutos de atividade do Claude Code e do Codex
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py archive          # cópia das transcrições em ~/Projetos/_arquivo
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py report           # soma tudo: registros/, auditoria.md, resumo.json
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py import-artifact <arquivo.json>
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py install-hook     # liga o registro do terminal no ~/.bashrc
    python3 CONVERSAS_COM_CHAT/estudo/study_clock.py uninstall-hook   # desliga

Os registros vivos ficam em data/estudo/: fora do Git, para o `git status` dos roteiros não mudar
enquanto você estuda, e fora dos contêineres, para sobreviver a reinício e a reset dos bancos. O
`report` copia um retrato deles para registros/, que é versionado e publicado com a auditoria.
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import hashlib
import html
import http.server
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import threading
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
LIVE = Path(os.environ.get("ESTUDO_DADOS") or REPO / "data" / "estudo")  # ESTUDO_DADOS: só para testes
PUBLIC = HERE / "registros"
TRAIL = "CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html"
ARCHIVE = Path.home() / "Projetos" / "_arquivo" / "registros_mvp_eng_dados_1"
PROJECT_PATHS = ["/home/doug/Projetos/mvp_ed1", str(REPO)]  # o checkout antigo e o atual
LOCAL_TZ = dt.timezone(dt.timedelta(hours=-3))               # America/Sao_Paulo: sem horário de verão desde 2019
UTC = dt.timezone.utc
PORT = 8770

# Parâmetros do método — a auditoria os repete, e mudar um muda a soma.
GAP_SESSION_MIN = 15   # Claude Code e Codex: eventos a até 15 min um do outro formam um bloco contínuo
TERMINAL_IDLE_MIN = 5  # no terminal, um minuto conta com tecla nos últimos 5 min: o Enter de cada comando
                       # e as teclas vistas pelo vigia enquanto ele roda (psql, contêiner); sem teto
PAGE_IDLE_MIN = 5      # na página, sem interação por 5 min o relógio pausa (study_clock.js)

HOOK_BEGIN = "# >>> relógio de estudo — mvp_eng_dados_1 >>>"
HOOK_END = "# <<< relógio de estudo <<<"
SECTION_RE = re.compile(r"^[A-Za-z0-9_-]{1,60}$")


# ── tempo ────────────────────────────────────────────────────────────────────────────────────────
def parse_ts(text: str) -> dt.datetime:
    return dt.datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone(UTC)


def minute_of(moment: dt.datetime) -> dt.datetime:
    return moment.astimezone(UTC).replace(second=0, microsecond=0)


def minute_key(moment: dt.datetime) -> str:
    return minute_of(moment).strftime("%Y-%m-%dT%H:%MZ")


def hm(minutes: int) -> str:
    return f"{minutes // 60}h{minutes % 60:02d}"


# ── arquivos ─────────────────────────────────────────────────────────────────────────────────────
def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue  # uma linha cortada (máquina desligada no meio da escrita) não derruba a soma
    return rows


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text("".join(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n" for r in rows), encoding="utf-8")
    tmp.replace(path)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


# ── fontes: Claude Code e Codex ──────────────────────────────────────────────────────────────────
def claude_dirs() -> list[Path]:
    return [Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", p) for p in PROJECT_PATHS]


def claude_files() -> list[Path]:
    files = []
    for folder in claude_dirs():
        files += sorted(folder.glob("*.jsonl")) + sorted(folder.glob("*/subagents/*.jsonl"))
    return files


def codex_cwd(path: Path) -> str | None:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("type") == "session_meta":
                return (row.get("payload") or {}).get("cwd")
    return None


def codex_files() -> list[Path]:
    base = Path.home() / ".codex"
    candidates = sorted(base.glob("sessions/**/*.jsonl")) + sorted(base.glob("archived_sessions/*.jsonl"))
    return [p for p in candidates if codex_cwd(p) in PROJECT_PATHS]


def archived_copy(source: Path) -> Path:
    home = Path.home()
    if source.is_relative_to(home / ".claude"):
        return ARCHIVE / "claude" / source.relative_to(home / ".claude" / "projects")
    return ARCHIVE / "codex" / source.relative_to(home / ".codex")


def all_sources() -> list[tuple[str, Path]]:
    """Cada fonte uma vez: o original, se ainda existe; senão, a cópia guardada pelo `archive`."""
    found: dict[str, tuple[str, Path]] = {}
    for kind, base in (("claude", ARCHIVE / "claude"), ("codex", ARCHIVE / "codex")):
        for copy in sorted(base.glob("**/*.jsonl")) if base.exists() else []:
            found[f"{kind}:{copy.name}"] = (kind, copy)
    for source in claude_files():
        found[f"claude:{source.name}"] = ("claude", source)
    for source in codex_files():
        found[f"codex:{source.name}"] = ("codex", source)
    return sorted(found.values(), key=lambda item: str(item[1]))


def claude_kind(row: dict) -> str | None:
    if not row.get("timestamp") or row.get("type") not in ("user", "assistant", "system"):
        return None
    if row.get("type") == "user" and not row.get("isMeta"):
        content = (row.get("message") or {}).get("content")
        if isinstance(content, str) and content.strip() and not content.startswith("<"):
            return "prompt"
        if isinstance(content, list):
            parts = [p for p in content if isinstance(p, dict)]
            if any(p.get("type") == "text" for p in parts) and not any(p.get("type") == "tool_result" for p in parts):
                return "prompt"
    return "work"


def cmd_archive(_args) -> int:
    copied = kept = 0
    manifest = []
    for source in claude_files() + codex_files():
        target = archived_copy(source)
        if not target.exists() or target.stat().st_size != source.stat().st_size \
                or target.stat().st_mtime < source.stat().st_mtime:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            copied += 1
        else:
            kept += 1
    for copy in sorted(ARCHIVE.glob("**/*.jsonl")):
        manifest.append({"arquivo": str(copy.relative_to(ARCHIVE)), "bytes": copy.stat().st_size, "sha256": sha256(copy)})
    (ARCHIVE / "manifesto.json").write_text(json.dumps(
        {"gerado_em": dt.datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"), "arquivos": manifest},
        ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"arquivo: {copied} copiado(s), {kept} já guardado(s); {len(manifest)} no total, em {ARCHIVE}")
    return 0


def cmd_import(_args) -> int:
    claude_rows = {(r["minute"], r["kind"], r["session"]) for r in read_jsonl(LIVE / "claude_code.jsonl")}
    codex_rows = {(r["minute"], r["session"]) for r in read_jsonl(LIVE / "codex.jsonl")}
    before = (len(claude_rows), len(codex_rows))
    for kind, path in all_sources():
        session = path.stem
        with path.open(encoding="utf-8") as handle:
            for line in handle:
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if kind == "claude":
                    event = claude_kind(row)
                    if event:
                        claude_rows.add((minute_key(parse_ts(row["timestamp"])), event, session))
                elif row.get("timestamp"):
                    codex_rows.add((minute_key(parse_ts(row["timestamp"])), session))
    write_jsonl(LIVE / "claude_code.jsonl",
                [{"minute": m, "kind": k, "session": s} for m, k, s in sorted(claude_rows)])
    write_jsonl(LIVE / "codex.jsonl", [{"minute": m, "session": s} for m, s in sorted(codex_rows)])
    print(f"importado: Claude Code {before[0]} → {len(claude_rows)} linhas; Codex {before[1]} → {len(codex_rows)} linhas")
    return 0


def cmd_import_artifact(args) -> int:
    """Junta os minutos que o relógio do Artifact gravou no banco dele (lidos pelo Claude e salvos em JSON)."""
    dump = json.loads(Path(args.file).read_text(encoding="utf-8"))
    docs = dump.get("documents") or dump.get("docs") or dump
    rows = {(r["minute"], r.get("section", "")) for r in read_jsonl(LIVE / "artifact.jsonl")}
    before = len(rows)
    for doc in docs:
        day = doc.get("id") or doc.get("doc_id")
        data = doc.get("data") or doc
        for hour_minute, section in (data.get("minutos") or {}).items():
            if re.fullmatch(r"\d{4}-\d\d-\d\d", str(day)) and re.fullmatch(r"\d\d:\d\d", hour_minute):
                section = section if isinstance(section, str) and SECTION_RE.match(section) else ""
                rows.add((f"{day}T{hour_minute}Z", section))
    by_minute: dict[str, str] = {}
    for minute, section in sorted(rows):
        by_minute[minute] = by_minute.get(minute) or section
    write_jsonl(LIVE / "artifact.jsonl", [{"minute": m, "section": s, "source": "artifact"} for m, s in sorted(by_minute.items())])
    print(f"Artifact: {before} → {len(by_minute)} minutos")
    return 0


# ── a soma ───────────────────────────────────────────────────────────────────────────────────────
def blocks(minutes: list[dt.datetime], gap_min: int) -> list[tuple[dt.datetime, dt.datetime]]:
    out: list[list[dt.datetime]] = []
    for moment in sorted(set(minutes)):
        if out and (moment - out[-1][1]) <= dt.timedelta(minutes=gap_min):
            out[-1][1] = moment
        else:
            out.append([moment, moment])
    return [(a, b) for a, b in out]


def expand(start: dt.datetime, end: dt.datetime) -> set[dt.datetime]:
    """Os minutos de start a end, inclusive."""
    out, moment = set(), minute_of(start)
    while moment <= minute_of(end):
        out.add(moment)
        moment += dt.timedelta(minutes=1)
    return out


def compute() -> dict:
    claude = read_jsonl(LIVE / "claude_code.jsonl")
    codex = read_jsonl(LIVE / "codex.jsonl")
    page = read_jsonl(LIVE / "pagina.jsonl") + read_jsonl(LIVE / "artifact.jsonl")
    terminal = read_jsonl(LIVE / "terminal.jsonl")

    # Claude Code: blocos com GAP; dentro do bloco, o intervalo até um pedido seu é tempo seu
    # (ler, decidir, digitar), e o resto é o Claude trabalhando com você acompanhando.
    kinds: dict[dt.datetime, set[str]] = collections.defaultdict(set)
    for row in claude:
        kinds[parse_ts(row["minute"])].add(row["kind"])
    label: dict[dt.datetime, str] = {}
    ordered = sorted(kinds)
    for index, current in enumerate(ordered):
        owner_here = "prompt" in kinds[current]  # o minuto em que você mandou um pedido é seu
        label[current] = "owner" if owner_here else "work"
        if index and current - ordered[index - 1] <= dt.timedelta(minutes=GAP_SESSION_MIN):
            for moment in expand(ordered[index - 1], current) - {ordered[index - 1], current}:
                label[moment] = "owner" if owner_here else "work"
    claude_work = {moment for moment, kind in label.items() if kind == "work"}
    claude_owner = {moment for moment, kind in label.items() if kind == "owner"}
    claude_all = claude_work | claude_owner

    codex_all: set[dt.datetime] = set()
    for start, end in blocks([parse_ts(r["minute"]) for r in codex], GAP_SESSION_MIN):
        codex_all |= expand(start, end)

    page_sections: dict[dt.datetime, str] = {}
    for row in page:
        moment = parse_ts(row["minute"])
        page_sections[moment] = page_sections.get(moment) or row.get("section", "")
    page_all = set(page_sections)

    terminal_all: set[dt.datetime] = set()
    keys = [parse_ts(r["start"]) for r in terminal if r.get("start")] + [parse_ts(r["input"]) for r in terminal if r.get("input")]
    for key in keys:
        terminal_all |= expand(key, key + dt.timedelta(minutes=TERMINAL_IDLE_MIN - 1))

    activities = {
        "claude_code": claude_all, "claude_work": claude_work, "claude_owner": claude_owner,
        "codex": codex_all, "trail": page_all, "terminal": terminal_all,
    }
    total = claude_all | codex_all | page_all | terminal_all
    per_day: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for name in ("claude_code", "codex", "trail", "terminal"):
        for moment in activities[name]:
            per_day[moment.astimezone(LOCAL_TZ).date().isoformat()][name] += 1
    for moment in total:
        per_day[moment.astimezone(LOCAL_TZ).date().isoformat()]["total"] += 1
    sections = collections.Counter(s for s in page_sections.values() if s)
    first = {name: min(values).isoformat() if values else None for name, values in activities.items()}
    return {"minutes": {name: len(v) for name, v in activities.items()} | {"total": len(total)},
            "per_day": {day: dict(c) for day, c in sorted(per_day.items())}, "sections": dict(sections.most_common()),
            "first": first, "today": len({m for m in page_all if m.astimezone(LOCAL_TZ).date() == dt.datetime.now(LOCAL_TZ).date()})}


def trail_titles() -> dict[str, str]:
    text = (REPO / TRAIL).read_text(encoding="utf-8")
    titles = {}
    for ident, inner in re.findall(r'<section class="roteiro[^"]*" id="([^"]+)">\s*<h4>(.*?)</h4>', text, re.S):
        titles[ident] = html.unescape(re.sub(r"<[^>]+>", "", inner)).strip()
    for ident, inner in re.findall(r'<h[23][^>]*\bid="([^"]+)"[^>]*>(.*?)</h[23]>', text, re.S):
        titles.setdefault(ident, html.unescape(re.sub(r"<[^>]+>", "", inner)).strip())
    return titles


def cmd_report(_args) -> int:
    result = compute()
    now = dt.datetime.now(UTC)
    PUBLIC.mkdir(parents=True, exist_ok=True)
    integrity = []
    for name in ("claude_code.jsonl", "codex.jsonl", "pagina.jsonl", "artifact.jsonl", "terminal.jsonl"):
        source, target = LIVE / name, PUBLIC / name
        if source.exists():
            shutil.copyfile(source, target)
        elif not target.exists():
            target.write_text("", encoding="utf-8")
        integrity.append((name, sum(1 for _ in target.open(encoding="utf-8")), sha256(target)))
    archive_manifest = ARCHIVE / "manifesto.json"
    archive_hash = sha256(archive_manifest) if archive_manifest.exists() else None
    archive_count = len(json.loads(archive_manifest.read_text(encoding="utf-8"))["arquivos"]) if archive_hash else 0

    m = result["minutes"]
    titles = trail_titles()
    lines = [
        "# Auditoria das horas de estudo — trilha da fase local",
        "",
        f"> Gerada por `study_clock.py report` em {now.astimezone(LOCAL_TZ):%d/%m/%Y %H:%M} (horário de Brasília).",
        "> Reproduzível: os registros estão em [`registros/`](registros/), e o mesmo comando refaz esta página",
        "> a partir deles. O método e os limites estão no [README](README.md).",
        "",
        "## Resumo",
        "",
        "| Atividade | Horas | De onde vem | Regra |",
        "|---|---|---|---|",
        f"| Construção com o Claude Code | {hm(m['claude_code'])} | transcrições do Claude Code | eventos a até {GAP_SESSION_MIN} min formam um bloco |",
        f"| ↳ o Claude trabalhando, você acompanhando | {hm(m['claude_work'])} | as mesmas | do evento ao seguinte, quando o seguinte não é um pedido seu |",
        f"| ↳ você entre turnos: lendo, decidindo, escrevendo | {hm(m['claude_owner'])} | as mesmas | do último evento até o seu pedido seguinte |",
        f"| Construção e revisão com o Codex | {hm(m['codex'])} | sessões do Codex na pasta do projeto | eventos a até {GAP_SESSION_MIN} min formam um bloco |",
        f"| Estudo na trilha | {hm(m['trail'])} | relógio da página, local e no Artifact | minuto com a aba visível e uso nos últimos {PAGE_IDLE_MIN} min |",
        f"| Execução no terminal | {hm(m['terminal'])} | gancho do bash, só na pasta do projeto | minuto com tecla no terminal nos últimos {TERMINAL_IDLE_MIN} min |",
        f"| **Total, sem contar o mesmo minuto duas vezes** | **{hm(m['total'])}** | a união dos minutos acima | |",
        "",
        "## Por dia",
        "",
        "| Dia | Claude Code | Codex | Trilha | Terminal | Total |",
        "|---|---|---|---|---|---|",
    ]
    for day, counts in result["per_day"].items():
        d = dt.date.fromisoformat(day)
        lines.append(f"| {d:%d/%m/%Y} | {hm(counts.get('claude_code', 0))} | {hm(counts.get('codex', 0))} | "
                     f"{hm(counts.get('trail', 0))} | {hm(counts.get('terminal', 0))} | **{hm(counts.get('total', 0))}** |")
    lines += ["", "## O que foi estudado na trilha", ""]
    if result["sections"]:
        lines += ["| Seção | Tempo com ela na tela |", "|---|---|"]
        for ident, minutes in result["sections"].items():
            label = titles.get(ident, ident)
            lines.append(f"| `{ident}` — {label.replace('|', '/')} | {hm(minutes)} |")
    else:
        lines.append("Nenhum minuto de estudo na trilha registrado ainda: o relógio da página começou em 13/10/2026.")
    lines += [
        "", "## Registros e integridade", "",
        "| Arquivo | Linhas | SHA-256 |", "|---|---|---|",
    ] + [f"| [`registros/{n}`](registros/{n}) | {c} | `{h}` |" for n, c, h in integrity] + [
        "",
        f"Fontes originais do Claude Code e do Codex: {archive_count} arquivos guardados fora do Git, com o hash de cada um "
        f"num manifesto (SHA-256 do manifesto: `{archive_hash}`)." if archive_hash else
        "Fontes originais do Claude Code e do Codex: ainda não arquivadas.",
        "",
        "## Método e limites",
        "",
        "- Cada fonte conta minutos de relógio. O total é a **união**: um minuto em que o Claude trabalhava e você lia a trilha conta uma vez.",
        f"- Claude Code e Codex: o minuto de cada evento das transcrições, e o intervalo entre eventos a até {GAP_SESSION_MIN} min. "
        "Pausas maiores ficam de fora — inclusive leitura longa sem nenhuma interação.",
        "- As transcrições do Claude Code anteriores a 14/09/2026 foram apagadas pela limpeza automática de 30 dias antes "
        "de este registro existir; o Codex cobre o projeto desde 01/09/2026.",
        f"- Trilha: o relógio da página grava um minuto quando a aba está visível e houve rolagem, clique ou tecla nos "
        f"últimos {PAGE_IDLE_MIN} min. Ler sem tocar em nada por mais tempo pausa a contagem. Mede presença e uso, não compreensão.",
        f"- Terminal: só comandos digitados dentro da pasta do projeto; grava início, fim e o nome do programa, nunca o "
        f"comando inteiro, e, enquanto o comando roda, o minuto de cada tecla no terminal (dentro de um `psql` ou de um "
        f"contêiner, inclusive), nunca a tecla. Um minuto conta com tecla nos últimos {TERMINAL_IDLE_MIN} min: esperar um "
        f"comando longo sem digitar pausa a contagem. Comandos repetidos idênticos ou começados por espaço não entram no "
        f"histórico do bash e não são vistos.",
        "- Terminal, mudança de regra em 13/10/2026: até então contava a duração do comando, com teto de 30 min, mais até 5 min "
        "entre comandos; o teto perdia o estudo longo dentro do `psql` e contava como uso um programa parado. A regra nova vale "
        "para todos os registros, inclusive os anteriores, que não têm as teclas e contam só o Enter de cada comando.",
        "- O estudo na trilha e no terminal antes de 13/10/2026 não foi medido.",
    ]
    (HERE / "auditoria.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    summary = {"gerado_em": now.strftime("%Y-%m-%dT%H:%M:%SZ"), "minutos": m, "por_dia": result["per_day"],
               "secoes": result["sections"], "registros": {n: h for n, _, h in integrity}, "manifesto_arquivo": archive_hash,
               "parametros": {"gap_sessao_min": GAP_SESSION_MIN, "terminal_ocioso_min": TERMINAL_IDLE_MIN,
                              "pagina_ociosa_min": PAGE_IDLE_MIN}}
    (HERE / "resumo.json").write_text(json.dumps(summary, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    print(f"total: {hm(m['total'])} (Claude Code {hm(m['claude_code'])}, Codex {hm(m['codex'])}, "
          f"trilha {hm(m['trail'])}, terminal {hm(m['terminal'])}) → {HERE / 'auditoria.md'}")
    return 0


# ── o coletor: serve a trilha com o relógio e grava os minutos ───────────────────────────────────
def tracked_files() -> set[str]:
    out = subprocess.run(["git", "ls-files", "-z"], cwd=REPO, capture_output=True, check=True).stdout
    return {p for p in out.decode("utf-8").split("\0") if p}


class Collector(http.server.BaseHTTPRequestHandler):
    allowed: set[str] = set()
    port = PORT
    lock = threading.Lock()
    last_minute = ""

    def log_message(self, *_):  # silencioso: o terminal do coletor só mostra os minutos gravados
        pass

    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, data: dict, code: int = 200) -> None:
        self._send(code, json.dumps(data, ensure_ascii=False).encode("utf-8"), "application/json; charset=utf-8")

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0].split("#", 1)[0]
        if path in ("/", "/trilha"):
            self.send_response(302)
            self.send_header("Location", "/" + TRAIL)
            self.end_headers()
            return
        if path == "/estudo/relogio.js":
            self._send(200, (HERE / "study_clock.js").read_bytes(), "text/javascript; charset=utf-8")
            return
        if path == "/estudo/total":
            result = compute()
            self._json({"hoje": result["today"], "total": result["minutes"]["total"], "trilha": result["minutes"]["trail"]})
            return
        relative = path.lstrip("/")
        if relative not in self.allowed:  # só arquivo versionado: o .env e o data/ nunca saem daqui
            self._send(404, b"nao encontrado", "text/plain; charset=utf-8")
            return
        body = (REPO / relative).read_bytes()
        if relative == TRAIL:
            tag = b'<script>window.RELOGIO_MODO="local";</script><script src="/estudo/relogio.js"></script></body>'
            body = body.replace(b"</body>", tag, 1)
        ctype = mimetypes.guess_type(relative)[0] or "text/plain"
        if relative.endswith((".md", ".yml", ".yaml", ".py", ".sql", ".tf", ".toml")):
            ctype = "text/plain"
        self._send(200, body, f"{ctype}; charset=utf-8" if ctype.startswith("text") else ctype)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/estudo/batida":
            self._send(404, b"", "text/plain")
            return
        origin = self.headers.get("Origin", "")
        if origin not in (f"http://127.0.0.1:{self.port}", f"http://localhost:{self.port}"):
            self._send(403, b"origem recusada", "text/plain; charset=utf-8")
            return
        length = min(int(self.headers.get("Content-Length") or 0), 2048)
        try:
            data = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            data = {}
        section = data.get("section", "")
        section = section if isinstance(section, str) and SECTION_RE.match(section) else ""
        minute = minute_key(dt.datetime.now(UTC))
        with self.lock:
            if minute != Collector.last_minute:
                Collector.last_minute = minute
                LIVE.mkdir(parents=True, exist_ok=True)
                with (LIVE / "pagina.jsonl").open("a", encoding="utf-8") as handle:
                    handle.write(json.dumps({"minute": minute, "section": section, "source": "local"}, sort_keys=True) + "\n")
                print(f"{dt.datetime.now(LOCAL_TZ):%H:%M} estudo na trilha · {section or '—'}", flush=True)
        self._json({"ok": True})


def cmd_serve(args) -> int:
    rows = read_jsonl(LIVE / "pagina.jsonl")
    Collector.last_minute = rows[-1]["minute"] if rows else ""
    Collector.allowed = tracked_files()
    Collector.port = args.port
    threading.Thread(target=lambda: (cmd_import(None), None), daemon=True).start()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), Collector)
    print(f"Trilha com o relógio: http://127.0.0.1:{args.port}/   (Ctrl-C encerra)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nrelógio encerrado; os minutos gravados ficam em data/estudo/pagina.jsonl")
    return 0


# ── o gancho do terminal no ~/.bashrc ────────────────────────────────────────────────────────────
def cmd_install_hook(_args) -> int:
    bashrc = Path.home() / ".bashrc"
    text = bashrc.read_text(encoding="utf-8") if bashrc.exists() else ""
    if HOOK_BEGIN in text:
        print("o gancho já está no ~/.bashrc")
        return 0
    shutil.copy2(bashrc, bashrc.with_name(".bashrc.antes-do-relogio")) if bashrc.exists() else None
    hook = HERE / "bash_hook.sh"
    block = f'\n{HOOK_BEGIN}\n[ -f "{hook}" ] && . "{hook}"\n{HOOK_END}\n'
    bashrc.write_text(text + block, encoding="utf-8")
    print(f"gancho acrescentado ao ~/.bashrc (cópia anterior em ~/.bashrc.antes-do-relogio); vale nos terminais novos")
    return 0


def cmd_uninstall_hook(_args) -> int:
    bashrc = Path.home() / ".bashrc"
    text = bashrc.read_text(encoding="utf-8")
    new = re.sub(rf"\n?{re.escape(HOOK_BEGIN)}.*?{re.escape(HOOK_END)}\n?", "\n", text, flags=re.S)
    if new == text:
        print("o gancho não estava no ~/.bashrc")
        return 0
    bashrc.write_text(new, encoding="utf-8")
    print("gancho retirado do ~/.bashrc; vale nos terminais novos")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("archive").set_defaults(fn=cmd_archive)
    sub.add_parser("import").set_defaults(fn=cmd_import)
    sub.add_parser("report").set_defaults(fn=cmd_report)
    serve = sub.add_parser("serve")
    serve.add_argument("--port", type=int, default=PORT)
    serve.set_defaults(fn=cmd_serve)
    artifact = sub.add_parser("import-artifact")
    artifact.add_argument("file")
    artifact.set_defaults(fn=cmd_import_artifact)
    sub.add_parser("install-hook").set_defaults(fn=cmd_install_hook)
    sub.add_parser("uninstall-hook").set_defaults(fn=cmd_uninstall_hook)
    args = parser.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
