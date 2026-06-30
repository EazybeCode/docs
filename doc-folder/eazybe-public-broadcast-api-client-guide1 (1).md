# Eazybe Public Broadcast API Guide

## Overview
This document explains how clients can use Eazybe's Public Broadcast API for Meta WABA-related broadcast operations. The API supports API key generation, single-recipient template broadcasts, bulk template broadcasts, health checks, and operational error handling.

The API uses JSON requests over HTTPS, authenticates through the `x-api-key` header, and is intended for approved WhatsApp template-based outbound messaging through the Eazybe platform.[file:1]

## Base configuration
- **Base URL:** `https://cerberus.eazybe.com/prod/api/v2` (replace with the production domain shared by Eazybe)[file:1]
- **Authentication:** `x-api-key` 
- **Content-Type:** `application/json`
- **Supported operations:** generate key, send single broadcast, send bulk broadcast, health check[file:1]

## Before you start
Clients should ensure the sending phone number is already onboarded on Eazybe and linked to an active WABA setup, because API key generation fails when no WABA account is found for the submitted number.

Clients should also confirm that the required WhatsApp templates are approved in Meta before attempting sends, because unapproved or missing templates return request failures.

## Authentication flow
### Step 1: Generate API key
Use this endpoint once for a registered sender number and securely store the returned API key for future requests.

**Endpoint**
```http
POST /broadcast/public/generate-key
```

**Request body**

| Field | Type | Required | Description |
|---|---|---|---|
| `phoneNumber` | string | Yes | Sender phone number with country code, without spaces or `+` |

**Example request**
```bash
curl -X POST https://cerberus.eazybe.com/prod/api/v2/broadcast/public/generate-key \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "919876543210"
  }'
```

**Success response**
```json
{
    "status": true,
    "message": "API key generated successfully",
    "data": {
        "apiKey": "9548e0f4ea0ab360ac9eeaf69f9754d72c6b606353037125d21842b9364ca8"
    }
}
```

**Failure example**
```json
{
    "statusCode": 400,
    "timestamp": "2026-04-14T07:13:33.289Z",
    "path": "/broadcast/public/generate-key",
    "method": "POST",
    "requestId": "9c57a355c364f07060335e348902c9b8",
    "message": "Failed to generate API key",
    "status": false,
    "status_code": 400,
    "data": {
        "error": {
            "message": "Phone number not found or not connected to WABA."
        }
    }
}
```

### Step 2: Use API key in request headers
All broadcast endpoints require the generated API key in the `x-api-key` header.

```http
x-api-key: YOUR_API_KEY
```

## Send single broadcast
Use the single broadcast endpoint to send one template message to one recipient.

**Endpoint**
```http
POST /broadcast/public/send-single
```

### Required request structure
| Field | Type | Required | Description |
|---|---|---|---|
| `templateName` | string | Yes | Approved WhatsApp template name |
| `templateLanguage` | string | Yes | Template language code, for example `en` |
| `templateType` | string | Yes | Template category: `MARKETING`, `UTILITY` |
| `countryCode` | string | Yes | Recipient country code without `+` |
| `toPhoneNumber` | string | Yes | Recipient mobile number |
| `templateId` | string | No | Meta template ID |
| `templateParams` | string[] | No | Template variable values in order {Required for the variable based templates only} |
| `broadcastName` | string | No | Optional label for this send |

### Example request
```bash
curl -X POST https://cerberus.eazybe.com/prod/api/v2/broadcast/public/send-single \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "templateName": "christmas_template",
    "templateLanguage": "en",
    "templateType": "MARKETING",
    "templateId": "768465685803110",
    "countryCode": "91",
    "toPhoneNumber": "8077378155",
    "templateParams": ["John", "100"],
    "broadcastName": "Single Broadcast Test"
  }'
```

### Success response
```json
{
    "status": true,
    "message": "Broadcast sent successfully",
    "data": {
        "status": true,
        "message": "Broadcast is being processed",
        "data": {
            "total_contacts": 1,
            "failed_contacts": 0,
            "estimated_cost": 0.94937,
            "oldBalance": 1860.0995179999998,
            "newEstimatedBalance": 1859.1501479999997
        }
    }
}
```

### Common failure responses
- **Invalid API key or unregistered number:** request fails when the API key does not match a valid signed-up sender.
- **Insufficient credits:** request fails when wallet credits are not enough for the send.
- **Invalid or unapproved template:** request fails if the template does not exist or is not approved.

## Send bulk broadcast
Use the bulk endpoint to send the same approved template to multiple recipients in one request. A single request can include up to 1000 recipients.

**Endpoint**
```http
POST /broadcast/public/send-bulk
```

### Required request structure
| Field | Type | Required | Description |
|---|---|---|---|
| `broadcastName` | string | Yes | Unique campaign name |
| `templateName` | string | Yes | Approved WhatsApp template name |
| `templateLanguage` | string | Yes | Template language code |
| `templateType` | string | Yes | Template category |
| `data` | array | Yes | Recipient list, maximum 1000 per request |
| `templateId` | string | No | Meta template ID |
| `globalTemplateParams` | string[] | No | Default variables used when recipient-level params are not provided |

### Recipient object in `data`
| Field | Type | Required | Description |
|---|---|---|---|
| `countryCode` | string | Yes | Recipient country code without `+` |
| `toPhoneNumber` | string | Yes | Recipient mobile number |
| `templateParams` | string[] | No | Recipient-level variables that override global values |

### Example request
```bash
curl -X POST https://cerberus.eazybe.com/prod/api/v2/broadcast/public/send-bulk \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "broadcastName": "Festival Campaign 2024",
    "templateName": "festive_offer_promo",
    "templateLanguage": "en",
    "templateType": "MARKETING",
    "templateId": "1172528374418691",
    "data": [
      {
        "countryCode": "91",
        "toPhoneNumber": "9897964421",
        "templateParams": ["John Doe", "212812790", "16-02-2026"]
      },
      {
        "countryCode": "91",
        "toPhoneNumber": "8077378155",
        "templateParams": ["Vineet", "122878278", "14-02-2026"]
      }
    ],
    "globalTemplateParams": ["Default Company", "Test date"]
  }'
```

### Success response
```json
{
    "status": true,
    "message": "Bulk broadcast queued successfully",
    "data": {
        "status": true,
        "message": "Broadcast is being processed",
        "data": {
            "total_contacts": 2,
            "failed_contacts": 0,
            "estimated_cost": 1.89874,
            "oldBalance": 1851.5995179999998,
            "newEstimatedBalance": 1849.7007779999997
        }
    }
}
```

### Operational notes
- A bulk request cannot exceed 1000 recipients.
- Broadcast names must be unique, otherwise the request fails.
- Invalid numbers can create partial failures; failed contacts are counted separately and credits are not deducted for those invalid contacts.
- Failed contacts may be stored with `failure_reason_code: "INVALID_PHONE_NUMBER"` for downstream tracking.

## Template parameter handling
The API supports both recipient-level parameters and global parameters.

### Recipient-level parameters
Use `templateParams` inside each recipient object when every contact should receive different variable values.

Example use cases:
- Order ID per customer
- Appointment time per customer
- Personalized name per recipient

### Global parameters
Use `globalTemplateParams` when the same variable values apply to all recipients in a bulk campaign.

This reduces repeated payload data and is useful for common campaign-wide values such as brand name, coupon code, or offer percentage.

### Rule of precedence
When recipient-level `templateParams` are provided, they override the global values for that recipient.

## Health check
Use the health endpoint to verify whether the Public Broadcast API service is operational.

**Endpoint**
```http
GET /broadcast/public/health
```

**Example request**
```bash
curl -X GET https://cerberus.eazybe.com/prod/api/v2/broadcast/public/health
```

**Sample response**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "service": "Public Broadcast API",
  "version": "1.0.0",
  "endpoints": {
    "single": "POST /broadcast/public/send-single",
    "bulk-standard": "POST /broadcast/public/send-bulk-standard",
    "health": "GET /broadcast/public/health"
  }
}
```

## Error handling reference
| Status code | Error | Meaning |
|---|---|---|
| `400` | `User is not signed up yet` | API key is invalid or the phone number is not registered |
| `400` | `No subscriptions available` | No active subscription is available for broadcasts |
| `400` | `Insufficient credits` | Wallet balance is not enough |
| `400` | `Template does not exist` | Template is missing or not approved |
| `400` | `Invalid template language` | Requested template language variant is not approved |
| `400` | `Invalid phone number format` | Country code or phone format is invalid |
| `400` | `Pricing not available` | Sending is not supported for the target country code |
| `400` | `Recipient limit exceeded` | Bulk request contains more than 1000 recipients |
| `400` | `Broadcast with same name exists` | Campaign name must be unique |
| `500` | `Internal Server Error` | Unexpected server-side error |

## Failure reason codes
| Code | Meaning | Notes |
|---|---|---|
| `INVALID_PHONE_NUMBER` | Invalid recipient number | Check country code and number formatting |
| `UNSUPPORTED_COUNTRY_CODE` | Country pricing unavailable | Destination not supported |
| `TEMPLATE_SEND_FAILED` | Template send failed | Review raw API error response |
| `131014` | Invalid parameter | Template parameter issue |
| `131051` | Rate limit exceeded | Too many requests sent in a short interval |
| `WORKER_ERROR` | Worker processing failure | Review worker error response |

## Rate limits and platform constraints
The document notes an approximate Meta sending rate of around 30 messages per second per WABA, with automatic retry and exponential backoff for rate-limit errors such as `429`, `80007`, and `130429`.

Clients should still batch responsibly and split large uploads into multiple requests once they approach the 1000-recipient per-request limit.

## Recommended client workflow
1. Onboard and verify the sender number on Eazybe before any API use.
2. Generate the API key once and store it securely.
3. Ensure the WhatsApp template is approved in Meta and the language variant is available.
4. Validate recipient country codes, phone numbers, and template variable count before sending.
5. Use the single endpoint for one-off tests and the bulk endpoint for campaigns.
6. Monitor the response for `failed_contacts`, balance changes, and queue status.
7. Use unique broadcast names for every campaign.

## Best practices for clients
- Store the API key securely and avoid regenerating it unnecessarily.
- Pre-validate numbers to reduce failures and operational cleanup.
- Match the number of template variables exactly with the approved template placeholders.
- Use `globalTemplateParams` for shared values and recipient-level params only when personalization is required.
- Check credits before large broadcast requests.
- Start with a small test batch before sending full-volume campaigns.

## Example payload patterns
### Single send with variables
```json
{
  "templateName": "order_shipped",
  "templateLanguage": "en",
  "templateType": "MARKETING",
  "countryCode": "91",
  "toPhoneNumber": "9876543210",
  "templateParams": ["John", "ORD12345", "17-02-2024"]
}
```

### Bulk send with recipient-level variables
```json
{
  "broadcastName": "Appointment Reminders",
  "templateName": "appointment_reminder",
  "templateLanguage": "en",
  "templateType": "UTILITY",
  "data": [
    {
      "countryCode": "1",
      "toPhoneNumber": "5551234567",
      "templateParams": ["Alice", "2024-01-20", "10:00 AM"]
    },
    {
      "countryCode": "1",
      "toPhoneNumber": "5559876543",
      "templateParams": ["Bob", "2024-01-20", "2:30 PM"]
    }
  ]
}
```

### Bulk send with global variables
```json
{
  "broadcastName": "Global Promo",
  "templateName": "promo_offer",
  "templateLanguage": "en",
  "templateType": "MARKETING",
  "data": [
    {
      "countryCode": "91",
      "toPhoneNumber": "9876543210"
    },
    {
      "countryCode": "91",
      "toPhoneNumber": "9876543211"
    }
  ],
  "globalTemplateParams": ["MyStore", "SAVE20", "20"]
}
```


