# Créditos de prueba en el Playground

Aprende cómo funcionan los créditos cuando pruebas tu agente en el Playground.

## Qué cambió

Cada respuesta de IA que tu agente genera mientras lo pruebas en el Playground ahora descuenta créditos de tu cuenta. Las pruebas se facturan de la misma forma que el uso en producción, porque cada respuesta de prueba ejecuta el mismo modelo de IA que usaría una conversación real con un cliente. El costo depende del **AI Model** seleccionado para tu agente — los niveles más altos son más capaces y cuestan más por respuesta.

## Dónde ver el costo y tu saldo

Cuando abres la pestaña **Playground**, aparece una barra de facturación en la parte superior de la ventana del chat. Muestra dos cosas:

- **Costo por respuesta** — el monto que se descuenta cada vez que el agente envía una respuesta (por ejemplo, $0.04 en el nivel Very High).
- **Saldo restante** — el saldo actual de tu billetera en tu moneda local (por ejemplo, ₹1,838.42 restantes).

La captura de pantalla a continuación muestra dónde aparecen estos datos. Busca la línea justo debajo del nombre y estado del agente.

## Costo por respuesta

| Nivel del modelo | Costo por respuesta |
| --- | --- |
| Low | $0.01 |
| Medium | $0.02 |
| High | $0.03 |
| Very High | $0.04 |
| Premium | $0.05 |
| Ultra | $0.06 |

El nivel **Ultra** está pensado solo para los casos más difíciles. Es más lento y considerablemente más caro, así que úsalo solo cuando los niveles inferiores no sean suficientes.

Puedes elegir el nivel del modelo en la pestaña **Billing** de tu agente, en el menú desplegable **AI Model**. El precio por respuesta se muestra junto a cada nivel.

## Consejos para mantener bajos los costos de prueba

- **Elige el nivel adecuado antes de empezar.** Usa un nivel bajo (Low o Medium) para verificaciones rutinarias como saludos y respuestas predefinidas. Cambia a un nivel más alto solo cuando necesites probar la calidad de las respuestas.
- **Planifica tus casos de prueba con anticipación.** Mantén cada chat enfocado y breve en lugar de repetir la misma conversación muchas veces.
- **Revisa el Monthly Breakdown** en la pestaña Billing después de una ronda de pruebas para ver cuánto costó.

## Preguntas frecuentes

**¿Hay una tarifa fija por cada chat de prueba?**
No. Los cargos se basan en el trabajo de IA realizado. Pagas por cada respuesta de IA, no por conversación.

**¿Cómo se cobran los agentes de tipo workflow?**
Los agentes de tipo workflow se cobran por paso de IA (nodo), no por respuesta. Un flujo estándar de clasificar-y-responder ejecuta dos pasos de IA por cada mensaje del cliente, por lo que se factura dos veces por mensaje.

**Si el agente envía múltiples mensajes de WhatsApp en una sola respuesta, ¿se cobra una o varias veces?**
Varios mensajes de WhatsApp generados en un solo paso de IA cuentan como un solo cargo. Varios pasos de IA en el mismo turno se cobran por separado.

**¿Se me cobra por respuestas fallidas o vacías?**
Una falla del proveedor sin tokens utilizados no se cobra. Una respuesta vacía después de que se usaron tokens sí se cobra, y una falla en la entrega después de que el modelo ya se ejecutó también puede cobrarse.

**¿En qué moneda son los cargos?**
Los precios de los niveles están en USD. Si tu billetera está en INR, los montos se convierten a la tasa configurada (actualmente 93.0 INR por USD). Así, una respuesta de $0.04 equivale a aproximadamente ₹3.72.

**¿Qué pasa si mi saldo se agota durante una conversación en vivo por WhatsApp?**
El agente deja de funcionar. El mensaje entrante se conserva, pero no se envía ninguna respuesta automática. Recarga tu saldo para reanudar.

**¿Las conversaciones en vivo por WhatsApp se cobran de la misma manera?**
Sí. Las conversaciones en vivo usan los mismos precios por nivel y el mismo conteo por paso que el Playground.
