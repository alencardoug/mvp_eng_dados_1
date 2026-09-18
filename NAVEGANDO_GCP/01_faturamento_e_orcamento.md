# 01 — Faturamento e orçamento: o taxímetro

**Em uma frase.** *Billing* é a conta bancária do projeto: mostra o que cada serviço custou, por
dia e por SKU, e avisa quando passa de um teto. Na fase local não existe equivalente — é a
novidade que muda o comportamento de todo o resto.

**Quanto custa e por quê.** Nada: olhar é grátis. Mas é aqui que se lê o que os outros cobraram, e
a fatura **atrasa 24–48 h** — o que você vê de manhã é ontem. A ordem de grandeza da janela está na
[conversa §7–§8](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md): estimativa, não medição.

**Onde fica.** Menu ☰ → *Billing* (ou `/` e "Billing"). URL `console.cloud.google.com/billing`.
Uma conta de faturamento pode servir vários projetos; confira que o seletor mostra **a conta do
projeto certo**. Páginas que importam: *Overview*, *Reports*, *Cost table*, *Budgets & alerts*,
*Credits*.

**O que é deste projeto aqui.** O crédito de conta nova (US$ 300 / 90 dias, se aplicável — confira
em *Credits*: valor restante e **data de expiração**), os dois alertas de orçamento combinados
(US$ 100 e US$ 150) e, a partir de terça, as linhas de custo de Composer, GKE, Cloud SQL, Dataflow.

## Roteiro guiado

1. **Overview.** Olhe *Current month's total* e o gráfico por serviço. *O que olhar:* qual serviço
   lidera. *Por quê:* se não for Composer/GKE/Cloud SQL, algo ficou ligado que não devia.
2. **Credits.** Saldo restante e validade. *Por quê:* a janela cabe no crédito só se ele ainda
   existe; crédito expirado vira cartão.
3. **Reports.** Filtre por *Project* = o seu; *Group by* = *Service*; período = últimos 7 dias.
   Depois *Group by* = *SKU* para ver o que dentro do Composer cobra (ambiente, *workers*, banco,
   *web server*). Depois filtre por **label** (`etapa=13`, se o Terraform etiquetou). *Por quê:*
   é a consulta que responde "custo real da janela" na semana seguinte — salve a URL: os
   filtros ficam na URL.
4. **Cost table.** A mesma coisa em tabela, exportável em CSV. *Por quê:* é o arquivo que entra
   no registro de custo real (critério da Etapa 13).
5. **Budgets & alerts.** Abra os dois alertas. *O que olhar:* escopo (projeto), valor, limiares
   (50/90/100 %), e-mails. Se não existirem, **crie agora**: *Create budget* → escopo do projeto →
   valor → limiares → notificação por e-mail. *Por quê:* é a única defesa que não depende de você
   lembrar de olhar.
6. **Billing export** (*Billing → Billing export*). Se estiver configurado para o BigQuery, o custo
   vira uma tabela consultável (`billing_export.gcp_billing_export_v1_…`): custo por
   `service.description`, por `labels.value`, por hora. *Por quê:* é a forma mais fiel de ler o
   custo da janela — e é BigQuery, que você já sabe consultar (cap. 04). Se não estiver, anote:
   configurar antes da próxima janela, porque o *export* só começa a partir de quando é ligado.

## Onde aciona, onde registra, o que controla

- **Aciona:** nada — é passivo. O que "aciona" custo é todo o resto.
- **Registra:** *Reports*/*Cost table* (agregado) e o *export* no BigQuery (linha a linha, por SKU
  e hora).
- **Controla:** orçamentos e alertas; *labels* como eixo de leitura; e a ligação conta ↔ projeto
  (desligar a conta de faturamento de um projeto **para** tudo que cobra — é o botão de pânico,
  destrutivo).

## Armadilhas

- A fatura de hoje é a de ontem. Custo real da janela se lê na **semana seguinte**.
- Recurso em outra região ou em outro projeto não aparece no filtro, mas cobra.
- Alerta de orçamento **avisa**; não desliga nada.
- Rede: tráfego de saída entre regiões e para a internet cobra por GB — Cloud SQL numa região e
  BigQuery/Composer em outra é o erro clássico. Confira no cap. 03 e 06 que estão na mesma.

## Evidência a levar

- Captura de *Reports* por serviço, com a URL dos filtros.
- CSV do *Cost table* da janela (na semana seguinte, o definitivo).
- Captura dos dois orçamentos com os limiares.
- Se houver *export*: a consulta SQL que dá o custo por serviço por dia.

## O que você saberá dizer depois

- "O custo da janela foi X, dominado por Composer (Y) e GKE (Z); li no *export* de *billing* por
  SKU, não no gráfico."
- "Configurei alertas de orçamento em dois limiares antes do primeiro `apply`."
- "A fatura atrasa até 48 h, então o custo real entrou no registro só na semana seguinte."
