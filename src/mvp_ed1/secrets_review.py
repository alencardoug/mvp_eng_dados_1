"""Revisão de segredos e do `.gitignore` — a primeira etapa de `make check`.

A regra inviolável nº 1 do `CLAUDE.md` diz que nenhum segredo entra no
repositório e que `.env.example` é versionado sem valores. Regra sem teste é
intenção; o que este módulo faz é medir as quatro formas de quebrá-la que já
aconteceram ou quase aconteceram aqui:

* o `.env` rastreado — ou deixando de ser ignorado;
* um valor do `.env` copiado para um arquivo versionado (senha num `.yml` de
  conector, chave do Airflow num compose);
* `.env.example` com valor preenchido;
* arquivo rastreado que o `.gitignore` também ignora — foi assim que os seeds
  do dbt sumiram em 2734fc9: o padrão engolia o que precisava ser versionado.

Cada achado é uma linha; a saída vazia é o que autoriza o resto do `check`.
Nenhuma ferramenta externa: `git` e o próprio `.env` são o oráculo.

**O modo `--historico`, e por que ele não pode depender do `.env` (Etapa 12,
B2).** Comparar com os valores atuais é cego exatamente onde a etapa precisa
enxergar: depois de uma rotação, o valor antigo não é mais conhecido, e o
*blob* que o contém não casa com nada. Medido na revisão do plano — senha
fictícia removida e rotacionada dá **zero** casamentos no blob antigo. A
detecção histórica é por **forma**, não por valor: atribuições nas três
sintaxes em que este repositório escreve chaves (ENV, YAML e JSON),
credencial embutida em URL, e as formas genéricas que já existiam.

**Placeholder é propriedade do valor, não do arquivo.** Nenhuma extensão
dispensa varredura: um segredo real gravado num `*.example` de um *commit*
antigo é achado como qualquer outro. O que dispensa é o valor ser
reconhecidamente um molde — vazio, `<…>`, `${…}`, `changeme` —, e cada molde
está declarado abaixo com o motivo.

**Pulado não é verificado.** Blob binário ou grande demais entra na lista de
pulados, com objeto, caminho e motivo, e a lista é impressa. Contar quantos
foram pulados esconderia justamente o arquivo que ninguém olhou.
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass

#: O que é segredo no `.env` se reconhece pela chave — é para essas que
#: `make env` sorteia valores. Nome de banco, usuário e porta são configuração
#: e aparecem legitimamente em compose, Terraform e documentação.
SECRET_KEY_PATTERN = re.compile(r"PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL")

#: Abaixo disto uma coincidência textual não diz nada — nem o valor de uma
#: atribuição, salvo quando ele repete o usuário (`detectar`).
MIN_SECRET_LENGTH = 8

#: Formas que denunciam credencial independentemente do `.env`.
GENERIC_PATTERNS = (
    re.compile(r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),                      # chave de acesso AWS
    re.compile(r"\bghp_[A-Za-z0-9]{36}\b"),                   # token do GitHub
    re.compile(r"\bxox[abp]-[0-9A-Za-z-]{10,}\b"),             # token do Slack
    re.compile(r'"private_key_id"\s*:\s*"[0-9a-f]{40}"'),      # conta de serviço GCP
)

#: Extensões binárias que não se leem como texto.
BINARY_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".ico", ".woff", ".woff2", ".zip", ".gz"}

#: Atribuição de chave sensível, nas três sintaxes em que este repositório
#: escreve chaves: ENV (`CHAVE=valor`), YAML (`chave: valor`) e JSON
#: (`"chave": "valor"`, a dos conectores e do `tfstate`). A aspa que **fecha** a
#: chave é aceita antes do separador, a caixa é ignorada, e o valor para na
#: aspa ou na vírgula — sem isso, `{"password": "x", "user": "y"}` viraria um
#: valor só, que é como a contraprova da segunda rodada passou despercebida.
#: A aspa que **abre** o valor é capturada: valor entre aspas é literal de
#: texto, e expressão não existe ali (`placeholder`). O comprimento mínimo fica
#: em `detectar`, não aqui, porque a senha igual ao usuário não o respeita.
ASSIGNMENT_PATTERN = re.compile(
    r"""(?ix)
    ["']?(?P<chave>[a-z0-9_.-]*
        (?:password|passwd|secret|token|api[_-]?key|private[_-]?key|credential)
        [a-z0-9_.-]*)["']?
    \s*[=:]\s*
    (?P<aspa>["']?)(?P<valor>[^\s"',]+)
    """
)

#: Atribuição de usuário, nas mesmas três sintaxes — `POSTGRES_USER: airflow`,
#: `"username": "mvp"`. Só valores com cara de nome: referência não é usuário.
USER_PATTERN = re.compile(
    r"""(?ix)
    ["']?[a-z0-9_.-]*user(?:name)?["']?
    \s*[=:]\s*
    (?P<aspa>["']?)(?P<valor>[a-z0-9_.-]+)(?=["',\s]|$)
    """
)

#: Linha de configuração — `CHAVE: valor` do YAML ou `CHAVE=valor` do ENV, com
#: `- ` de lista ou `export` na frente: a chave abre a linha e o valor a fecha.
#: É só nela que um valor **sem aspas** é literal. `usuario = db_user` (Python,
#: HCL) e `connect(user=db_user, …)` são referência a variável — e até
#: 03/10/2026 usuário e senha atribuídos ao mesmo identificador viravam senha
#: de fábrica (RVF12-2-02). **Limite declarado:** `chave = valor` com espaços num
#: `.env` não é lido como literal; `make env` escreve sem espaços.
CONFIG_LINE_PATTERN = re.compile(
    r"""(?x)^\s*(?:-\s+)?(?:export\s+)?["']?[\w.-]+["']?(?:\s*:\s+|=)[^\s"',\#]+\s*(?:\#.*)?$"""
)

#: Credencial embutida em URL: `postgresql://usuario:senha@host/banco`.
URL_CREDENTIAL_PATTERN = re.compile(r"://(?P<chave>[^/:@\s]+):(?P<valor>[^@\s]+)@")

#: Moldes — o que **não** é segredo, reconhecido pelo valor e não pelo arquivo.
#: Cada um carrega o motivo, porque uma lista de regex sem motivo vira lixo que
#: ninguém ousa mexer.
#
#: A regra que organiza todas elas: **credencial é literal; referência não é.**
#: Aplicar a atribuição ao código-fonte sem isso acusa toda variável chamada
#: `password` — `password = quote_plus(...)` em `db.py`, `var.source_db_password`
#: no Terraform, `$$AIRBYTE_CLIENT_SECRET` no Makefile. Medido: sem estas
#: regras, o repositório devolve 24 achados e **nenhum** é um segredo.
#
#: **Referência é o valor inteiro, não um caractere dele** (RVF12-03). Até
#: 03/10/2026 `$`, `(` e `[` em qualquer posição excusavam o valor, e uma senha
#: JSON entre aspas com `$` no meio passava como referência a variável. As
#: regras de referência agora ancoram no início, e a de expressão vive à parte.
PLACEHOLDER_RULES: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"^$"), "vazio — é o que `.env.example` declara"),
    (re.compile(r"^<[^>]*>"), "marcador `<…>`"),
    (re.compile(r"^\{[^}]*\}"), "interpolação — `{var}` de f-string"),
    (
        re.compile(r"^(var|local|data|module|each|self)\."),
        "referência do Terraform ou atributo de objeto",
    ),
    (re.compile(r"(?i)^change[_-]?me"), "molde literal `changeme`"),
    (re.compile(r"(?i)example|exemplo"), "molde literal `example`"),
    (re.compile(r"(?i)^x{3,}$"), "molde `xxx…`"),
    (re.compile(r"^\*+$"), "valor já mascarado `***`"),
    (re.compile(r"(?i)^(null|none|nil|true|false)$"), "literal da linguagem, não credencial"),
)

#: Referência a variável ou gabarito: `$VAR`, `$1`, `${…}`, `$(…)`, as formas
#: `$$` do Make e o `{{ … }}` de gabarito. **A forma tem de estar completa e
#: alcançar o fim do valor** (RVF12-2-01): até 03/10/2026 bastava o prefixo, e
#: `${Ab9Z7q1`, sem a chave que fecha, passava por referência. Ela é lida no
#: resto da linha, e não só no valor, porque o valor para no espaço e na vírgula
#: e a referência não: `${AIRFLOW_DB_PASSWORD:?defina …}` e
#: `"${trimsuffix(var.url, "/")}/token"` fecham depois do corte. Aspa dentro da
#: referência só entra com par — senão um valor JSON que abre `${` e não fecha
#: se fecharia na chave do objeto. `$1` é o parâmetro posicional do shell (RVF12-2-03);
#: `$1Ab9` continua literal. Medido no histórico em 03/10/2026: as 575
#: ocorrências que o prefixo `$` excusava, e a única do `{{`, são formas
#: completas que alcançam o fim do valor.
REFERENCE_RULE = (
    re.compile(
        r"""(?x)
        \$\$?(?:
            \{ (?: [^}"'\n] | "[^"\n]*" | '[^'\n]*' )* \}      # ${…}
          | \( (?: [^)"'\n] | "[^"\n]*" | '[^'\n]*' )* \)      # $(…)
          | [A-Za-z_]\w*                                      # $VAR
          | \d                                                # $1
        )
        | \{\{ (?: [^}"'\n] | "[^"\n]*" | '[^'\n]*' )* \}\}    # {{ … }}
        """
    ),
    "referência — `$VAR`, `$1`, `${…}`, `$(…)`, `$$VAR` do Make, `{{ … }}` de gabarito",
)

#: **Limite declarado desta regra:** uma senha escrita à mão só com letras
#: (`correcthorsebattery`) é excusada por ela. Vale aqui porque `make env`
#: sorteia valores com dígitos, e porque as formas conhecidas (`GENERIC_PATTERNS`)
#: e a comparação com os valores do `.env` cobrem o resto — mas é uma escolha,
#: não uma cobertura, e está escrita para ser revista quando deixar de valer.
#: Ela não excusa a senha **igual ao usuário**: foi assim que `airflow`/`airflow`
#: ficou na composição do Airflow até 0b89b3d sem a varredura ver (RVF12-01).
#: Por isso vive fora de `PLACEHOLDER_RULES` — referência repetida continua
#: molde (`{usuario}:{usuario}` num f-string), palavra repetida não.
WORD_RULE = (
    re.compile(r"^[A-Za-z][A-Za-z_.\-]*[}\],;]?$"),
    "palavra única sem dígito — identificador ou molde, não valor gerado",
)

#: Expressão só existe **fora** de literal de texto: `quote_plus(...)` em
#: `db.py`, `airbyte.token()`, o grupo `\(\S*\)` do `sed` no Makefile, o `(?!…)`
#: de uma regex citada num documento. Entre aspas ou numa URL, `Ab9(Z7q1` é
#: literal — e é entre aspas, no JSON dos conectores, que uma credencial gerada
#: aparece. **Limite declarado:** valor sem aspa que comece como chamada
#: (`Ab9(…`) é tomado por código; `make env` sorteia só `A-Za-z0-9`.
EXPRESSION_RULES: tuple[tuple[re.Pattern[str], str], ...] = (
    (
        re.compile(r"^[A-Za-z_][\w.]*[(\[]"),
        "expressão, não literal — chamada de função ou indexação",
    ),
    (
        re.compile(r"^\\?[(\[]"),
        "expressão, não literal — grupo ou classe de expressão regular",
    ),
)

#: Blob maior que isto não é lido — e entra na lista de pulados, por nome.
MAX_BLOB_BYTES = 5 * 1024 * 1024

#: Onde vivem os achados históricos já tratados (D48). O dono documental
#: definitivo é fixado em B6.
TRATADOS_PATH = pathlib.Path("docs/segredos_tratados.yml")


def placeholder(
    valor: str,
    *,
    literal: bool = False,
    igual_ao_usuario: bool = False,
    contexto: str | None = None,
) -> str | None:
    """O motivo de `valor` ser molde, ou `None` se ele é um valor de verdade.

    `literal` diz que o valor está num literal de texto — entre aspas ou numa
    URL —, onde não há expressão a excusar. `igual_ao_usuario` tira a regra da
    palavra sem dígito: o par de fábrica não é identificador. `contexto` é o
    resto da linha a partir do valor, onde a referência é lida; sem ele, só o
    próprio valor.
    """
    referencia = REFERENCE_RULE[0].match(valor if contexto is None else contexto)
    if referencia and referencia.end() >= len(valor):
        return REFERENCE_RULE[1]
    regras = PLACEHOLDER_RULES
    if not literal:
        regras += EXPRESSION_RULES
    if not igual_ao_usuario:
        regras += (WORD_RULE,)
    for padrao, motivo in regras:
        if padrao.search(valor):
            return motivo
    return None


def mascarar(valor: str) -> str:
    """Dois caracteres e o tamanho. O valor nunca é impresso inteiro.

    Imprimir o segredo para denunciar o segredo é copiá-lo para a saída do CI,
    para o rolo do terminal e para o dossiê de revisão.
    """
    return f"{valor[:2]}*** ({len(valor)} caracteres)"


@dataclass(frozen=True)
class Achado:
    """Uma ocorrência de forma de credencial, onde quer que ela esteja."""

    caminho: str
    linha: int
    chave: str
    valor: str
    forma: str
    commit: str = ""

    @property
    def identidade(self) -> tuple[str, str, str]:
        """O que `docs/segredos_tratados.yml` cita: commit, caminho e chave."""
        return (self.commit, self.caminho, self.chave)

    def __str__(self) -> str:
        onde = f"{self.commit[:12]}  " if self.commit else ""
        return f"{onde}{self.caminho}:{self.linha}  {self.chave}={mascarar(self.valor)}  [{self.forma}]"


def _literal(linha: str, casado: re.Match[str]) -> bool:
    """O valor de uma atribuição é literal: entre aspas, ou numa linha de configuração."""
    return bool(casado.group("aspa")) or CONFIG_LINE_PATTERN.match(linha) is not None


def detectar(texto: str) -> list[Achado]:
    """As formas de credencial num texto, sem saber valor nenhum de antemão.

    O caminho e o commit ficam vazios aqui: quem chama sabe onde leu.

    Senha igual ao usuário — o par de fábrica, `airflow`/`airflow` — não tem
    comprimento mínimo nem passa pela regra da palavra sem dígito; referência
    repetida continua molde. O usuário vem da mesma URL ou de qualquer
    atribuição de usuário do mesmo texto, e os dois lados do par precisam ser
    literais — entre aspas ou numa linha de configuração (`CONFIG_LINE_PATTERN`).
    """
    linhas = texto.splitlines()
    usuarios = {
        casado.group("valor")
        for linha in linhas
        for casado in USER_PATTERN.finditer(linha)
        if _literal(linha, casado)
    }
    achados: list[Achado] = []
    for numero, linha in enumerate(linhas, start=1):
        for casado in ASSIGNMENT_PATTERN.finditer(linha):
            valor = casado.group("valor")
            igual = valor in usuarios and _literal(linha, casado)
            if (not igual and len(valor) < MIN_SECRET_LENGTH) or placeholder(
                valor,
                literal=bool(casado.group("aspa")),
                igual_ao_usuario=igual,
                contexto=linha[casado.start("valor"):],
            ) is not None:
                continue
            achados.append(Achado("", numero, casado.group("chave"), valor, "atribuição"))
        for casado in URL_CREDENTIAL_PATTERN.finditer(linha):
            valor = casado.group("valor")
            igual = valor == casado.group("chave")
            if placeholder(
                valor, literal=True, igual_ao_usuario=igual, contexto=linha[casado.start("valor"):]
            ) is not None:
                continue
            achados.append(
                Achado("", numero, f"credencial de {casado.group('chave')}", valor, "URL")
            )
        for padrao in GENERIC_PATTERNS:
            casado = padrao.search(linha)
            if casado:
                achados.append(
                    Achado("", numero, "forma genérica", casado.group(0), "forma conhecida")
                )
    return achados


def _git(*args: str, root: pathlib.Path) -> list[str]:
    saida = subprocess.run(["git", *args], cwd=root, capture_output=True, text=True, check=True).stdout
    return [linha for linha in saida.split("\0" if "-z" in args else "\n") if linha]


def read_env(path: pathlib.Path) -> dict[str, str]:
    """`CHAVE=valor` por linha, ignorando comentários e vazios; sem interpolação."""
    valores: dict[str, str] = {}
    if not path.exists():
        return valores
    for linha in path.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, valor = linha.split("=", 1)
        valores[chave.strip()] = valor.strip().strip('"').strip("'")
    return valores


def secret_values(env: dict[str, str]) -> dict[str, str]:
    """Os valores do `.env` que, encontrados num arquivo versionado, são vazamento."""
    return {
        chave: valor
        for chave, valor in env.items()
        if SECRET_KEY_PATTERN.search(chave) and len(valor) >= MIN_SECRET_LENGTH
    }


def review(root: pathlib.Path) -> list[str]:
    """Todos os achados, uma linha cada. Lista vazia é aprovação."""
    achados: list[str] = []
    rastreados = _git("ls-files", "-z", root=root)

    # 1. O .env não é rastreado e continua ignorado.
    if ".env" in rastreados:
        achados.append(".env está rastreado pelo git — remova do índice e rode o histórico")
    ignorado = subprocess.run(["git", "check-ignore", "-q", ".env"], cwd=root)
    if ignorado.returncode != 0:
        achados.append(".env não é ignorado pelo .gitignore")

    # 2. .env.example declara chaves, nunca valores.
    exemplo = root / ".env.example"
    if exemplo.exists():
        for numero, linha in enumerate(exemplo.read_text(encoding="utf-8").splitlines(), start=1):
            texto = linha.strip()
            if texto and not texto.startswith("#") and "=" in texto and texto.split("=", 1)[1].strip():
                achados.append(f".env.example:{numero}: chave com valor preenchido ({texto.split('=', 1)[0]})")
    else:
        achados.append(".env.example não existe")

    # 3. Nenhum valor do .env, nem forma genérica de credencial, em arquivo rastreado.
    segredos = secret_values(read_env(root / ".env"))
    for relativo in rastreados:
        caminho = root / relativo
        if caminho.suffix.lower() in BINARY_SUFFIXES or not caminho.is_file():
            continue
        try:
            conteudo = caminho.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for chave, valor in segredos.items():
            if valor in conteudo:
                achados.append(f"{relativo}: contém o valor de {chave} do .env")
        # Os detectores por forma valem aqui também: uma declaração, dois
        # alcances. O que o modo rastreado acrescenta é achar hoje o que o
        # histórico acharia amanhã, antes de o commit existir.
        for achado in detectar(conteudo):
            achados.append(
                f"{relativo}:{achado.linha}: {achado.chave}={mascarar(achado.valor)} "
                f"[{achado.forma}]"
            )

    # 4. Rastreado e ignorado ao mesmo tempo é contradição — o .gitignore
    #    engole a próxima versão do arquivo sem ninguém ver.
    for relativo in _git("ls-files", "-z", "-ci", "--exclude-standard", root=root):
        achados.append(f"{relativo}: rastreado, mas o .gitignore o ignora — o próximo `git add` não o vê")

    return achados


# ── O histórico ─────────────────────────────────────────────────────────────
@dataclass(frozen=True)
class Pulado:
    """Blob que a varredura não leu — nomeado, nunca só contado."""

    objeto: str
    caminho: str
    motivo: str

    def __str__(self) -> str:
        return f"{self.objeto[:12]}  {self.caminho}  pulado: {self.motivo}"


def _blobs_do_historico(root: pathlib.Path) -> dict[str, tuple[str, str]]:
    """Cada blob que já existiu → (primeiro commit que o contém, caminho).

    A caminhada é do mais antigo para o mais novo, então o commit registrado é
    o que **introduziu** o conteúdo — que é o que se cita ao rotacionar.
    """
    por_blob: dict[str, tuple[str, str]] = {}
    for commit in _git("rev-list", "--all", "--reverse", root=root):
        for linha in _git("ls-tree", "-r", "--full-tree", commit, root=root):
            cabecalho, _, caminho = linha.partition("\t")
            partes = cabecalho.split()
            if len(partes) < 3 or partes[1] != "blob":
                continue
            por_blob.setdefault(partes[2], (commit, caminho))
    return por_blob


def _conteudos(root: pathlib.Path, objetos: list[str]) -> dict[str, bytes]:
    """Lê vários blobs num processo só — `git cat-file --batch`."""
    if not objetos:
        return {}
    processo = subprocess.run(
        ["git", "cat-file", "--batch"],
        cwd=root, input="\n".join(objetos).encode() + b"\n", capture_output=True, check=True,
    )
    saida, corpos, posicao = processo.stdout, {}, 0
    for objeto in objetos:
        fim_cabecalho = saida.index(b"\n", posicao)
        partes = saida[posicao:fim_cabecalho].split()
        tamanho = int(partes[2])
        inicio = fim_cabecalho + 1
        corpos[objeto] = saida[inicio : inicio + tamanho]
        posicao = inicio + tamanho + 1  # o \n que o git põe depois do corpo
    return corpos


def _tratados(root: pathlib.Path) -> dict[tuple[str, str, str], str]:
    """Achados históricos já resolvidos pelo Owner (D48), por identidade."""
    caminho = root / TRATADOS_PATH
    if not caminho.exists():
        return {}
    import yaml

    bruto = yaml.safe_load(caminho.read_text(encoding="utf-8")) or {}
    resultado: dict[tuple[str, str, str], str] = {}
    for item in bruto.get("tratados", []):
        chave = (str(item["commit"]), str(item["caminho"]), str(item["chave"]))
        resultado[chave] = f"{item.get('tratamento', 'tratado')} — {item.get('motivo', '')}".strip(" —")
    return resultado


def historico(root: pathlib.Path) -> tuple[list[Achado], list[Pulado], list[str]]:
    """Varre todo blob que já existiu. Devolve achados, pulados e avisos.

    Nenhum valor do `.env` participa: a detecção é por forma, e é por isso que
    ela enxerga o que foi rotacionado depois.
    """
    avisos: list[str] = []
    if _git("log", "--all", "--diff-filter=A", "--format=%H", "--", ".env", root=root):
        avisos.append(".env já foi adicionado ao histórico — o blob existe e precisa de decisão")

    por_blob = _blobs_do_historico(root)
    tamanhos = {}
    if por_blob:
        entrada = "\n".join(por_blob) + "\n"
        processo = subprocess.run(
            ["git", "cat-file", "--batch-check=%(objectname) %(objectsize)"],
            cwd=root, input=entrada, capture_output=True, text=True, check=True,
        )
        for linha in processo.stdout.split("\n"):
            if linha.strip():
                objeto, tamanho = linha.split()
                tamanhos[objeto] = int(tamanho)

    pulados: list[Pulado] = []
    a_ler: list[str] = []
    for objeto, (_commit, caminho) in por_blob.items():
        if pathlib.PurePath(caminho).suffix.lower() in BINARY_SUFFIXES:
            pulados.append(Pulado(objeto, caminho, "extensão binária"))
        elif tamanhos.get(objeto, 0) > MAX_BLOB_BYTES:
            pulados.append(Pulado(objeto, caminho, f"{tamanhos[objeto]} bytes > {MAX_BLOB_BYTES}"))
        else:
            a_ler.append(objeto)

    achados: list[Achado] = []
    for objeto, corpo in _conteudos(root, a_ler).items():
        commit, caminho = por_blob[objeto]
        try:
            texto = corpo.decode("utf-8")
        except UnicodeDecodeError:
            pulados.append(Pulado(objeto, caminho, "não é texto UTF-8"))
            continue
        for achado in detectar(texto):
            achados.append(
                Achado(caminho, achado.linha, achado.chave, achado.valor, achado.forma, commit)
            )
    return achados, pulados, avisos


def _relatar_historico(root: pathlib.Path) -> int:
    achados, pulados, avisos = historico(root)
    tratados = _tratados(root)

    nao_tratados = []
    for achado in achados:
        motivo = tratados.get(achado.identidade)
        if motivo:
            print(f"tratado: {achado}  → {motivo}")
        else:
            nao_tratados.append(achado)

    if pulados:
        print(f"\npulados ({len(pulados)}) — pulado não é verificado:", file=sys.stderr)
        for pulado in pulados:
            print(f"  {pulado}", file=sys.stderr)

    for aviso in avisos:
        print(f"\nAVISO: {aviso}", file=sys.stderr)

    if nao_tratados:
        print(f"\n{len(nao_tratados)} achado(s) não tratado(s) no histórico:", file=sys.stderr)
        for achado in nao_tratados:
            print(f"  {achado}", file=sys.stderr)
        print(
            f"\nCada um se resolve rotacionando e registrando em {TRATADOS_PATH} (D48), "
            "com commit, caminho, chave, tratamento e motivo.",
            file=sys.stderr,
        )
        return 1

    if avisos:
        return 1
    print(
        f"revisão do histórico: nada não tratado "
        f"({len(achados)} achado(s), todos registrados; {len(pulados)} blob(s) pulado(s))"
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    argumentos = list(argv or [])
    historico_pedido = "--historico" in argumentos
    if historico_pedido:
        argumentos.remove("--historico")
    root = pathlib.Path(argumentos[0]) if argumentos else pathlib.Path.cwd()

    if historico_pedido:
        return _relatar_historico(root)

    achados = review(root)
    for achado in achados:
        print(achado, file=sys.stderr)
    if achados:
        print(f"\nrevisão de segredos: {len(achados)} achado(s)", file=sys.stderr)
        return 1
    print("revisão de segredos: nada encontrado nos arquivos rastreados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
