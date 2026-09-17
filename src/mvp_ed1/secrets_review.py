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
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

#: O que é segredo no `.env` se reconhece pela chave — é para essas que
#: `make env` sorteia valores. Nome de banco, usuário e porta são configuração
#: e aparecem legitimamente em compose, Terraform e documentação.
SECRET_KEY_PATTERN = re.compile(r"PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL")

#: Abaixo disto uma coincidência textual não diz nada.
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
        for padrao in GENERIC_PATTERNS:
            casado = padrao.search(conteudo)
            if casado:
                achados.append(f"{relativo}: forma de credencial `{casado.group(0)[:24]}…`")

    # 4. Rastreado e ignorado ao mesmo tempo é contradição — o .gitignore
    #    engole a próxima versão do arquivo sem ninguém ver.
    for relativo in _git("ls-files", "-z", "-ci", "--exclude-standard", root=root):
        achados.append(f"{relativo}: rastreado, mas o .gitignore o ignora — o próximo `git add` não o vê")

    return achados


def main(argv: list[str] | None = None) -> int:
    root = pathlib.Path(argv[0]) if argv else pathlib.Path.cwd()
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
