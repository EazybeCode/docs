#!/usr/bin/env ruby

require "fileutils"
require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
SOURCE = File.join(ROOT, "api-reference/meta/openapi.yaml")
HTTP_METHODS = %w[get post put patch delete options head trace].freeze

LOCALES = {
  "es" => {
    title: "API Wrapper de Meta de Eazybe",
    description: "Una superficie REST autenticada de Eazybe para la API de WhatsApp Business Cloud.",
    server: "Sustituye este marcador por el host de la API de Eazybe asignado a tu entorno.",
    operation: ->(summary) { "#{summary}. Consulta los parámetros, el ejemplo y las respuestas disponibles para esta operación." },
    success: "La operación se completó correctamente.",
    failure_responses: [
      "**Respuestas de error**",
      "",
      "| **Estado** | **Significado** | **Acción** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, no válido o caducado | Vuelve a autenticarte |",
      "| `404` | El `phoneNumberId` o `wabaId` no está conectado a tu organización, o la conexión necesita una nueva autorización | Ejecuta de nuevo `GET /meta/phone-numbers`; vuelve a conectar la WABA si devuelve `status: false` |",
      "| `400`, `429` u otro | WhatsApp rechazó la solicitud por una plantilla no válida, una ventana de 24 horas cerrada, un límite de uso u otro motivo. Se devuelve el error original de Meta | Consulta `error.message` y `error.code` |",
      "| `502` | WhatsApp no está disponible o agotó el tiempo de espera | Reintenta con espera exponencial |"
    ].join("\n"),
    get_phone_numbers_failure_responses: [
      "**Respuestas de error**",
      "",
      "| **Estado** | **Significado** | **Acción** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, no válido o caducado | Vuelve a autenticarte y obtén un token nuevo |",
      "| `400`, `429` u otro | Meta rechazó la solicitud: se superó el límite, el ID de WABA no es válido o existe un problema de permisos. Se devuelve el error original de Meta | Consulta `error.message` y `error.code`; aplica espera progresiva si es `429` |",
      "| `502` | No se puede acceder a WhatsApp/Meta Graph API o se agotó el tiempo de espera | Reintenta con espera exponencial |"
    ].join("\n"),
    get_phone_number_details_failure_responses: [
      "**Respuestas de error**",
      "",
      "| **Estado** | **Significado** | **Acción** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, no válido o caducado | Vuelve a autenticarte y obtén un token nuevo |",
      "| `404` | El `phoneNumberId` no está conectado a tu organización, o la conexión de la WABA necesita una nueva autorización | Ejecuta `GET /meta/phone-numbers` para verificar los ID válidos; vuelve a conectar la WABA si devuelve `is_waba_connected: false` |",
      "| `400`, `429` u otro | Meta rechazó la solicitud: formato de ID de teléfono no válido, permisos insuficientes o límite alcanzado. Se devuelve el error original de Meta | Consulta `error.message` y `error.code`; aplica espera progresiva si es `429` |",
      "| `502` | No se puede acceder a Meta Graph API o se agotó el tiempo de espera | Reintenta con espera exponencial |"
    ].join("\n"),
    get_waba_details_failure_responses: [
      "**Respuestas de error**",
      "",
      "| **Estado** | **Significado** | **Acción** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, no válido o caducado | Vuelve a autenticarte y obtén un token nuevo |",
      "| `404` | El `wabaId` no está conectado a tu organización, o la conexión de la WABA necesita una nueva autorización | Ejecuta `GET /meta/phone-numbers` para listar las WABA conectadas; vuelve a conectar mediante el registro integrado si es necesario |",
      "| `400`, `429` u otro | Meta rechazó la solicitud: formato de ID de WABA no válido, permisos insuficientes o límite alcanzado. Se devuelve el error original de Meta | Consulta `error.message` y `error.code`; aplica espera progresiva si es `429` |",
      "| `502` | No se puede acceder a Meta Graph API o se agotó el tiempo de espera | Reintenta con espera exponencial |"
    ].join("\n"),
    send_marketing_template_failure_responses: [
      "**Respuestas de error**",
      "",
      "| **Estado** | **Significado** | **Acción** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, no válido o caducado | Vuelve a autenticarte y obtén un token nuevo |",
      "| `404` | El `phoneNumberId` no está conectado a tu organización, o la conexión de la WABA necesita una nueva autorización | Ejecuta `GET /meta/phone-numbers` para verificar los ID válidos; vuelve a conectar la WABA si devuelve `is_waba_connected: false` |",
      "| `400`, `429` u otro | WhatsApp rechazó la solicitud: nombre de plantilla no válido, plantilla no aprobada, ventana de 24 horas cerrada, límite de uso o componentes mal formados. Se devuelve el error original de Meta | Consulta `error.message` y `error.code`; aplica espera progresiva si es `429` |",
      "| `502` | No se puede acceder a Meta Graph API o se agotó el tiempo de espera | Reintenta con espera exponencial |"
    ].join("\n"),
    tags: {
      "Phone numbers" => ["Números de teléfono", "Descubre las WABA y los identificadores de números de teléfono conectados."],
      "Messaging" => ["Mensajería", "Envía mensajes de WhatsApp y actualiza su estado."],
      "Templates" => ["Plantillas", "Administra las plantillas de mensajes de WhatsApp."],
      "Media" => ["Archivos multimedia", "Sube, consulta y elimina archivos multimedia de WhatsApp."],
      "Webhooks" => ["Webhooks", "Administra las suscripciones de webhooks de una WABA."],
      "Analytics" => ["Analíticas", "Consulta analíticas de mensajería, conversaciones, precios y plantillas."],
      "Profiles and settings" => ["Perfiles y configuración", "Administra perfiles empresariales y ajustes de números de teléfono."],
      "Automation" => ["Automatización", "Configura mensajes de bienvenida, preguntas iniciales y comandos."],
      "QR codes" => ["Códigos QR", "Administra códigos QR de clic para chatear."],
      "Flows" => ["Flows", "Administra el ciclo de vida de WhatsApp Flows."],
      "Number administration" => ["Administración de números", "Registra números, administra PIN y sincroniza datos de coexistencia."],
      "Block list" => ["Lista de bloqueados", "Consulta, bloquea y desbloquea usuarios de WhatsApp."]
    },
    summaries: {
      "getPhoneNumbers" => "Listar números de teléfono conectados",
      "getPhoneNumberDetails" => "Obtener detalles del número de teléfono",
      "getWabaDetails" => "Obtener detalles de la WABA",
      "sendMessage" => "Enviar cualquier tipo de mensaje compatible",
      "sendTemplateMessage" => "Enviar un mensaje de plantilla",
      "sendMarketingTemplateMessage" => "Enviar una plantilla de marketing",
      "sendBulkTemplateMessages" => "Enviar una plantilla de forma masiva",
      "sendFreeFormMessage" => "Enviar un mensaje de texto libre",
      "markMessageRead" => "Marcar un mensaje como leído",
      "reactToMessage" => "Reaccionar a un mensaje",
      "sendContactCard" => "Enviar tarjetas de contacto",
      "showTypingIndicator" => "Mostrar un indicador de escritura",
      "listTemplates" => "Listar plantillas",
      "createTemplate" => "Crear una plantilla",
      "listAllTemplates" => "Listar todas las plantillas",
      "createTemplateFromLibrary" => "Crear una plantilla desde la biblioteca de Meta",
      "migrateTemplates" => "Migrar plantillas desde otra WABA",
      "compareTemplates" => "Comparar el rendimiento de plantillas",
      "editTemplate" => "Editar una plantilla",
      "deleteTemplate" => "Eliminar una plantilla",
      "uploadMedia" => "Subir un archivo multimedia",
      "getMedia" => "Obtener metadatos de un archivo multimedia",
      "deleteMedia" => "Eliminar un archivo multimedia",
      "listWebhookSubscriptions" => "Listar suscripciones de webhooks",
      "createWebhookSubscription" => "Suscribir una WABA a webhooks",
      "deleteWebhookSubscription" => "Cancelar la suscripción de una WABA a webhooks",
      "getMessagingAnalytics" => "Obtener analíticas de mensajería",
      "getTemplateAnalytics" => "Obtener analíticas de plantillas",
      "getConversationAnalytics" => "Obtener analíticas de conversaciones",
      "getPricingAnalytics" => "Obtener analíticas de precios",
      "getBusinessProfile" => "Obtener el perfil empresarial",
      "updateBusinessProfile" => "Actualizar el perfil empresarial",
      "getPhoneNumberSettings" => "Obtener la configuración del número de teléfono",
      "updatePhoneNumberSettings" => "Actualizar la configuración del número de teléfono",
      "getConversationalAutomation" => "Obtener la automatización conversacional",
      "updateConversationalAutomation" => "Actualizar la automatización conversacional",
      "listQrCodes" => "Listar códigos QR",
      "createQrCode" => "Crear un código QR",
      "updateQrCode" => "Actualizar un código QR",
      "deleteQrCode" => "Eliminar un código QR",
      "listFlows" => "Listar Flows",
      "createFlow" => "Crear un Flow",
      "getFlow" => "Obtener un Flow",
      "updateFlow" => "Actualizar un Flow",
      "deleteFlow" => "Eliminar un Flow",
      "uploadFlowAsset" => "Subir un archivo JSON de Flow",
      "publishFlow" => "Publicar un Flow",
      "deprecateFlow" => "Retirar un Flow",
      "requestVerificationCode" => "Solicitar un código de verificación",
      "verifyPhoneNumberCode" => "Verificar el código de un número de teléfono",
      "registerPhoneNumber" => "Registrar un número de teléfono",
      "deregisterPhoneNumber" => "Dar de baja un número de teléfono",
      "setTwoStepVerification" => "Configurar la verificación en dos pasos",
      "removeTwoStepVerification" => "Eliminar la verificación en dos pasos",
      "syncCoexistenceContacts" => "Sincronizar contactos de coexistencia",
      "syncCoexistenceHistory" => "Sincronizar el historial de coexistencia",
      "listBlockedUsers" => "Listar usuarios bloqueados",
      "blockUsers" => "Bloquear usuarios",
      "unblockUsers" => "Desbloquear usuarios"
    }
  },
  "pt" => {
    title: "Wrapper da API Meta da Eazybe",
    description: "Uma superfície REST autenticada da Eazybe para a API do WhatsApp Business Cloud.",
    server: "Substitua este marcador pelo host da API da Eazybe atribuído ao seu ambiente.",
    operation: ->(summary) { "#{summary}. Consulte os parâmetros, o exemplo e as respostas disponíveis para esta operação." },
    success: "A operação foi concluída com sucesso.",
    failure_responses: [
      "**Respostas de erro**",
      "",
      "| **Status** | **Significado** | **Ação** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, inválido ou expirado | Autentique-se novamente |",
      "| `404` | O `phoneNumberId` ou `wabaId` não está conectado à sua organização, ou a conexão precisa de nova autorização | Execute `GET /meta/phone-numbers` novamente; reconecte a WABA se retornar `status: false` |",
      "| `400`, `429` ou outro | O WhatsApp rejeitou a solicitação por modelo inválido, janela de 24 horas encerrada, limite de uso ou outro motivo. O erro original da Meta é repassado | Consulte `error.message` e `error.code` |",
      "| `502` | O WhatsApp está indisponível ou excedeu o tempo limite | Tente novamente com espera exponencial |"
    ].join("\n"),
    get_phone_numbers_failure_responses: [
      "**Respostas de erro**",
      "",
      "| **Status** | **Significado** | **Ação** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, inválido ou expirado | Autentique-se novamente e obtenha um novo token |",
      "| `400`, `429` ou outro | A Meta rejeitou a solicitação: limite excedido, ID da WABA inválido ou problema de permissão. O erro original da Meta é repassado | Consulte `error.message` e `error.code`; aplique espera progressiva em caso de `429` |",
      "| `502` | Não foi possível acessar a API Graph do WhatsApp/Meta ou o tempo limite foi excedido | Tente novamente com espera exponencial |"
    ].join("\n"),
    get_phone_number_details_failure_responses: [
      "**Respostas de erro**",
      "",
      "| **Status** | **Significado** | **Ação** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, inválido ou expirado | Autentique-se novamente e obtenha um novo token |",
      "| `404` | O `phoneNumberId` não está conectado à sua organização, ou a conexão da WABA precisa de nova autorização | Execute `GET /meta/phone-numbers` para verificar IDs válidos; reconecte a WABA se retornar `is_waba_connected: false` |",
      "| `400`, `429` ou outro | A Meta rejeitou a solicitação: formato de ID de telefone inválido, permissões insuficientes ou limite atingido. O erro original da Meta é repassado | Consulte `error.message` e `error.code`; aplique espera progressiva em caso de `429` |",
      "| `502` | Não foi possível acessar a API Graph da Meta ou o tempo limite foi excedido | Tente novamente com espera exponencial |"
    ].join("\n"),
    get_waba_details_failure_responses: [
      "**Respostas de erro**",
      "",
      "| **Status** | **Significado** | **Ação** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, inválido ou expirado | Autentique-se novamente e obtenha um novo token |",
      "| `404` | O `wabaId` não está conectado à sua organização, ou a conexão da WABA precisa de nova autorização | Execute `GET /meta/phone-numbers` para listar as WABAs conectadas; reconecte por meio do cadastro incorporado se necessário |",
      "| `400`, `429` ou outro | A Meta rejeitou a solicitação: formato de ID da WABA inválido, permissões insuficientes ou limite atingido. O erro original da Meta é repassado | Consulte `error.message` e `error.code`; aplique espera progressiva em caso de `429` |",
      "| `502` | Não foi possível acessar a API Graph da Meta ou o tempo limite foi excedido | Tente novamente com espera exponencial |"
    ].join("\n"),
    send_marketing_template_failure_responses: [
      "**Respostas de erro**",
      "",
      "| **Status** | **Significado** | **Ação** |",
      "| --- | --- | --- |",
      "| `401` | Token bearer ausente, inválido ou expirado | Autentique-se novamente e obtenha um novo token |",
      "| `404` | O `phoneNumberId` não está conectado à sua organização, ou a conexão da WABA precisa de nova autorização | Execute `GET /meta/phone-numbers` para verificar IDs válidos; reconecte a WABA se retornar `is_waba_connected: false` |",
      "| `400`, `429` ou outro | O WhatsApp rejeitou a solicitação: nome de modelo inválido, modelo não aprovado, janela de 24 horas encerrada, limite de uso ou componentes malformados. O erro original da Meta é repassado | Consulte `error.message` e `error.code`; aplique espera progressiva em caso de `429` |",
      "| `502` | Não foi possível acessar a API Graph da Meta ou o tempo limite foi excedido | Tente novamente com espera exponencial |"
    ].join("\n"),
    tags: {
      "Phone numbers" => ["Números de telefone", "Descubra WABAs e IDs de números de telefone conectados."],
      "Messaging" => ["Mensagens", "Envie mensagens do WhatsApp e atualize o estado delas."],
      "Templates" => ["Modelos", "Gerencie modelos de mensagens do WhatsApp."],
      "Media" => ["Mídia", "Envie, consulte e exclua arquivos de mídia do WhatsApp."],
      "Webhooks" => ["Webhooks", "Gerencie assinaturas de webhook de uma WABA."],
      "Analytics" => ["Análises", "Consulte análises de mensagens, conversas, preços e modelos."],
      "Profiles and settings" => ["Perfis e configurações", "Gerencie perfis comerciais e configurações de números de telefone."],
      "Automation" => ["Automação", "Configure mensagens de boas-vindas, perguntas iniciais e comandos."],
      "QR codes" => ["Códigos QR", "Gerencie códigos QR de clique para conversar."],
      "Flows" => ["Flows", "Gerencie o ciclo de vida do WhatsApp Flows."],
      "Number administration" => ["Administração de números", "Registre números, gerencie PINs e sincronize dados de coexistência."],
      "Block list" => ["Lista de bloqueados", "Liste, bloqueie e desbloqueie usuários do WhatsApp."]
    },
    summaries: {
      "getPhoneNumbers" => "Listar números de telefone conectados",
      "getPhoneNumberDetails" => "Obter detalhes do número de telefone",
      "getWabaDetails" => "Obter detalhes da WABA",
      "sendMessage" => "Enviar qualquer tipo de mensagem compatível",
      "sendTemplateMessage" => "Enviar uma mensagem de modelo",
      "sendMarketingTemplateMessage" => "Enviar um modelo de marketing",
      "sendBulkTemplateMessages" => "Enviar um modelo em massa",
      "sendFreeFormMessage" => "Enviar uma mensagem de texto livre",
      "markMessageRead" => "Marcar uma mensagem como lida",
      "reactToMessage" => "Reagir a uma mensagem",
      "sendContactCard" => "Enviar cartões de contato",
      "showTypingIndicator" => "Mostrar um indicador de digitação",
      "listTemplates" => "Listar modelos",
      "createTemplate" => "Criar um modelo",
      "listAllTemplates" => "Listar todos os modelos",
      "createTemplateFromLibrary" => "Criar um modelo da biblioteca da Meta",
      "migrateTemplates" => "Migrar modelos de outra WABA",
      "compareTemplates" => "Comparar o desempenho de modelos",
      "editTemplate" => "Editar um modelo",
      "deleteTemplate" => "Excluir um modelo",
      "uploadMedia" => "Enviar um arquivo de mídia",
      "getMedia" => "Obter metadados de mídia",
      "deleteMedia" => "Excluir mídia",
      "listWebhookSubscriptions" => "Listar assinaturas de webhook",
      "createWebhookSubscription" => "Assinar webhooks para uma WABA",
      "deleteWebhookSubscription" => "Cancelar a assinatura de webhooks de uma WABA",
      "getMessagingAnalytics" => "Obter análises de mensagens",
      "getTemplateAnalytics" => "Obter análises de modelos",
      "getConversationAnalytics" => "Obter análises de conversas",
      "getPricingAnalytics" => "Obter análises de preços",
      "getBusinessProfile" => "Obter o perfil comercial",
      "updateBusinessProfile" => "Atualizar o perfil comercial",
      "getPhoneNumberSettings" => "Obter configurações do número de telefone",
      "updatePhoneNumberSettings" => "Atualizar configurações do número de telefone",
      "getConversationalAutomation" => "Obter automação de conversa",
      "updateConversationalAutomation" => "Atualizar automação de conversa",
      "listQrCodes" => "Listar códigos QR",
      "createQrCode" => "Criar um código QR",
      "updateQrCode" => "Atualizar um código QR",
      "deleteQrCode" => "Excluir um código QR",
      "listFlows" => "Listar Flows",
      "createFlow" => "Criar um Flow",
      "getFlow" => "Obter um Flow",
      "updateFlow" => "Atualizar um Flow",
      "deleteFlow" => "Excluir um Flow",
      "uploadFlowAsset" => "Enviar um arquivo JSON de Flow",
      "publishFlow" => "Publicar um Flow",
      "deprecateFlow" => "Descontinuar um Flow",
      "requestVerificationCode" => "Solicitar um código de verificação",
      "verifyPhoneNumberCode" => "Verificar o código de um número de telefone",
      "registerPhoneNumber" => "Registrar um número de telefone",
      "deregisterPhoneNumber" => "Cancelar o registro de um número de telefone",
      "setTwoStepVerification" => "Configurar a verificação em duas etapas",
      "removeTwoStepVerification" => "Remover a verificação em duas etapas",
      "syncCoexistenceContacts" => "Sincronizar contatos de coexistência",
      "syncCoexistenceHistory" => "Sincronizar o histórico de coexistência",
      "listBlockedUsers" => "Listar usuários bloqueados",
      "blockUsers" => "Bloquear usuários",
      "unblockUsers" => "Desbloquear usuários"
    }
  },
  "tr" => {
    title: "Eazybe Meta API Katmanı",
    description: "WhatsApp Business Cloud API için kimlik doğrulamalı tek bir Eazybe REST yüzeyi.",
    server: "Bu yer tutucuyu ortamınıza atanmış Eazybe API sunucusuyla değiştirin.",
    operation: ->(summary) { "#{summary}. Bu işlem için parametreleri, örneği ve kullanılabilir yanıtları inceleyin." },
    success: "İşlem başarıyla tamamlandı.",
    failure_responses: [
      "**Hata yanıtları**",
      "",
      "| **Durum** | **Anlamı** | **Eylem** |",
      "| --- | --- | --- |",
      "| `401` | Bearer tokenı eksik, geçersiz veya süresi dolmuş | Yeniden kimlik doğrulayın |",
      "| `404` | `phoneNumberId` veya `wabaId` kuruluşunuza bağlı değil ya da bağlantının yeniden yetkilendirilmesi gerekiyor | `GET /meta/phone-numbers` isteğini yeniden çalıştırın; `status: false` dönerse WABA'yı yeniden bağlayın |",
      "| `400`, `429` veya diğer | WhatsApp; geçersiz şablon, kapalı 24 saatlik pencere, kullanım sınırı veya başka bir nedenle isteği reddetti. Meta'nın özgün hatası iletilir | `error.message` ve `error.code` alanlarını inceleyin |",
      "| `502` | WhatsApp'a ulaşılamıyor veya istek zaman aşımına uğradı | Üstel geri çekilme ile yeniden deneyin |"
    ].join("\n"),
    get_phone_numbers_failure_responses: [
      "**Hata yanıtları**",
      "",
      "| **Durum** | **Anlamı** | **Eylem** |",
      "| --- | --- | --- |",
      "| `401` | Bearer tokenı eksik, geçersiz veya süresi dolmuş | Yeniden kimlik doğrulayın ve yeni bir token alın |",
      "| `400`, `429` veya diğer | Meta isteği reddetti: hız sınırı aşıldı, WABA kimliği geçersiz veya izin sorunu var. Meta'nın özgün hatası iletilir | `error.message` ve `error.code` alanlarını inceleyin; `429` durumunda geri çekilme uygulayın |",
      "| `502` | WhatsApp/Meta Graph API'ye ulaşılamıyor veya istek zaman aşımına uğradı | Üstel geri çekilme ile yeniden deneyin |"
    ].join("\n"),
    get_phone_number_details_failure_responses: [
      "**Hata yanıtları**",
      "",
      "| **Durum** | **Anlamı** | **Eylem** |",
      "| --- | --- | --- |",
      "| `401` | Bearer tokenı eksik, geçersiz veya süresi dolmuş | Yeniden kimlik doğrulayın ve yeni bir token alın |",
      "| `404` | `phoneNumberId` kuruluşunuza bağlı değil veya WABA bağlantısının yeniden yetkilendirilmesi gerekiyor | Geçerli kimlikleri doğrulamak için `GET /meta/phone-numbers` isteğini çalıştırın; `is_waba_connected: false` dönerse WABA'yı yeniden bağlayın |",
      "| `400`, `429` veya diğer | Meta isteği reddetti: telefon numarası kimliği biçimi geçersiz, izinler yetersiz veya hız sınırına ulaşıldı. Meta'nın özgün hatası iletilir | `error.message` ve `error.code` alanlarını inceleyin; `429` durumunda geri çekilme uygulayın |",
      "| `502` | Meta Graph API'ye ulaşılamıyor veya istek zaman aşımına uğradı | Üstel geri çekilme ile yeniden deneyin |"
    ].join("\n"),
    get_waba_details_failure_responses: [
      "**Hata yanıtları**",
      "",
      "| **Durum** | **Anlamı** | **Eylem** |",
      "| --- | --- | --- |",
      "| `401` | Bearer tokenı eksik, geçersiz veya süresi dolmuş | Yeniden kimlik doğrulayın ve yeni bir token alın |",
      "| `404` | `wabaId` kuruluşunuza bağlı değil veya WABA bağlantısının yeniden yetkilendirilmesi gerekiyor | Bağlı WABA'ları listelemek için `GET /meta/phone-numbers` isteğini çalıştırın; gerekirse gömülü kayıt üzerinden yeniden bağlayın |",
      "| `400`, `429` veya diğer | Meta isteği reddetti: WABA kimliği biçimi geçersiz, izinler yetersiz veya hız sınırına ulaşıldı. Meta'nın özgün hatası iletilir | `error.message` ve `error.code` alanlarını inceleyin; `429` durumunda geri çekilme uygulayın |",
      "| `502` | Meta Graph API'ye ulaşılamıyor veya istek zaman aşımına uğradı | Üstel geri çekilme ile yeniden deneyin |"
    ].join("\n"),
    send_marketing_template_failure_responses: [
      "**Hata yanıtları**",
      "",
      "| **Durum** | **Anlamı** | **Eylem** |",
      "| --- | --- | --- |",
      "| `401` | Bearer tokenı eksik, geçersiz veya süresi dolmuş | Yeniden kimlik doğrulayın ve yeni bir token alın |",
      "| `404` | `phoneNumberId` kuruluşunuza bağlı değil veya WABA bağlantısının yeniden yetkilendirilmesi gerekiyor | Geçerli kimlikleri doğrulamak için `GET /meta/phone-numbers` isteğini çalıştırın; `is_waba_connected: false` dönerse WABA'yı yeniden bağlayın |",
      "| `400`, `429` veya diğer | WhatsApp isteği reddetti: şablon adı geçersiz, şablon onaylanmamış, 24 saatlik pencere kapalı, kullanım sınırına ulaşıldı veya bileşenler hatalı. Meta'nın özgün hatası iletilir | `error.message` ve `error.code` alanlarını inceleyin; `429` durumunda geri çekilme uygulayın |",
      "| `502` | Meta Graph API'ye ulaşılamıyor veya istek zaman aşımına uğradı | Üstel geri çekilme ile yeniden deneyin |"
    ].join("\n"),
    tags: {
      "Phone numbers" => ["Telefon numaraları", "Bağlı WABA ve telefon numarası kimliklerini bulun."],
      "Messaging" => ["Mesajlaşma", "WhatsApp mesajları gönderin ve mesaj durumunu güncelleyin."],
      "Templates" => ["Şablonlar", "WhatsApp mesaj şablonlarını yönetin."],
      "Media" => ["Medya", "WhatsApp medya dosyalarını yükleyin, görüntüleyin ve silin."],
      "Webhooks" => ["Webhook'lar", "Bir WABA'nın webhook aboneliklerini yönetin."],
      "Analytics" => ["Analizler", "Mesajlaşma, konuşma, fiyatlandırma ve şablon analizlerini görüntüleyin."],
      "Profiles and settings" => ["Profiller ve ayarlar", "İşletme profillerini ve telefon numarası ayarlarını yönetin."],
      "Automation" => ["Otomasyon", "Karşılama mesajlarını, başlangıç sorularını ve komutları yapılandırın."],
      "QR codes" => ["QR kodları", "Sohbete yönlendiren QR kodlarını yönetin."],
      "Flows" => ["Flows", "WhatsApp Flows yaşam döngüsünü yönetin."],
      "Number administration" => ["Numara yönetimi", "Numaraları kaydedin, PIN'leri yönetin ve birlikte kullanım verilerini eşitleyin."],
      "Block list" => ["Engellenenler listesi", "WhatsApp kullanıcılarını listeleyin, engelleyin ve engellerini kaldırın."]
    },
    summaries: {
      "getPhoneNumbers" => "Bağlı telefon numaralarını listele",
      "getPhoneNumberDetails" => "Telefon numarası ayrıntılarını getir",
      "getWabaDetails" => "WABA ayrıntılarını getir",
      "sendMessage" => "Desteklenen herhangi bir mesaj türünü gönder",
      "sendTemplateMessage" => "Şablon mesajı gönder",
      "sendMarketingTemplateMessage" => "Pazarlama şablonu gönder",
      "sendBulkTemplateMessages" => "Toplu şablon gönder",
      "sendFreeFormMessage" => "Serbest biçimli metin mesajı gönder",
      "markMessageRead" => "Mesajı okundu olarak işaretle",
      "reactToMessage" => "Mesaja tepki ver",
      "sendContactCard" => "Kişi kartları gönder",
      "showTypingIndicator" => "Yazıyor göstergesini göster",
      "listTemplates" => "Şablonları listele",
      "createTemplate" => "Şablon oluştur",
      "listAllTemplates" => "Tüm şablonları listele",
      "createTemplateFromLibrary" => "Meta kitaplığından şablon oluştur",
      "migrateTemplates" => "Şablonları başka bir WABA'dan taşı",
      "compareTemplates" => "Şablon performansını karşılaştır",
      "editTemplate" => "Şablonu düzenle",
      "deleteTemplate" => "Şablonu sil",
      "uploadMedia" => "Medya yükle",
      "getMedia" => "Medya meta verilerini getir",
      "deleteMedia" => "Medyayı sil",
      "listWebhookSubscriptions" => "Webhook aboneliklerini listele",
      "createWebhookSubscription" => "WABA'yı webhook'lara abone et",
      "deleteWebhookSubscription" => "WABA'nın webhook aboneliğini kaldır",
      "getMessagingAnalytics" => "Mesajlaşma analizlerini getir",
      "getTemplateAnalytics" => "Şablon analizlerini getir",
      "getConversationAnalytics" => "Konuşma analizlerini getir",
      "getPricingAnalytics" => "Fiyatlandırma analizlerini getir",
      "getBusinessProfile" => "İşletme profilini getir",
      "updateBusinessProfile" => "İşletme profilini güncelle",
      "getPhoneNumberSettings" => "Telefon numarası ayarlarını getir",
      "updatePhoneNumberSettings" => "Telefon numarası ayarlarını güncelle",
      "getConversationalAutomation" => "Konuşma otomasyonunu getir",
      "updateConversationalAutomation" => "Konuşma otomasyonunu güncelle",
      "listQrCodes" => "QR kodlarını listele",
      "createQrCode" => "QR kodu oluştur",
      "updateQrCode" => "QR kodunu güncelle",
      "deleteQrCode" => "QR kodunu sil",
      "listFlows" => "Flows öğelerini listele",
      "createFlow" => "Flow oluştur",
      "getFlow" => "Flow getir",
      "updateFlow" => "Flow güncelle",
      "deleteFlow" => "Flow sil",
      "uploadFlowAsset" => "Flow JSON dosyası yükle",
      "publishFlow" => "Flow yayımla",
      "deprecateFlow" => "Flow kullanımını sonlandır",
      "requestVerificationCode" => "Doğrulama kodu iste",
      "verifyPhoneNumberCode" => "Telefon numarası kodunu doğrula",
      "registerPhoneNumber" => "Telefon numarasını kaydet",
      "deregisterPhoneNumber" => "Telefon numarasının kaydını kaldır",
      "setTwoStepVerification" => "İki adımlı doğrulamayı ayarla",
      "removeTwoStepVerification" => "İki adımlı doğrulamayı kaldır",
      "syncCoexistenceContacts" => "Birlikte kullanım kişilerini eşitle",
      "syncCoexistenceHistory" => "Birlikte kullanım mesaj geçmişini eşitle",
      "listBlockedUsers" => "Engellenen kullanıcıları listele",
      "blockUsers" => "Kullanıcıları engelle",
      "unblockUsers" => "Kullanıcıların engelini kaldır"
    }
  }
}.freeze

PARAMETERS = {
  "es" => {
    "phoneNumberId" => "ID del número de teléfono devuelto por `GET /meta/phone-numbers`.",
    "wabaId" => "ID de la cuenta de WhatsApp Business devuelto por `GET /meta/phone-numbers`.",
    "fields" => "Campos de Graph API separados por comas.",
    "limit" => "Número máximo de elementos que se devolverán.",
    "after" => "Cursor de paginación de Meta de la respuesta anterior.",
    "name" => "Nombre usado para filtrar o identificar el recurso.",
    "status" => "Estado de Meta usado para filtrar los resultados.",
    "templateId" => "ID de la plantilla base.",
    "comparedTo" => "IDs de plantillas separados por comas para la comparación.",
    "start" => "Inicio del intervalo en segundos Unix.",
    "end" => "Fin del intervalo en segundos Unix.",
    "templateIdOrName" => "Usa un ID para editar y un nombre para eliminar.",
    "hsmId" => "ID de plantilla de Meta para eliminar una sola variante de idioma.",
    "mediaId" => "ID del archivo multimedia devuelto al subirlo.",
    "code" => "Código del recurso.",
    "phoneNumbers" => "IDs de números de teléfono separados por comas.",
    "metricTypes" => "Tipos de métricas separados por comas.",
    "dimensions" => "Dimensiones separadas por comas.",
    "flowId" => "ID del Flow devuelto por Meta."
  },
  "pt" => {
    "phoneNumberId" => "ID do número de telefone retornado por `GET /meta/phone-numbers`.",
    "wabaId" => "ID da conta do WhatsApp Business retornado por `GET /meta/phone-numbers`.",
    "fields" => "Campos da Graph API separados por vírgulas.",
    "limit" => "Número máximo de itens a retornar.",
    "after" => "Cursor de paginação da Meta da resposta anterior.",
    "name" => "Nome usado para filtrar ou identificar o recurso.",
    "status" => "Estado da Meta usado para filtrar os resultados.",
    "templateId" => "ID do modelo de referência.",
    "comparedTo" => "IDs de modelos separados por vírgulas para comparação.",
    "start" => "Início do intervalo em segundos Unix.",
    "end" => "Fim do intervalo em segundos Unix.",
    "templateIdOrName" => "Use um ID para editar e um nome para excluir.",
    "hsmId" => "ID do modelo da Meta para excluir uma única variante de idioma.",
    "mediaId" => "ID da mídia retornado no envio.",
    "code" => "Código do recurso.",
    "phoneNumbers" => "IDs de números de telefone separados por vírgulas.",
    "metricTypes" => "Tipos de métricas separados por vírgulas.",
    "dimensions" => "Dimensões separadas por vírgulas.",
    "flowId" => "ID do Flow retornado pela Meta."
  },
  "tr" => {
    "phoneNumberId" => "`GET /meta/phone-numbers` tarafından döndürülen telefon numarası kimliği.",
    "wabaId" => "`GET /meta/phone-numbers` tarafından döndürülen WhatsApp Business hesabı kimliği.",
    "fields" => "Virgülle ayrılmış Graph API alanları.",
    "limit" => "Döndürülecek en fazla öğe sayısı.",
    "after" => "Önceki yanıttaki Meta sayfalama imleci.",
    "name" => "Kaynağı filtrelemek veya tanımlamak için kullanılan ad.",
    "status" => "Sonuçları filtrelemek için kullanılan Meta durumu.",
    "templateId" => "Temel şablon kimliği.",
    "comparedTo" => "Karşılaştırılacak virgülle ayrılmış şablon kimlikleri.",
    "start" => "Aralığın Unix saniyesi cinsinden başlangıcı.",
    "end" => "Aralığın Unix saniyesi cinsinden sonu.",
    "templateIdOrName" => "Düzenlemek için kimlik, silmek için ad kullanın.",
    "hsmId" => "Tek bir dil varyantını silmek için Meta şablon kimliği.",
    "mediaId" => "Yükleme işleminden döndürülen medya kimliği.",
    "code" => "Kaynak kodu.",
    "phoneNumbers" => "Virgülle ayrılmış telefon numarası kimlikleri.",
    "metricTypes" => "Virgülle ayrılmış metrik türleri.",
    "dimensions" => "Virgülle ayrılmış boyutlar.",
    "flowId" => "Meta tarafından döndürülen Flow kimliği."
  }
}.freeze

COMMON = {
  "es" => {
    auth: "Token bearer de Eazybe. El token identifica la organización y debe mantenerse en el servidor.",
    bad_request: "Meta rechazó la solicitud o uno de los valores no es válido.",
    unauthorized: "El token bearer de Eazybe falta, no es válido o ha caducado.",
    not_found: "La WABA o el número solicitado no está conectado a la organización autenticada.",
    rate_limited: "Se alcanzó un límite de Meta. Reintenta con espera exponencial.",
    upstream: "Meta no estaba disponible o no respondió dentro de 15 segundos.",
    meta_object: "Objeto de WhatsApp Cloud API devuelto o aceptado por Meta.",
    meta_response: "Respuesta correcta transmitida desde WhatsApp Cloud API."
  },
  "pt" => {
    auth: "Token bearer da Eazybe. O token identifica a organização e deve ser mantido no servidor.",
    bad_request: "A Meta rejeitou a solicitação ou um valor não é válido.",
    unauthorized: "O token bearer da Eazybe está ausente, é inválido ou expirou.",
    not_found: "A WABA ou o número solicitado não está conectado à organização autenticada.",
    rate_limited: "Um limite da Meta foi atingido. Tente novamente com espera exponencial.",
    upstream: "A Meta estava indisponível ou não respondeu em 15 segundos.",
    meta_object: "Objeto da WhatsApp Cloud API retornado ou aceito pela Meta.",
    meta_response: "Resposta bem-sucedida repassada pela WhatsApp Cloud API."
  },
  "tr" => {
    auth: "Eazybe bearer tokenı. Token kuruluşu tanımlar ve sunucuda güvenli tutulmalıdır.",
    bad_request: "Meta isteği reddetti veya bir değer geçersiz.",
    unauthorized: "Eazybe bearer tokenı eksik, geçersiz veya süresi dolmuş.",
    not_found: "İstenen WABA veya numara, kimliği doğrulanmış kuruluşa bağlı değil.",
    rate_limited: "Bir Meta sınırına ulaşıldı. Üstel geri çekilme ile yeniden deneyin.",
    upstream: "Meta'ya ulaşılamadı veya Meta 15 saniye içinde yanıt vermedi.",
    meta_object: "Meta tarafından döndürülen veya kabul edilen WhatsApp Cloud API nesnesi.",
    meta_response: "WhatsApp Cloud API'den iletilen başarılı yanıt."
  }
}.freeze

def deep_copy(value)
  Marshal.load(Marshal.dump(value))
end

def localize_parameter!(parameter, locale)
  return unless parameter.is_a?(Hash) && parameter["name"]

  translated = PARAMETERS.fetch(locale)[parameter["name"]]
  parameter["description"] = translated if translated
end

def walk_properties!(value, locale)
  case value
  when Hash
    if value["properties"].is_a?(Hash)
      value["properties"].each do |name, property|
        next unless property.is_a?(Hash) && property.key?("description")

        translated = PARAMETERS.fetch(locale)[name]
        translated ? property["description"] = translated : property.delete("description")
      end
    end
    value.each_value { |child| walk_properties!(child, locale) }
  when Array
    value.each { |child| walk_properties!(child, locale) }
  end
end

def localize_spec(source, locale, config)
  spec = deep_copy(source)
  common = COMMON.fetch(locale)

  spec["info"]["title"] = config[:title]
  spec["info"]["description"] = config[:description]
  spec["servers"].first["description"] = config[:server]

  spec["tags"].each do |tag|
    translated_name, translated_description = config[:tags].fetch(tag["name"])
    tag["name"] = translated_name
    tag["description"] = translated_description
  end

  tag_names = config[:tags].transform_values(&:first)
  security_scheme = spec.dig("components", "securitySchemes", "bearerAuth")
  security_scheme["description"] = common[:auth]

  spec.dig("components", "parameters").each_value do |parameter|
    localize_parameter!(parameter, locale)
  end

  response_text = {
    "BadRequest" => common[:bad_request],
    "Unauthorized" => common[:unauthorized],
    "NotFound" => common[:not_found],
    "RateLimited" => common[:rate_limited],
    "UpstreamError" => common[:upstream]
  }
  spec.dig("components", "responses").each do |name, response|
    response["description"] = response_text.fetch(name)
  end

  schemas = spec.dig("components", "schemas")
  schemas["MetaObject"]["description"] = common[:meta_object]
  schemas["MetaResponse"]["description"] = common[:meta_response]
  schemas.each_value { |schema| walk_properties!(schema, locale) }

  spec["paths"].each_value do |path_item|
    Array(path_item["parameters"]).each { |parameter| localize_parameter!(parameter, locale) }

    HTTP_METHODS.each do |method|
      operation = path_item[method]
      next unless operation

      operation_id = operation.fetch("operationId")
      summary = config[:summaries].fetch(operation_id)
      operation["summary"] = summary
      operation["description"] = config[:operation].call(summary)
      operation["tags"] = operation.fetch("tags").map { |tag| tag_names.fetch(tag) }
      operation["x-mint"] ||= {}
      operation["x-mint"]["href"] = "/#{locale}#{operation["x-mint"].fetch("href")}"
      operation["x-mint"]["metadata"] = {
        "title" => summary,
        "description" => operation["description"],
        "sidebarTitle" => summary
      }
      operation["x-mint"].delete("content")

      Array(operation["parameters"]).each { |parameter| localize_parameter!(parameter, locale) }
      walk_properties!(operation, locale)
    end
  end

  spec
end

def find_array_end(text, array_start)
  depth = 0
  in_string = false
  escaped = false

  (array_start...text.length).each do |index|
    character = text[index]

    if in_string
      if escaped
        escaped = false
      elsif character == "\\"
        escaped = true
      elsif character == '"'
        in_string = false
      end
      next
    end

    if character == '"'
      in_string = true
    elsif character == "["
      depth += 1
    elsif character == "]"
      depth -= 1
      return index if depth.zero?
    end
  end

  raise "Could not find the end of the localized navigation pages array"
end

def write_operation_pages(spec, locale)
  page_map = {}

  spec.fetch("paths").each do |path, path_item|
    HTTP_METHODS.each do |method|
      operation = path_item[method]
      next unless operation

      href = operation.dig("x-mint", "href")
      relative_page = href.delete_prefix("/")
      output_file = File.join(ROOT, "#{relative_page}.mdx")
      FileUtils.mkdir_p(File.dirname(output_file))

      openapi_reference = "/#{locale}/api-reference/meta/openapi.json #{method.upcase} #{path}"
      content = <<~MDX
        ---
        title: #{JSON.generate(operation.fetch("summary"))}
        sidebarTitle: #{JSON.generate(operation.fetch("summary"))}
        description: #{JSON.generate(operation.fetch("description"))}
        openapi: #{JSON.generate(openapi_reference)}
        ---
      MDX
      File.write(output_file, content)
      page_map["#{method.upcase} #{path}"] = relative_page
    end
  end

  page_map
end

def update_navigation(locale, page_map)
  config_file = File.join(ROOT, "docs.json")
  config = File.read(config_file)
  marker = %("openapi": "/#{locale}/api-reference/meta/openapi.json")
  marker_index = config.index(marker)
  raise "Could not find navigation marker for #{locale}" unless marker_index

  pages_index = config.index('"pages": [', marker_index)
  raise "Could not find navigation pages for #{locale}" unless pages_index

  array_start = config.index("[", pages_index)
  array_end = find_array_end(config, array_start)
  pages = config[array_start..array_end]
  replaced = pages.gsub(%r{"((?:GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD|TRACE) /meta/[^"]+)"}) do
    operation = Regexp.last_match(1)
    JSON.generate(page_map.fetch(operation))
  end

  config[array_start..array_end] = replaced
  File.write(config_file, config)
end

source = YAML.load_file(SOURCE)

LOCALES.each do |locale, config|
  output_dir = File.join(ROOT, locale, "api-reference/meta")
  FileUtils.mkdir_p(output_dir)
  output_file = File.join(output_dir, "openapi.json")
  localized = localize_spec(source, locale, config)
  File.write(output_file, JSON.pretty_generate(localized) + "\n")
  page_map = write_operation_pages(localized, locale)
  update_navigation(locale, page_map)
  puts "Generated #{output_file.sub("#{ROOT}/", "")}"
  puts "Generated #{page_map.size} endpoint pages for #{locale}"
end
