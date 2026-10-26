# Créditos de teste no Playground

Saiba como os créditos funcionam quando você testa seu agente no Playground.

## O que mudou

Cada resposta de IA que seu agente gera enquanto você testa no Playground agora deduz créditos da sua conta. Os testes são cobrados da mesma forma que o uso real, porque cada resposta de teste executa o mesmo modelo de IA que uma conversa real com um cliente usaria. O custo depende do **AI Model** selecionado para o seu agente — níveis mais altos são mais capazes e custam mais por resposta.

## Onde ver o custo e o seu saldo

Quando você abre a aba **Playground**, uma barra de cobrança aparece no topo da janela do chat. Ela mostra duas informações:

- **Custo por resposta** — o valor descontado cada vez que o agente envia uma resposta (ex.: $0.04 no nível Very High).
- **Saldo restante** — o saldo atual da sua carteira na sua moeda local (ex.: ₹1.838,42 restantes).

A captura de tela abaixo mostra onde essas informações aparecem. Procure a linha logo abaixo do nome e status do agente.

## Custo por resposta

| Nível do modelo | Custo por resposta |
| --- | --- |
| Low | $0.01 |
| Medium | $0.02 |
| High | $0.03 |
| Very High | $0.04 |
| Premium | $0.05 |
| Ultra | $0.06 |

O nível **Ultra** é destinado apenas para os casos mais difíceis. Ele é mais lento e consideravelmente mais caro, então use-o somente quando os níveis inferiores não forem suficientes.

Você pode escolher o nível do modelo na aba **Billing** do seu agente, no menu suspenso **AI Model**. O preço por resposta é exibido ao lado de cada nível.

## Dicas para manter os custos de teste baixos

- **Escolha o nível certo antes de começar.** Use um nível mais baixo (Low ou Medium) para verificações de rotina, como saudações e respostas padrão. Mude para um nível mais alto somente quando precisar testar a qualidade das respostas.
- **Planeje seus casos de teste com antecedência.** Mantenha cada chat focado e curto, em vez de repetir a mesma conversa várias vezes.
- **Confira o Monthly Breakdown** na aba Billing após uma rodada de testes para ver quanto custou.

## Perguntas frequentes

**Existe uma taxa fixa por chat de teste?**
Não. As cobranças seguem o trabalho de IA realizado. Você paga por resposta de IA, não por conversa.

**Como os agentes de workflow são cobrados?**
Agentes de workflow são cobrados por etapa de IA (nó), não por resposta. Um fluxo padrão de classificar-e-responder executa duas etapas de IA para cada mensagem do cliente, então é cobrado duas vezes por mensagem.

**Se o agente enviar múltiplas mensagens de WhatsApp em uma única resposta, isso é cobrado uma ou várias vezes?**
Várias mensagens de WhatsApp geradas em uma única etapa de IA contam como uma única cobrança. Várias etapas de IA no mesmo turno são cobradas separadamente.

**Sou cobrado por respostas com falha ou vazias?**
Uma falha do provedor sem tokens utilizados não é cobrada. Uma resposta vazia após tokens terem sido usados é cobrada, e uma falha na entrega após o modelo já ter sido executado também pode ser cobrada.

**Em qual moeda são as cobranças?**
Os preços dos níveis são em USD. Se sua carteira estiver em INR, os valores são convertidos pela taxa configurada (atualmente 93,0 INR por USD). Então, uma resposta de $0.04 custa aproximadamente ₹3,72.

**O que acontece se meu saldo acabar durante uma conversa ao vivo no WhatsApp?**
O agente para de funcionar. A mensagem recebida é mantida, mas nenhuma resposta automática é enviada. Recarregue seu saldo para retomar.

**As conversas ao vivo no WhatsApp são cobradas da mesma forma?**
Sim. As conversas ao vivo usam os mesmos preços por nível e a mesma contagem por etapa que o Playground.
