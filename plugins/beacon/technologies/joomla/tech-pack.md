# Joomla Tech Pack

## Framework Identification
**Name**: Joomla
**Type**: Content Management System (CMS)
**Language**: PHP
**Database**: MySQL

## Fingerprinting Rules
```yaml
rules:
  - name: joomla-generator-meta
    description: Detect Joomla via generator meta tag
    pattern: 'content="Joomla! - Open Source Content Management"'
    type: body
    confidence: definitive
    
  - name: joomla-administrator
    description: Detect Joomla via admin directory
    pattern: "/administrator/"
    type: path
    confidence: high
    
  - name: joomla-core-js
    description: Detect Joomla via core JavaScript file
    pattern: "/media/system/js/core.js"
    type: path
    confidence: high
    
  - name: joomla-option-param
    description: Detect Joomla via option parameter pattern
    pattern: "option=com_[a-z_]+"
    type: path
    confidence: high
    
  - name: joomla-version-xml
    description: Detect Joomla via version XML file
    pattern: "/administrator/manifests/files/joomla.xml"
    type: path
    confidence: high
    
  - name: joomla-module-structure
    description: Detect Joomla via module directory structure
    pattern: "/modules/mod_[a-z_]+/"
    type: path
    confidence: medium
    
  - name: joomla-cookie-pattern
    description: Detect Joomla via session cookie
    pattern: "(jos_|[a-f0-9]{32})"
    type: cookie
    confidence: medium
    
  - name: joomla-error-page
    description: Detect Joomla via error pages
    pattern: "The page you requested was not found.*Joomla"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for Joomla generator meta tag
- Look for `/administrator/` directory
- Probe `/media/system/js/core.js`
- Check for legacy Joomla option patterns (`option=com_`)
- Analyze cookies for Joomla patterns

### Phase 4: Directory Enumeration
- Enumerate `/administrator/`, `/components/`, `/modules/`, `/plugins/` directories
- Check `/templates/` directory for installed templates
- Probe `/media/system/` and `/media/[component]/` directories
- Look for `/cache/` directory patterns

### Phase 5: Known Patterns
- Apply Joomla-specific discovery probes
- Check common component routes (`com_content`, `com_users`)
- Probe `/api/index.php/v1/` for Joomla 4+ API
- Look for e-commerce extension patterns
- Check `/installation/` directory if accessible

### Phase 6: Version Analysis
- Extract version from `/administrator/manifests/files/joomla.xml`
- Check footer of admin login page (`/administrator/`)
- Analyze `/media/system/js/core.js` for version strings
- Check `/language/en-GB/en-GB.xml` for version info

### Phase 7: E-commerce Detection
- Check for VirtueMart (`com_virtuemart`)
- Look for HikaShop (`com_hikashop`)
- Probe for J2Store (`com_j2store`)
- Check for other e-commerce extensions

## Common Joomla Patterns

```http
# Content component
GET /index.php?option=com_content&view=article&id=1

# User component
GET /index.php?option=com_users&task=login

# Joomla 4+ API
GET /api/index.php/v1
GET /api/index.php/v1/content/articles

# Administrator login
GET /administrator/
POST /administrator/index.php

# Template assets
GET /templates/[template-name]/css/template.css
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| Version XML | `/administrator/manifests/files/joomla.xml` | High |
| Admin Footer | Version in `/administrator/` footer | High |
| Core JS | Version in `/media/system/js/core.js` | Medium |
| Language XML | `/language/en-GB/en-GB.xml` | Medium |
| Database | `#__schemas` table contains version info | Medium|

## E-commerce Extension Checklist
When Joomla is detected, probe for these e-commerce extensions:
- [ ] VirtueMart (`com_virtuemart`)
- [ ] HikaShop (`com_hikashop`)
- [ ] J2Store (`com_j2store`)
- [ ] Eshop (`com_eshop`)
- [ ] MijoShop (`com_mijoshop`)
- [ ] RedSHOP (`com_redshop`)
- [ ] RokQuickCart (`com_rokquickcart`)

## Framework-Specific Probes
Check these Joomla-specific endpoints:
```
/administrator/
/api/index.php/v1/
/media/system/js/core.js
/components/com_content/
/components/com_users/
/index.php?option=com_content
/templates/[template-name]/
```

## Technology Stack Integration

### Common Joomla Extensions
| Extension | Type | Detection Pattern |
|-----------|------|--------------------|
| VirtueMart | E-commerce | `/components/com_virtuemart/` |
| HikaShop | E-commerce | `/components/com_hikashop/` |
| J2Store | E-commerce | `/components/com_j2store/` |
| K2 | Content | `/components/com_k2/` |
| Community Builder | Social | `/components/com_comprofiler/` |
| JomSocial | Social | `/components/com_community/` |
| Admin Tools | Security | `/plugins/system/admintools/` |
| RSFirewall | Security | `/plugins/system/rsfirewall/` |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of `/administrator/` directory
- Check for Joomla-specific meta tags
- Validate error page patterns
- Test actual content component routes
- Cross-check with admin interface behavior

## Integration with Beacon Skill
- Load this tech pack when Joomla meta tags or directory patterns detected
- Run Joomla version detection
- Check for common Joomla components
- Probe for e-commerce extensions
- Document discovered API surfaces