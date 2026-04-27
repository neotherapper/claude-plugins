# Site Map — httpbin.org

## Main Pages
- `/` — Main page (200)
- `/api` — API root (404)

## HTTP Method Endpoints
- `/get` — GET request echo (200)
- `/post` — POST request echo (405, needs data)
- `/put` — PUT request echo (405, needs data)
- `/delete` — DELETE request echo (405, needs data)

## Utility Endpoints
- `/anything` — Full request echo (200)
- `/headers` — Echo headers (200)
- `/ip` — Return origin IP (200)
- `/uuid` — Return random UUID (200)
- `/user-agent` — Echo user-agent (200)

## Static Resources
- `/flasgger_static/swagger-ui.css` — Swagger CSS
- `/static/favicon.ico` — Favicon

## Robot Rules
- `/deny` — Disallowed in robots.txt