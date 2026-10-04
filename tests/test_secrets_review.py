"""A revisão de segredos de `make check`, provada num repositório efêmero.

Cada forma de quebrar a regra inviolável nº 1 tem a sua contraprova: o teste
monta um repositório limpo que passa, introduz a quebra e exige o achado.

**Os valores fictícios deste arquivo são montados em partes.** Escritos
inteiros, a própria revisão acusaria este arquivo — que é exatamente o que ela
deve fazer, e por isso a fixture obedece à regra que prova. O nome da constante
também importa: `SENHA` não casa com o detector de atribuição, `PASSWORD`
casaria.
"""

from __future__ import annotations

import json
import pathlib
import re
import subprocess
import textwrap

import pytest

from mvp_ed1 import secrets_review

#: Valores fictícios, em partes. Nenhum deles jamais existiu em lugar nenhum.
SENHA = "s3nh4-" + "muito-longa-e-aleatoria"
SENHA_ROTACIONADA = "s3nh4-" + "nova-depois-da-rotacao-9f2c"
SEGREDO_JWT = "jwt" + "0123456789abcdef"
TOKEN_GITHUB = "ghp_" + "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8"


def _git(root: pathlib.Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)


def _commit(root: pathlib.Path, mensagem: str) -> str:
    _git(root, "add", "-A")
    _git(root, "commit", "-q", "-m", mensagem)
    return subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=root, check=True, capture_output=True, text=True
    ).stdout.strip()


def _escrever_env(root: pathlib.Path, senha: str) -> None:
    (root / ".env").write_text(
        textwrap.dedent(
            f"""\
            WAREHOUSE_DB_NAME=warehouse_db
            WAREHOUSE_DB_PASSWORD={senha}
            AIRFLOW_JWT_SECRET={SEGREDO_JWT}
            """
        ),
        encoding="utf-8",
    )


@pytest.fixture
def repositorio(tmp_path: pathlib.Path) -> pathlib.Path:
    _git(tmp_path, "init", "-q")
    _git(tmp_path, "config", "user.email", "teste@exemplo.local")
    _git(tmp_path, "config", "user.name", "teste")
    (tmp_path / ".gitignore").write_text(".env\n*.log\n", encoding="utf-8")
    (tmp_path / ".env.example").write_text(
        textwrap.dedent(
            """\
            # modelo
            WAREHOUSE_DB_NAME=
            WAREHOUSE_DB_PASSWORD=
            AIRFLOW_JWT_SECRET=
            """
        ),
        encoding="utf-8",
    )
    _escrever_env(tmp_path, SENHA)
    (tmp_path / "docs.md").write_text(
        "O banco chama-se warehouse_db e a senha vem do .env.\n", encoding="utf-8"
    )
    _commit(tmp_path, "base")
    return tmp_path


def test_repositorio_limpo_passa_e_o_nome_do_banco_nao_e_segredo(repositorio: pathlib.Path) -> None:
    assert secrets_review.review(repositorio) == []
    assert set(secrets_review.secret_values(secrets_review.read_env(repositorio / ".env"))) == {
        "WAREHOUSE_DB_PASSWORD", "AIRFLOW_JWT_SECRET",
    }


def test_valor_do_env_num_arquivo_rastreado_e_acusado_com_a_chave(repositorio: pathlib.Path) -> None:
    (repositorio / "conector.yml").write_text(f"password: {SENHA}\n", encoding="utf-8")
    _git(repositorio, "add", "conector.yml")
    achados = secrets_review.review(repositorio)
    assert "conector.yml: contém o valor de WAREHOUSE_DB_PASSWORD do .env" in achados
    # E o detector por forma o acha também, sem consultar o `.env` — é a mesma
    # declaração servindo os dois alcances.
    assert any("conector.yml:1: password=" in a for a in achados), achados


def test_env_example_com_valor_e_env_rastreado_sao_acusados(repositorio: pathlib.Path) -> None:
    (repositorio / ".env.example").write_text(
        "WAREHOUSE_DB_NAME=\nWAREHOUSE_DB_PASSWORD=abc\n", encoding="utf-8"
    )
    _git(repositorio, "add", "-f", ".env", ".env.example")
    achados = secrets_review.review(repositorio)
    assert ".env está rastreado pelo git — remova do índice e rode o histórico" in achados
    assert ".env.example:2: chave com valor preenchido (WAREHOUSE_DB_PASSWORD)" in achados
    # O próprio .env rastreado contém os seus valores, e é acusado como qualquer arquivo.
    assert ".env: contém o valor de WAREHOUSE_DB_PASSWORD do .env" in achados
    # Rastreado e ignorado ao mesmo tempo: a contradição que engoliu os seeds do dbt.
    assert ".env: rastreado, mas o .gitignore o ignora — o próximo `git add` não o vê" in achados


def test_forma_generica_de_credencial_e_acusada_sem_depender_do_env(repositorio: pathlib.Path) -> None:
    # Montada em partes: escrita inteira, a própria revisão acusaria este arquivo.
    cabecalho = "-----BEGIN " + "RSA PRIVATE KEY-----"
    (repositorio / "chave.pem").write_text(f"{cabecalho}\nMIIE...\n", encoding="utf-8")
    (repositorio / ".env").unlink()
    _git(repositorio, "add", "chave.pem")
    achados = secrets_review.review(repositorio)
    assert len(achados) == 1, achados
    assert achados[0].startswith("chave.pem:1: forma genérica=")
    assert "[forma conhecida]" in achados[0]


def test_gitignore_que_deixa_de_ignorar_o_env_e_acusado(repositorio: pathlib.Path) -> None:
    (repositorio / ".gitignore").write_text("*.log\n", encoding="utf-8")
    assert secrets_review.review(repositorio) == [".env não é ignorado pelo .gitignore"]


def test_o_repositorio_deste_projeto_passa() -> None:
    """A regra vale para o repositório real, não só para o efêmero."""
    raiz = pathlib.Path(__file__).resolve().parent.parent
    assert secrets_review.review(raiz) == []


# ── O histórico (Etapa 12, B2) ──────────────────────────────────────────────
#
# O modo rastreado é cego para o passado por construção: ele compara com os
# valores do `.env` **atual**. Depois de uma rotação, o valor antigo não é mais
# conhecido, e o blob que o contém não casa com nada. A varredura histórica
# detecta por **forma**, e estes testes são a prova de que ela enxerga
# exatamente onde a outra não enxerga.


def test_senha_rotacionada_some_do_modo_rastreado_e_o_historico_a_acha(repositorio):
    """A contraprova que justifica o bloco inteiro.

    A senha vaza num arquivo versionado, o arquivo é removido e a senha é
    rotacionada. O `.env` já não a contém: comparar por valor devolve zero. A
    forma `password: <valor>` continua no blob antigo, e é ela que se acha.
    """
    (repositorio / "conector.yml").write_text(f"password: {SENHA}\n", encoding="utf-8")
    vazamento = _commit(repositorio, "vazamento")

    (repositorio / "conector.yml").unlink()
    _escrever_env(repositorio, SENHA_ROTACIONADA)
    _commit(repositorio, "remove o arquivo e rotaciona a senha")

    # O modo rastreado passa — e passar é justamente o problema.
    assert secrets_review.review(repositorio) == []
    # E nenhum valor conhecido hoje aparece no blob antigo.
    assert SENHA not in (repositorio / ".env").read_text(encoding="utf-8")

    achados, _pulados, _avisos = secrets_review.historico(repositorio)
    vazados = [a for a in achados if a.caminho == "conector.yml"]
    assert len(vazados) == 1, achados
    assert vazados[0].commit == vazamento
    assert vazados[0].chave == "password"
    assert vazados[0].valor == SENHA
    # O valor não é impresso: dois caracteres e o tamanho.
    assert str(vazados[0]).endswith(f"password=s3*** ({len(SENHA)} caracteres)  [atribuição]")
    assert SENHA not in str(vazados[0])


def test_a_mesma_senha_e_achada_em_env_yaml_e_json(repositorio):
    """As três sintaxes em que este repositório escreve chaves.

    A do JSON é a que a segunda rodada de revisão do plano pegou: sem aceitar a
    aspa que **fecha** a chave, `{"password": "…"}` dava zero casamentos.
    """
    (repositorio / "servico.env").write_text(f"DB_PASSWORD={SENHA}\n", encoding="utf-8")
    (repositorio / "conector.yml").write_text(f"password: {SENHA}\n", encoding="utf-8")
    (repositorio / "estado.json").write_text(
        '{"user": "mvp", "password": "%s", "port": 5432}\n' % SENHA, encoding="utf-8"
    )
    _commit(repositorio, "vazamento nas três formas")

    for arquivo in ("servico.env", "conector.yml", "estado.json"):
        (repositorio / arquivo).unlink()
    _escrever_env(repositorio, SENHA_ROTACIONADA)
    _commit(repositorio, "remove e rotaciona")

    assert secrets_review.review(repositorio) == []
    achados, _p, _a = secrets_review.historico(repositorio)
    por_arquivo = {a.caminho: a for a in achados}
    assert {"servico.env", "conector.yml", "estado.json"} <= set(por_arquivo)
    for arquivo in ("servico.env", "conector.yml", "estado.json"):
        assert por_arquivo[arquivo].valor == SENHA, arquivo


def test_credencial_em_url_e_achada(repositorio):
    (repositorio / "profiles.yml").write_text(
        f"url: postgresql://mvp:{SENHA}@localhost:5432/warehouse\n", encoding="utf-8"
    )
    _commit(repositorio, "url com credencial")
    (repositorio / "profiles.yml").unlink()
    _commit(repositorio, "remove")

    achados, _p, _a = secrets_review.historico(repositorio)
    urls = [a for a in achados if a.forma == "URL"]
    assert len(urls) == 1, achados
    assert urls[0].valor == SENHA


def test_forma_generica_num_blob_antigo(repositorio):
    (repositorio / "ci.yml").write_text(f"token: {TOKEN_GITHUB}\n", encoding="utf-8")
    _commit(repositorio, "token")
    (repositorio / "ci.yml").unlink()
    _commit(repositorio, "remove")

    achados, _p, _a = secrets_review.historico(repositorio)
    formas = {a.forma for a in achados if a.caminho == "ci.yml"}
    assert "forma conhecida" in formas, achados


def test_placeholder_no_env_example_nao_acusa(repositorio):
    """Chave declarada sem valor é o que `.env.example` **deve** ter."""
    achados, _p, _a = secrets_review.historico(repositorio)
    assert [a for a in achados if a.caminho == ".env.example"] == []
    assert secrets_review.placeholder("") is not None
    assert secrets_review.placeholder("${DB_PASSWORD}") is not None
    assert secrets_review.placeholder("<sua-senha-aqui>") is not None
    assert secrets_review.placeholder(SENHA) is None


def test_segredo_real_num_arquivo_de_exemplo_e_achado(repositorio):
    """Nenhuma extensão dispensa varredura.

    O molde é propriedade do **valor**. Um segredo de verdade gravado num
    `config.example.yml` de um commit antigo é achado como qualquer outro — e
    é por isso que a regra não é "arquivos `*.example` não contam".
    """
    (repositorio / "config.example.yml").write_text(f"api_key: {SENHA}\n", encoding="utf-8")
    _commit(repositorio, "segredo de verdade num arquivo de molde")

    achados, _p, _a = secrets_review.historico(repositorio)
    de_exemplo = [a for a in achados if a.caminho == "config.example.yml"]
    assert len(de_exemplo) == 1, achados
    assert de_exemplo[0].valor == SENHA


def test_blob_grande_aparece_na_lista_de_pulados(repositorio):
    """Pulado não é verificado — e por isso é nomeado, não só contado."""
    grande = repositorio / "dump.sql"
    grande.write_text("-- " + ("x" * (secrets_review.MAX_BLOB_BYTES + 10)), encoding="utf-8")
    _commit(repositorio, "arquivo grande")

    _achados, pulados, _a = secrets_review.historico(repositorio)
    por_caminho = {p.caminho: p for p in pulados}
    assert "dump.sql" in por_caminho, pulados
    assert "bytes >" in por_caminho["dump.sql"].motivo
    assert por_caminho["dump.sql"].objeto  # o objeto é nomeado, para quem quiser olhar


def test_achado_tratado_sai_como_tratado_e_o_codigo_e_zero(repositorio, capsys):
    """D48: o veredito é "nada **não tratado**", não "nada encontrado".

    Um segredo rotacionado continua no histórico para sempre — reescrevê-lo é
    decisão do Owner, e para credencial local a decisão foi não reescrever. O
    registro é o que faz a §7 conviver com isso.
    """
    (repositorio / "conector.yml").write_text(f"password: {SENHA}\n", encoding="utf-8")
    vazamento = _commit(repositorio, "vazamento")
    (repositorio / "conector.yml").unlink()
    _escrever_env(repositorio, SENHA_ROTACIONADA)
    _commit(repositorio, "remove e rotaciona")

    assert secrets_review.main([str(repositorio), "--historico"]) == 1

    (repositorio / "docs").mkdir(exist_ok=True)
    (repositorio / secrets_review.TRATADOS_PATH).write_text(
        textwrap.dedent(
            f"""\
            tratados:
              - commit: {vazamento}
                caminho: conector.yml
                chave: password
                tratamento: rotacionada em 20/09/2026
                motivo: credencial local; histórico não reescrito (D48)
            """
        ),
        encoding="utf-8",
    )
    _commit(repositorio, "registra o tratamento")

    assert secrets_review.main([str(repositorio), "--historico"]) == 0
    saida = capsys.readouterr()
    assert "tratado:" in saida.out
    assert "rotacionada em 20/09/2026" in saida.out
    assert "nada não tratado" in saida.out
    assert SENHA not in saida.out and SENHA not in saida.err


def test_env_no_historico_e_aviso_mesmo_sem_achado(repositorio):
    """`.env` que já esteve rastreado deixa um blob, e o blob é a questão."""
    _git(repositorio, "add", "-f", ".env")
    _commit(repositorio, "adiciona o .env por engano")
    _git(repositorio, "rm", "-q", "--cached", ".env")
    _commit(repositorio, "remove do índice")

    _achados, _pulados, avisos = secrets_review.historico(repositorio)
    assert any(".env já foi adicionado ao histórico" in a for a in avisos), avisos


# ── Os moldes não excusam literal (revisão final da Etapa 12) ───────────────


@pytest.mark.parametrize("simbolo", ["x", "$", "(", "[", "{{"])
def test_literal_entre_aspas_com_simbolo_no_meio_e_achado(simbolo):
    """RVF12-03: `$`, `(` e `[` no meio de um valor JSON não fazem dele referência.

    É a contraprova do revisor, com `{{` junto — a regra de interpolação também
    deixou de valer em qualquer posição. `x` é o controle, que sempre foi achado.
    """
    chave = "pass" + "word"
    valor = "Ab9" + simbolo + "Z7q1"
    achados = secrets_review.detectar(json.dumps({chave: valor}))
    assert [(a.chave, a.valor) for a in achados] == [(chave, valor)]


def test_referencias_e_expressoes_continuam_moldes():
    """O aperto não pode devolver os 24 falsos achados que as regras evitam.

    Uma linha por forma que a sonda do histórico achou excusada pelas regras
    antigas: Make, Compose, Python, o `sed` do Makefile e o Terraform.
    """
    texto = "\n".join(
        [
            "PGPASSWORD=$$AIRBYTE_CLIENT_SECRET",
            'password: "${DB_PASSWORD}"',
            "secret: ${AIRFLOW_JWT_SECRET:?defina no .env}",
            'password = quote_plus(os.environ["WAREHOUSE_DB_PASSWORD"])',
            "token = airbyte.token()",
            r"s/.*Client-Secret: \(\S*\).*/AIRBYTE_CLIENT_SECRET=\1/p",
            r"POSTGRES_PASSWORD: (?!\$)\S+",
            "password = var.source_db_password",
            'echo "SOURCE_DB_PASSWORD=$$(pw)"; \\',
            'token_url     = "${trimsuffix(var.airbyte_server_url, "/")}/applications/token"',
            "password: \"{{ env_var('DBT_PASSWORD') }}\"",
        ]
    )
    assert secrets_review.detectar(texto) == []


@pytest.mark.parametrize("valor", ["${Ab9Z7q1", "$(Ab9Z7q1", "{{Ab9Z7q1", "${A}Ab9Z7q1", "$1Ab9Z7q1"])
@pytest.mark.parametrize("sintaxe", ["json", "yaml"])
def test_referencia_incompleta_ou_seguida_de_literal_e_achada(valor, sintaxe):
    """RVF12-2-01: referência é forma completa que alcança o fim do valor.

    `${` sem a chave que fecha não é referência — e a chave que fecha o objeto
    JSON em volta não pode completá-la. Referência seguida de literal também
    não é molde: o que sobra depois dela é texto que alguém escreveu.
    """
    chave = "pass" + "word"
    texto = json.dumps({chave: valor}) if sintaxe == "json" else f"{chave}: {valor}"
    achados = secrets_review.detectar(texto)
    assert [(a.chave, a.valor) for a in achados] == [(chave, valor)]


def test_parametro_posicional_do_shell_e_referencia():
    """RVF12-2-03: `$1` na URL de um script é o parâmetro, não a senha.

    A regra anterior só aceitava letra, sublinhado, chave ou parêntese depois
    do `$`, e a URL virava credencial literal.
    """
    url = 'url="postgresql' + "://" + "reader:" + "$1" + '@localhost/db"'
    assert secrets_review.detectar(url) == []


def test_senha_igual_ao_usuario_e_achada_mesmo_curta_e_sem_digito():
    """RVF12-01: o par de fábrica que ficou na composição do Airflow até 0b89b3d.

    Sozinho, o valor é excusado — palavra única sem dígito, e abaixo do
    comprimento mínimo. Repetindo o usuário, na URL ou numa atribuição do mesmo
    texto, ele é credencial. Referência repetida continua molde: `{u}:{u}` num
    f-string e `${U}:${U}` numa composição não são par de fábrica.
    """
    usuario = "air" + "flow"
    chave = "POSTGRES_" + "PASSWORD"
    composicao = "\n".join(
        [
            f"CONN: postgresql+psycopg2://{usuario}:{usuario}@airflow_db:5432/{usuario}",
            f"POSTGRES_USER: {usuario}",
            f"{chave}: {usuario}",
        ]
    )
    assert secrets_review.placeholder(usuario) is not None

    achados = secrets_review.detectar(composicao)
    assert [(a.linha, a.forma, a.valor) for a in achados] == [
        (1, "URL", usuario),
        (3, "atribuição", usuario),
    ]

    moldes = "\n".join(
        [
            "url = f'postgresql://{usuario}:{usuario}@localhost/banco'",
            "CONN: postgresql://${AIRFLOW_DB_USER}:${AIRFLOW_DB_USER}@airflow_db/airflow",
        ]
    )
    assert secrets_review.detectar(moldes) == []


@pytest.mark.parametrize(
    "texto",
    [
        "{u} = db_user\n{s} = db_user\n",
        "connect(\n    {u}=db_user,\n    {s}=db_user,\n)\n",
    ],
    ids=["atribuicao_python", "argumentos_nomeados"],
)
def test_identificador_repetido_no_codigo_nao_e_par_de_fabrica(texto):
    """RVF12-2-02: usuário e senha atribuídos à mesma variável são referência.

    O par de fábrica só existe entre literais — entre aspas, ou numa linha de
    configuração YAML ou ENV, como a composição do Airflow até 0b89b3d.
    """
    assert secrets_review.detectar(texto.format(u="u" + "ser", s="pass" + "word")) == []


@pytest.mark.parametrize(
    "texto",
    [
        '{{"username": "reader", "{s}": "reader"}}',
        '{u} = "reader"\n{s} = "reader"\n',
        "POSTGRES_USER=reader\nPOSTGRES_{S}=reader\n",
        "environment:\n  - POSTGRES_USER=reader\n  - POSTGRES_{S}=reader\n",
    ],
    ids=["json", "python_entre_aspas", "env", "lista_da_composicao"],
)
def test_par_de_fabrica_entre_literais_continua_achado(texto):
    """O controle positivo do RVF12-2-02: a distinção não pode perder o literal."""
    senha = "pass" + "word"
    achados = secrets_review.detectar(texto.format(u="u" + "ser", s=senha, S=senha.upper()))
    assert [a.valor for a in achados] == ["reader"]


# ── As composições tiram credencial do ambiente, não do próprio arquivo ─────


def test_nenhuma_composicao_embute_credencial():
    """A regra inviolável nº 1 vale também para o que é "só interno".

    Até 20/09/2026 `docker-compose.airflow.yml` trazia `airflow`/`airflow` na
    URL de conexão e no `POSTGRES_PASSWORD` do banco de metadados. Era interno
    à rede do Compose e nunca exposto — e ainda assim uma credencial fora do
    `.env`, que é uma exceção não declarada à regra.

    Até 03/10/2026 a varredura por forma não pegava esse caso: `airflow` é
    palavra única sem dígito, e a regra que excusa `var.password` e `$SENHA`
    excusava essa também. A senha igual ao usuário passou a ser achada sempre
    (RVF12-01); este guarda continua, porque cobre o que o detector não cobre —
    usuário literal, e senha literal **diferente** do usuário e só com letras.
    """
    raiz = pathlib.Path(__file__).resolve().parent.parent
    composicoes = sorted((raiz / "docker").glob("docker-compose*.yml"))
    assert composicoes, "nenhuma composição encontrada"

    atribuicoes = re.compile(r"(?i)^\s*(POSTGRES_PASSWORD|POSTGRES_USER)\s*:\s*(?P<valor>\S+)")
    em_url = re.compile(r"://(?P<credencial>[^/:@\s]+:[^@\s]+)@")

    culpados: list[str] = []
    for composicao in composicoes:
        for numero, linha in enumerate(
            composicao.read_text(encoding="utf-8").splitlines(), start=1
        ):
            atribuicao = atribuicoes.match(linha)
            if atribuicao and "${" not in atribuicao.group("valor"):
                culpados.append(f"{composicao.name}:{numero}: valor literal em {linha.strip()}")
            url = em_url.search(linha)
            if url and "${" not in url.group("credencial"):
                culpados.append(f"{composicao.name}:{numero}: credencial literal na URL")

    assert culpados == [], "\n".join(culpados)
