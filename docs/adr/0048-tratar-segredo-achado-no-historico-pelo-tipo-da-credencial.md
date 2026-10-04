# ADR-0048 — Tratar segredo achado no histórico pelo tipo da credencial

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 03/10/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D48 — decidida em 18/09/2026, na abertura da Etapa 12; formalizada aqui em 03/10/2026, pela revisão final da etapa (RVF12-02) |
| Substitui / é substituída por | — |

## Contexto

A [Governança §9](../governanca_de_dados.md#9-tratamento-de-segredos) tinha duas regras sobre
segredos que já tinham saído do `.env`: nenhum é versionado, e o exposto por engano é considerado
comprometido — **rotacionado**, não apenas removido do histórico. Nenhuma dizia o que fazer com o
que já está no histórico, e até a Etapa 12 a pergunta não aparecia. A revisão de segredos do
`make check` compara os arquivos rastreados com os valores do `.env` **atual**, e depois de uma
rotação o valor antigo não é mais conhecido: medido na revisão do plano da etapa, uma senha
removida e rotacionada dá **zero** casamentos no *blob* antigo.

O critério da Etapa 12 — nenhum segredo no repositório **nem no histórico** — exigiu a varredura
histórica (B2, `make secrets-history`), que detecta por **forma** e não por valor. Uma varredura
dessas acha o que já foi tratado, e acha para sempre. A pergunta virou: o que se faz com um achado.

O Owner decidiu em 18/09/2026, ao abrir o plano da etapa, sobre duas opções propostas: senha de
contêiner local se regenera e se registra, sem reescrever o histórico; chave de nuvem ou *token*
externo se revoga **e** se reescreve, só pela mão dele. A decisão foi registrada nas
[Pendências](../pendencias.md) como D48 e, em 25/09/2026, escrita na §9 — **sem ADR**, sob a leitura
de que ela detalhava a rotação que a §9 já exigia.

A revisão final da etapa (03/10/2026, achado RVF12-02) leu diferente, e o Owner concordou: a D48
**acrescenta** política. Ela distingue credencial local de externa, torna o registro obrigatório
e, para a externa, exige **reescrever** o histórico — o que não se deduz de "rotacionar". A
[§10](../governanca_de_dados.md#10-revisão-desta-política) exige ADR para alteração na política.

A mesma revisão achou o primeiro caso real da política (RVF12-01). A composição do Airflow trouxe
de 04/09 a 20/09/2026 a senha de fábrica do banco de metadados, igual ao usuário, na URL de conexão
e no `POSTGRES_PASSWORD`. Ela foi achada por inspeção e rotacionada em `0b89b3d`, mas a varredura
não a via — palavra única sem dígito, a regra que excusa identificadores — e ela ficou fora do
registro. O detector passou a achar senha igual ao usuário em `8e60739`, e os quatro achados estão
registrados desde `41c39c5`.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Pelo tipo da credencial** (escolhida): a local se regenera e se registra, sem reescrever; a externa se revoga e se reescreve, pela mão do Owner | Cada tipo recebe a resposta que o seu valor admite: uma senha de PostgreSQL em `localhost`, já trocada, não dá acesso a nada; uma chave de nuvem dá acesso de qualquer lugar até ser revogada. O registro torna o veredito repetível — "nada **não tratado**" — e o histórico continua sendo prova de que o processo funcionou | O texto da senha local antiga continua no histórico público para sempre. A política depende de alguém classificar cada achado, e de a varredura achá-lo |
| Reescrever o histórico em todo achado (`git filter-repo` e *force push*) | O texto some do repositório | Reescrever não descompromete — a rotação continua obrigatória, porque o valor já pode ter sido copiado. Quebra todo clone, e depois do fechamento da fase local a *tag* `v1.0.0`. E apaga a prova de que o achado aconteceu e foi tratado |
| Só rotacionar, sem registro | Nenhum artefato novo | A varredura acusaria o mesmo achado a cada execução, e "nada encontrado" deixa de ser possível no primeiro achado. O leitor do histórico não sabe se o valor foi trocado — exatamente o contra que a própria opção escolhida declarava sem o registro |
| Registrar, sem rotacionar a credencial local | Nenhuma troca de senha | Contradiz a regra que já existia na §9: segredo exposto é comprometido. O registro passaria a ser uma lista de exceções, não de tratamentos |

## Decisão

Segredo achado no histórico é tratado pelo tipo da credencial: a senha de contêiner local se
regenera e se registra em [`segredos_tratados.yml`](../segredos_tratados.yml), com o tratamento e o
motivo, sem reescrever o histórico; a chave de nuvem ou o *token* externo se revoga **e** se
reescreve, só pela mão do Owner — e o veredito da varredura histórica é "nada **não tratado**",
nunca "nada encontrado".

## Consequências

- **Positivas:** o critério "nem no histórico" tem um veredito que se repete: `make secrets-history`
  sai 0 só quando todo achado tem tratamento registrado, e sai 1 com o achado novo listado, sem
  imprimir o valor. O registro é declarativo, revisado por inteiro (`CLAUDE.md` §5), e cada entrada
  cita o *commit*, o caminho e a chave. Os clones e a *tag* da fase local não quebram por credencial
  local. Em 03/10/2026: 11 achados, todos registrados — 7 *fixtures* de teste e os 4 da senha de
  fábrica do Airflow.
- **Negativas:** a senha antiga de cada credencial local fica legível no histórico público. Para a
  senha de fábrica do Airflow isso não dá acesso a nada: o banco atual nasceu em 25/09/2026 com
  outra senha. Mas quem lê precisa ir ao registro para saber disso. O registro cresce por *blob*, não
  por credencial: a mesma senha em duas versões da composição são quatro entradas. E a política só
  alcança o que a varredura acha. Os limites declarados no detector — senha só com letras e
  diferente do usuário; valor sem aspa que comece como chamada de função — passam calados, e foi
  assim que a senha de fábrica do Airflow ficou fora do registro até a revisão final. Reescrever
  por chave externa, se um dia acontecer, quebra clones e qualquer *tag* publicada depois do
  vazamento — custo aceito, porque é a única resposta que o valor dessa chave admite.
- **Paridade com o GCP:** na fase GCP os segredos vivem no Secret Manager
  ([Arquitetura §5](../arquitetura.md#5-mapa-de-paridade-local--gcp)), e o critério da decisão — o que o valor dá de acesso, e de
  onde — põe toda credencial de lá no segundo tipo: nada fica confinado à estação. Chave de conta de
  serviço, *token* de API ou senha do Cloud SQL vazados são **revogados** — a chave no IAM, a senha
  no próprio Cloud SQL — e o histórico é reescrito pelo Owner. A varredura é a mesma, porque o
  repositório é o mesmo.
- **Documentos a atualizar:** [Governança §9](../governanca_de_dados.md#9-tratamento-de-segredos) —
  a política cita este ADR, e a detecção por forma inclui a senha igual ao usuário;
  [`segredos_tratados.yml`](../segredos_tratados.yml) — o cabeçalho cita este ADR como dono da
  política; [Riscos](../riscos.md), R7; [Plano](../plano_de_desenvolvimento.md), critério 6 da
  Etapa 12; [Pendências](../pendencias.md) — a D48 aponta para este ADR, e a decisão embutida no
  aceite da Etapa 12 está resolvida; [Registro de Decisões](README.md) e [README](../../README.md).
