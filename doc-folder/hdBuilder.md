# HD Builder: Mintlify MDX Migration Workflow

> ** reusable prompt template for converting source documentation to Mintlify MDX across 4 languages (en, es, pt, tr) with strict local image mapping.**

---

## How to Use

1. Ask Claude: *"Read the hdBuilder.md file and execute the migration workflow"*
2. Claude will ask for the source content
3. Provide your source doc content (paste directly or attach file)
4. Claude will execute the full migration

---

## CONFIGURATION TEMPLATE

Fill these values before each migration:

```yaml
# ============================================================================
# MIGRATION CONFIGURATION (Fill for each doc)
# ============================================================================

# Source Content
SOURCE_CONTENT: "<paste your source doc content here>"

# File Paths (these are defaults, update if different)
DOCS_JSON_PATH: "docs.json"
IMAGE_MAP_FILE: "image-mapping.json"

# Output Configuration
BASE_SLUG: "chatbot"                    # Used for filename: {BASE_SLUG}-{lang}.mdx
DOC_TITLE: "Chatbot Setup"              # Natural title for navigation (will be localized)
DOC_DESCRIPTION: "Learn how to set up and configure your chatbot"  # For frontmatter

# Language Output Directories (defaults)
OUT_DIR_EN: "en"
OUT_DIR_ES: "es"
OUT_DIR_PT: "pt"
OUT_DIR_TR: "tr"

# Navigation Insertion Point (specify where to add in docs.json)
NAV_EN: "language:en -> group:CRM Integration -> group:HubSpot"
NAV_ES: "language:es -> group:Integración CRM -> group:HubSpot"
NAV_PT: "language:pt -> group:Integração CRM -> group:HubSpot"
NAV_TR: "language:tr -> group:CRM Entegrasyonu -> group:HubSpot"

# Options
USE_LANG_PREFIX_IN_NAV_PATHS: true
```

---

## EXECUTION INSTRUCTIONS FOR CLAUDE

When executing this workflow:

### Step 1: Read Configuration
- Parse the YAML configuration above
- Validate all paths exist
- Read IMAGE_MAP_FILE to build image lookup table

### Step 2: Process Source Content
- Parse SOURCE_CONTENT
- Extract all image references
- Preserve structure, headings, steps, and sections

### Step 3: Image Mapping Audit (REQUIRED OUTPUT)
Before writing any files, output:

```markdown
## IMAGE AUDIT
### SOURCE_IMAGE_URLS
[List all image URLs found in source content]

### IMAGE_MAPPING_TABLE
| Source Reference | Matched Key | Local Path | Status |
|------------------|-------------|------------|--------|
| [url] | [key] | [/images/xxx.png] | MAPPED |
| [url] | [key] | [/images/xxx.png] | TODO |

### SUMMARY
- Total Images: [count]
- Mapped: [count]
- Missing/TODO: [count]
```

### Step 4: Generate MDX Files
Create 4 files with identical structure, translated content:

```
{OUT_DIR_EN}/{BASE_SLUG}-en.mdx
{OUT_DIR_ES}/{BASE_SLUG}-sp.mdx
{OUT_DIR_PT}/{BASE_SLUG}-pt.mdx
{OUT_DIR_TR}/{BASE_SLUG}-tr.mdx
```

**Frontmatter format:**
```yaml
---
title: "[Localized Title]"
description: "[Localized Description]"
---
```

### Step 5: Update Navigation (docs.json)
Insert navigation entries at the specified insertion points for all 4 languages.

---

## FORMATTING RULES

| Rule | Implementation |
|------|----------------|
| **No External Images** | Replace all external URLs with local paths from IMAGE_MAP_FILE. Flag missing with `<!-- TODO: [original_url] -->` |
| **Standard Syntax** | Use `![alt](/images/xxx.png)` or `<Frame src="/images/xxx.png" />` |
| **Preserve Structure** | Maintain section order, steps, headings. Do NOT invent new sections |
| **Premium Formatting** | Apply Mintlify components: `<Steps>`, `<Note>`, `<Warning>`, `<Tip>`, `<Accordion>` |
| **Professional Writing** | Fix grammar, spelling, ensure natural technical writing in all 4 languages |

---

## MINTLIFY COMPONENT REFERENCE

```mdx
<Steps>
    <Step>
        <h3>Step title</h3>
        Step content...
    </Step>
    <Step>
        <h3>Step title</h3>
        Step content...
    </Step>
</Steps>

<Note>
    Important information...
</Note>

<Warning>
    Warning content...
</Warning>

<Tip>
    Helpful tip...
</Tip>

<Accordion>
    <AccordionItem title="Item title">
        Expandable content...
    </AccordionItem>
</Accordion>
```

---

## LANGUAGES REFERENCE

| Language | Code | Folder | Suffix |
|----------|------|--------|--------|
| English | en | en/ | -en.mdx |
| Spanish | es | es/ | -sp.mdx |
| Portuguese | pt | pt/ | -pt.mdx |
| Turkish | tr | tr/ | -tr.mdx |

---

*This file is a reusable template. Update the CONFIGURATION section for each migration.*
