# Relógio de estudo da trilha

> **O que esta pasta é:** o registro auditável das horas de aprendizado em torno da
> [trilha de estudo da fase local](../trilha_de_estudo_fase_local.html) — o tempo construindo o
> projeto com o Claude Code e o Codex, e o tempo estudando a trilha e executando os roteiros. A soma
> está em [`auditoria.md`](auditoria.md), refeita a cada fechamento.
>
> **O que não é:** documento do projeto nem componente da arquitetura. Como a trilha, fica fora do
> mapa de documentação, e nada no projeto depende dela.

## O que é medido, e de onde vem

| Atividade | Fonte | Regra |
|---|---|---|
| Construção com o Claude Code | transcrições do Claude Code (`~/.claude/projects/`) | eventos a até 15 min um do outro formam um bloco contínuo |
| ↳ o Claude trabalhando, você acompanhando | as mesmas | do evento ao seguinte, quando o seguinte não é um pedido seu |
| ↳ você entre turnos | as mesmas | do último evento até o seu pedido seguinte |
| Construção e revisão com o Codex | sessões do Codex abertas na pasta do projeto (`~/.codex/sessions/`) | eventos a até 15 min formam um bloco |
| Estudo na trilha | o relógio da página, local e no Artifact | um minuto conta quando a aba está visível e houve rolagem, clique ou tecla nos últimos 5 min |
| Execução no terminal | o gancho do bash, só dentro da pasta do projeto | um minuto conta quando houve tecla no terminal nos últimos 5 min: o Enter de cada comando e, enquanto ele roda, as teclas dentro dele (`psql`, contêiner) |

O total é a **união** dos minutos: um minuto em que o Claude trabalhava e você lia a trilha conta uma
vez. Os parâmetros ficam no começo de [`study_clock.py`](study_clock.py), e a auditoria os repete.

## No dia a dia

**Estudar na página local.** Da raiz do repositório:

```bash
python3 CONVERSAS_COM_CHAT/estudo/study_clock.py serve
```

Abra `http://127.0.0.1:8770/`. É a mesma trilha, com um selo no canto inferior direito que mostra o
tempo de hoje e o total somado. Ctrl-C no terminal encerra o coletor. Os links para `docs/` funcionam;
o coletor só serve arquivos versionados no Git, nunca o `.env` nem o `data/`.

**Estudar no Artifact** (o link privado da trilha no claude.ai): o relógio grava no banco da própria
página, e só quando quem vê é o dono. Os minutos de lá entram na soma quando o Claude os lê e os
importa — peça "traga os minutos do Artifact".

**Terminal:** nada a fazer. Nos terminais abertos depois da instalação, cada comando digitado dentro
da pasta do projeto é registrado e, enquanto ele roda, um vigia anota a cada 20 s se houve tecla
naquele terminal — só o minuto, nunca a tecla. `ESTUDO_SEM_REGISTRO=1` desliga num terminal. Um
terminal aberto antes da chegada do vigia (13/10/2026) continua com o gancho antigo, que só
vê o Enter: feche e abra de novo, ou rode `source ~/.bashrc`.

**Fechar o dia:**

```bash
python3 CONVERSAS_COM_CHAT/estudo/study_clock.py archive
python3 CONVERSAS_COM_CHAT/estudo/study_clock.py import
python3 CONVERSAS_COM_CHAT/estudo/study_clock.py report
```

O `archive` guarda uma cópia das transcrições; o `import` extrai delas os minutos de atividade; o
`report` copia os registros para [`registros/`](registros/) e refaz [`auditoria.md`](auditoria.md) e
`resumo.json`. Depois, *commit* e *push*: é o que publica a auditoria.

## Onde os registros ficam, e por que sobrevivem

| O quê | Onde | Por quê |
|---|---|---|
| Registros vivos: página, terminal, Artifact e os minutos importados | `data/estudo/` | fora do Git, para o `git status` dos roteiros não mudar enquanto você estuda; fora dos contêineres, para sobreviver a reinício e a `make reset` dos bancos |
| Retrato publicado | [`registros/`](registros/), com a [`auditoria.md`](auditoria.md) | versionado e publicado no GitHub a cada fechamento |
| Fontes originais do Claude Code e do Codex | `~/Projetos/_arquivo/registros_mvp_eng_dados_1/`, com `manifesto.json` | cópia com o SHA-256 de cada arquivo. O Claude Code apagava transcrições com mais de 30 dias; desde 13/10/2026, `cleanupPeriodDays` em `~/.claude/settings.json` desliga essa limpeza |

## Método e limites

- **Presença e uso, não compreensão.** O relógio da página prova que a trilha estava na tela e em
  uso; não prova o que foi entendido. A prova de que algo foi feito são os roteiros executados, com a
  saída, e os exercícios.
- **Leitura parada pausa a contagem.** Mais de 5 min sem tocar na página, ou mais de 15 min sem
  evento numa sessão do Claude ou do Codex, ficam de fora.
- **O passado tem buracos conhecidos.** As transcrições do Claude Code anteriores a 14/09/2026 foram
  apagadas pela limpeza automática antes de este registro existir; o Codex cobre o projeto desde
  01/09/2026. O estudo na trilha e no terminal antes de 13/10/2026 não foi medido.
- **O terminal vê o histórico do bash e as teclas, não o que elas dizem.** Comandos começados por
  espaço e repetidos idênticos não entram no histórico (`HISTCONTROL=ignoreboth`). Dentro de um `psql`
  ou de um contêiner, conta o minuto com tecla nos últimos 5 min, pelo horário de acesso do
  dispositivo do terminal — o mesmo sinal que o `w` usa para a ociosidade, que o núcleo atualiza de 8
  em 8 s. Esperar um comando longo sem digitar pausa a contagem, como ler a página sem tocar nela.
  Até 13/10/2026 a regra era a duração do comando, com teto de 30 min; a regra nova vale para todos
  os registros.
- **Relógio da máquina.** Os horários vêm do relógio desta máquina (coletor, gancho e transcrições) e
  do navegador (Artifact).

## O que fica público

Minutos de relógio, o identificador da seção da trilha que estava na tela, o nome do programa de cada
comando (`make`, `git`, `docker`…) e o identificador das sessões do Claude e do Codex. Nenhum conteúdo de
conversa, nenhum comando inteiro, nenhum argumento: senhas digitadas num comando nunca chegam aqui.

## O certificado

Ao término, o certificado sai desta auditoria: carga horária por atividade e total, o período, as
seções estudadas, os hashes dos registros e um QR code para a auditoria numa *tag* do Git, que não
muda depois de emitida. O texto do atestado diz o que os registros mostram, e só isso.

## Desligar

```bash
python3 CONVERSAS_COM_CHAT/estudo/study_clock.py uninstall-hook
```

Tira o gancho do `~/.bashrc` (a cópia de antes da instalação está em `~/.bashrc.antes-do-relogio`).
O coletor só roda quando você o sobe. Para voltar à limpeza automática do Claude Code, apague a linha
`cleanupPeriodDays` de `~/.claude/settings.json`.
