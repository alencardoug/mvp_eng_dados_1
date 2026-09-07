# Como usar a skill `revisao`

> **Para quem:** o Owner. Este arquivo responde às perguntas de operação — o que
> roda sozinho, o que é preciso digitar, como desfazer, como levar para outro
> projeto.
>
> **Não vive aqui:** o procedimento que os agentes seguem, que está no
> [`SKILL.md`](SKILL.md) ao lado. Um é para pessoa, o outro é para agente.

## 1. Para que serve

O projeto é trabalhado por **dois** agentes com orçamentos de esforço
diferentes: um gera o código, outro revisa. A skill faz a passagem entre eles
deixar de depender da memória de qualquer um dos dois.

Ela produz um `REVISAO.md` na raiz com quatro coisas que o `git` **não** dá:

- onde o revisor deve gastar esforço — o que é declaração e o que é derivado;
- o que foi executado, com a saída **literal** dos comandos;
- o que **não** foi verificado;
- que premissas sobre o ambiente o autor assumiu sem confirmar.

O diff não é repetido: quem revisa lê o `git`.

## 2. O que acontece se você não fizer nada

**Nada.** Não há *hook* configurado, nada roda em segundo plano, e a ferramenta
só usa biblioteca padrão do Python — não há dependência a instalar. Os arquivos
ficam inertes até alguém invocar a skill.

Skill não se instala: ela é descoberta pelo diretório `.claude/skills/`, e passa
a existir no instante em que o arquivo é escrito.

**Uma exceção, e é honesto dizê-la:** o Codex lê o `AGENTS.md` por padrão, e ele
ganhou uma seção sobre esta passagem. São instruções, não execução — mas é a
única coisa que muda de comportamento sem ninguém digitar nada. O Claude Code lê
o `CLAUDE.md`, não o `AGENTS.md`, então do lado dele nada muda por padrão.

### O dossiê parado não transforma ninguém em revisor

Um `REVISAO.md` na raiz é um sinal forte — mais forte que o texto do
`AGENTS.md` —, porque parece tarefa endereçada a quem abrir o projeto. Por isso
os dois arquivos dizem, explicitamente, que **papel não é fixo**: ele vem do seu
pedido, e o dossiê é um convite em aberto, não uma ordem.

Se você pedir implementação com um dossiê pendente na raiz e mesmo assim o
agente começar a revisar, é defeito de instrução — vale corrigir o texto, não
contornar apagando o arquivo.

## 3. Como usar

### Passar uma entrega para revisão

Peça ao agente que gerou o código: **"prepare a revisão"**, ou digite `/revisao`.
Ele roda a ferramenta, que coleta o mecânico, e preenche as seções que só o
autor sabe:

```bash
python3 .claude/skills/revisao/dossie.py --desde origin/main
python3 .claude/skills/revisao/dossie.py --conferir
```

O `--conferir` recusa o dossiê enquanto qualquer seção do autor continuar em
branco, ou enquanto algum comando de verificação estiver falhando sem
explicação. Não é possível passar um dossiê pela metade sem que isso apareça.

### Receber a revisão

O revisor escreve os achados na tabela ao fim do `REVISAO.md`, um por linha, com
veredito `bloqueante`, `ajuste` ou `observação`.

### Fechar

Peça ao agente que gerou: **"aplique os achados"**. Ele preenche a coluna
*Situação* de cada achado — o que foi feito, ou por que não — e apaga o
`REVISAO.md` no *commit* que entrega. Achado recusado precisa de motivo escrito;
silêncio não conta como resposta.

## 4. Como reverter

Reverta os *commits* da skill, do mais novo para o mais antigo. Para descobrir
quais são:

```bash
git log --oneline -- .claude/skills/revisao AGENTS.md REVISAO.md
git revert <do mais novo> ... <eceaa2c>
```

Reverter só o primeiro deixaria os arquivos acrescentados depois órfãos.

Ou, explicitamente, removendo os três lugares — não há nenhum outro:

```bash
rm -rf .claude/skills/revisao REVISAO.md
git checkout HEAD~1 -- AGENTS.md
```

Não existe estado fora do repositório: nem configuração global, nem cache, nem
nada em `~/.claude`. Apagar os arquivos devolve o comportamento anterior por
completo.

## 5. Como instalar em outro projeto

Copie **um diretório** e edite **um arquivo**:

```bash
mkdir -p /caminho/do/projeto/.claude/skills
cp -r .claude/skills/revisao /caminho/do/projeto/.claude/skills/
```

Depois abra `comandos.txt` e troque os comandos pelos de verificação daquele
projeto — `pytest`, `npm test`, `cargo test`, o que for. É a **única** parte
específica de projeto.

Duas ressalvas:

**O caminho importa.** `dossie.py` acha a raiz do repositório contando três
níveis acima de si mesmo, então precisa ficar exatamente em
`.claude/skills/revisao/`. Movido para outro lugar, aponta para a pasta errada.

**Se o projeto novo também usa Codex**, copie junto a seção *"Passagem entre
agentes"* do `AGENTS.md`. Sem ela a skill funciona igual, mas o Codex não sabe
que existe um `REVISAO.md` para ler, e você teria que dizer isso a cada vez.

## 6. O que a skill não pressupõe

Ela **não** exige `make`, `dbt`, banco de dados nem qualquer ferramenta do
projeto: roda o que estiver escrito em `comandos.txt`, via *shell*. Os únicos
requisitos são `git` e um Python 3 para a própria ferramenta.

Se `comandos.txt` estiver vazio, o dossiê **diz** que nada foi medido, em vez de
fingir o contrário.
