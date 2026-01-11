# Required Images for Eazybe Documentation

## Download Instructions

Since images are hosted on Intercom's CDN with time-limited URLs:

1. **Visit help.eazybe.com** articles directly
2. **Right-click images** → Save Image As
3. **Use filenames** specified below
4. **Upload** to the appropriate `/images/` subfolder

---

## Directory Structure

Create these folders in `/images/`:
- hubspot/
- zoho/
- salesforce/
- agents/
- waba/
- revenue-inbox/
- productivity/
- getting-started/

---

## Getting Started Images

**Folder:** `/images/getting-started/`

| Filename | Description |
|----------|-------------|
| `extension-install.png` | Chrome extension install button |
| `sidebar-overview.png` | Eazybe sidebar in WhatsApp Web |
| `qr-scan.png` | WhatsApp QR code scanning |
| `connection-success.png` | Successful connection screen |

---

## HubSpot Images

**Folder:** `/images/hubspot/`

| Filename | Description |
|----------|-------------|
| `integrations-button.png` | Integrations button in sidebar |
| `connect-button.png` | Connect to HubSpot button |
| `select-account.png` | HubSpot account selection |
| `permissions-screen.png` | Permissions approval |
| `hubspot-icon-chat.png` | HubSpot icon in chat sidebar |
| `mini-crm-panel.png` | Mini-CRM view panel |
| `create-contact.png` | Create contact form |
| `create-deal.png` | Deal creation form |
| `workflow-action.png` | Workflow WhatsApp action |
| `activity-timeline.png` | HubSpot activity timeline |

---

## Zoho Images

**Folder:** `/images/zoho/`

| Filename | Description |
|----------|-------------|
| `zoho-connect.png` | Connect to Zoho button |
| `zoho-permissions.png` | Authorization screen |
| `zoho-mini-crm.png` | Mini-CRM panel |
| `zoho-sync-settings.png` | Sync configuration |

---

## Salesforce Images

**Folder:** `/images/salesforce/`

| Filename | Description |
|----------|-------------|
| `sf-connect.png` | Connect to Salesforce |
| `sf-permissions.png` | OAuth permissions |
| `sf-mini-crm.png` | Mini-CRM panel |

---

## AI Agents Images

**Folder:** `/images/agents/`

| Filename | Description | Source Article |
|----------|-------------|----------------|
| `unreplied-inbox.png` | Team inbox unreplied filter | AI Agent article |
| `critical-label.png` | Critical priority badge | AI Agent article |
| `filter-controls.png` | Priority filter options | AI Agent article |
| `admin-notification.png` | WhatsApp summary notification | AI Agent article |
| `ai-suggestions.png` | Reply suggestions panel | AI Suggestions |
| `chatbot-flow.png` | Flow builder interface | Agents article |

---

## WABA Images

**Folder:** `/images/waba/`

| Filename | Description |
|----------|-------------|
| `waba-connect.png` | WABA connection screen |
| `coexistence-qr.png` | Coexistence QR code |
| `template-create.png` | Template creation form |
| `template-list.png` | Templates list view |
| `broadcast-create.png` | Broadcast creation |
| `broadcast-analytics.png` | Broadcast results |
| `wallet-balance.png` | Wallet balance screen |

---

## Revenue Inbox Images

**Folder:** `/images/revenue-inbox/`

| Filename | Description |
|----------|-------------|
| `inbox-overview.png` | Main inbox view |
| `conversation-panel.png` | Conversation detail |
| `labels-panel.png` | Labels management |
| `funnels-view.png` | Funnel stages |
| `assign-dropdown.png` | Assign conversation |

---

## Productivity Images

**Folder:** `/images/productivity/`

| Filename | Description |
|----------|-------------|
| `quick-replies-panel.png` | Quick replies list |
| `create-reply.png` | Create quick reply form |
| `scheduled-list.png` | Scheduled messages |
| `schedule-form.png` | Schedule message form |
| `privacy-blur.png` | Privacy blur enabled |

---

## Analytics Images

**Folder:** `/images/analytics/`

| Filename | Description |
|----------|-------------|
| `dashboard.png` | Analytics dashboard |
| `team-metrics.png` | Team performance |
| `conversation-chart.png` | Conversation trends |

---

## Alternative: Take Fresh Screenshots

If you can't access Intercom images, take new screenshots:

1. **Use consistent browser size** (1200px width)
2. **PNG format** (no compression artifacts)
3. **Blur sensitive data** (customer info)
4. **Add annotations** for complex UI
5. **Use same styling** across all screenshots

---

## After Adding Images

```bash
git add images/
git commit -m "Add documentation images"
git push origin main
```

Mintlify will automatically pick up the new images.
