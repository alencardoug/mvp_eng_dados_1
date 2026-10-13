# Auditoria das horas de estudo — trilha da fase local

> Gerada por `study_clock.py report` em 13/10/2026 02:31 (horário de Brasília).
> Reproduzível: os registros estão em [`registros/`](registros/), e o mesmo comando refaz esta página
> a partir deles. O método e os limites estão no [README](README.md).

## Resumo

| Atividade | Horas | De onde vem | Regra |
|---|---|---|---|
| Construção com o Claude Code | 47h27 | transcrições do Claude Code | eventos a até 15 min formam um bloco |
| ↳ o Claude trabalhando, você acompanhando | 38h12 | as mesmas | do evento ao seguinte, quando o seguinte não é um pedido seu |
| ↳ você entre turnos: lendo, decidindo, escrevendo | 9h15 | as mesmas | do último evento até o seu pedido seguinte |
| Construção e revisão com o Codex | 16h14 | sessões do Codex na pasta do projeto | eventos a até 15 min formam um bloco |
| Estudo na trilha | 0h00 | relógio da página, local e no Artifact | minuto com a aba visível e uso nos últimos 5 min |
| Execução no terminal | 0h00 | gancho do bash, só na pasta do projeto | duração do comando, até 30 min, mais até 5 min entre comandos |
| **Total, sem contar o mesmo minuto duas vezes** | **61h30** | a união dos minutos acima | |

## Por dia

| Dia | Claude Code | Codex | Trilha | Terminal | Total |
|---|---|---|---|---|---|
| 01/09/2026 | 0h00 | 0h49 | 0h00 | 0h00 | **0h49** |
| 05/09/2026 | 0h00 | 2h34 | 0h00 | 0h00 | **2h34** |
| 06/09/2026 | 0h00 | 0h54 | 0h00 | 0h00 | **0h54** |
| 07/09/2026 | 0h00 | 0h53 | 0h00 | 0h00 | **0h53** |
| 08/09/2026 | 0h00 | 0h49 | 0h00 | 0h00 | **0h49** |
| 14/09/2026 | 2h55 | 1h22 | 0h00 | 0h00 | **4h15** |
| 15/09/2026 | 6h07 | 0h47 | 0h00 | 0h00 | **6h33** |
| 16/09/2026 | 1h23 | 0h31 | 0h00 | 0h00 | **1h44** |
| 17/09/2026 | 4h11 | 0h51 | 0h00 | 0h00 | **4h28** |
| 18/09/2026 | 4h26 | 1h11 | 0h00 | 0h00 | **5h37** |
| 19/09/2026 | 0h30 | 0h27 | 0h00 | 0h00 | **0h56** |
| 20/09/2026 | 3h25 | 0h50 | 0h00 | 0h00 | **4h00** |
| 21/09/2026 | 1h06 | 0h34 | 0h00 | 0h00 | **1h40** |
| 23/09/2026 | 2h51 | 0h20 | 0h00 | 0h00 | **3h11** |
| 24/09/2026 | 4h07 | 0h21 | 0h00 | 0h00 | **4h21** |
| 25/09/2026 | 4h49 | 0h33 | 0h00 | 0h00 | **5h07** |
| 03/10/2026 | 1h55 | 1h07 | 0h00 | 0h00 | **2h51** |
| 04/10/2026 | 4h19 | 0h26 | 0h00 | 0h00 | **4h30** |
| 12/10/2026 | 4h37 | 0h55 | 0h00 | 0h00 | **5h32** |
| 13/10/2026 | 0h46 | 0h00 | 0h00 | 0h00 | **0h46** |

## O que foi estudado na trilha

Nenhum minuto de estudo na trilha registrado ainda: o relógio da página começou em 13/10/2026.

## Registros e integridade

| Arquivo | Linhas | SHA-256 |
|---|---|---|
| [`registros/claude_code.jsonl`](registros/claude_code.jsonl) | 1976 | `dd74a0f2b85eefaad084e5eaf1522860c3c894ee2949d8a6f75d1da1c1cc4741` |
| [`registros/codex.jsonl`](registros/codex.jsonl) | 711 | `2082f5ba70b375079680bd97781ddd9e10b01a6c2f1d9918db54aebe3c425d8a` |
| [`registros/pagina.jsonl`](registros/pagina.jsonl) | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| [`registros/artifact.jsonl`](registros/artifact.jsonl) | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| [`registros/terminal.jsonl`](registros/terminal.jsonl) | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

Fontes originais do Claude Code e do Codex: 40 arquivos guardados fora do Git, com o hash de cada um num manifesto (SHA-256 do manifesto: `42f4d251ba9579f5362a350406d53f1a9feaded9eac2cf76d2996074b0ece837`).

## Método e limites

- Cada fonte conta minutos de relógio. O total é a **união**: um minuto em que o Claude trabalhava e você lia a trilha conta uma vez.
- Claude Code e Codex: o minuto de cada evento das transcrições, e o intervalo entre eventos a até 15 min. Pausas maiores ficam de fora — inclusive leitura longa sem nenhuma interação.
- As transcrições do Claude Code anteriores a 14/09/2026 foram apagadas pela limpeza automática de 30 dias antes de este registro existir; o Codex cobre o projeto desde 01/09/2026.
- Trilha: o relógio da página grava um minuto quando a aba está visível e houve rolagem, clique ou tecla nos últimos 5 min. Ler sem tocar em nada por mais tempo pausa a contagem. Mede presença e uso, não compreensão.
- Terminal: só comandos digitados dentro da pasta do projeto; grava início, fim e o nome do programa, nunca o comando inteiro. Comandos repetidos idênticos ou começados por espaço não entram no histórico do bash e não são vistos.
- O estudo na trilha e no terminal antes de 13/10/2026 não foi medido.
