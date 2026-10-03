# WordPress Framework Fingerprinting Guide

## Framework Overview
WordPress is the world's most popular content management system (CMS), powering over 42% of all websites. It's an open-source platform written in PHP that offers extensive customization through themes, plugins, and APIs. WordPress supports everything from simple blogs to complex e-commerce sites via plugins like WooCommerce.

## Fingerprinting Patterns

### 1. Static File Patterns
WordPress has distinctive static file patterns:
- `/wp-content/` - Themes, plugins, uploads
- `/wp-includes/` - Core WordPress files
- `/wp-admin/` - Administration interface
- `/wp-json/` - REST API endpoints
- `/xmlrpc.php` - XML-RPC API
- `/wp-login.php` - Login page
- `/wp-signup.php` - Registration page (multisite)
- `/wp-trackback.php` - Trackback endpoint
- `/license.txt` - WordPress license
- `/readme.html` - WordPress readme

### 2. HTTP Headers
WordPress sites often show these headers:
```
X-Powered-By: PHP/[version]
X-Generator: WordPress [version]
Link: <https://example.com/wp-json/>; rel="https://api.w.org/"
Link: <https://example.com/>; rel=shortlink
Server: nginx/Apache
```

### 3. HTML Meta Tags
WordPress sites typically include:
```html
<meta name="generator" content="WordPress [version]" />
<link rel="EditURI" type="application/rsd+xml" title="RSD" href="https://example.com/xmlrpc.php?rsd" />
<link rel="wlwmanifest" type="application/wlwmanifest+xml" href="https://example.com/wp-includes/wlwmanifest.xml" />
<link rel="pingback" href="https://example.com/xmlrpc.php" />
<link rel='https://api.w.org/' href='https://example.com/wp-json/' />
```