# Tech Stack — httpbin.org

## Framework

- **Name**: Flask (Python)
- **Version**: N/A (not exposed in headers)
- **WSGI Server**: gunicorn 19.9.0
- **Detection Signal**: HTML contains Flasgger (Swagger UI for Flask) references

## Dependencies

- Flask
- Flasgger (API documentation)
- Werkzeug

## Server

- **Platform**: AWS (inferred from X-Amzn-Trace-Id header)
- **Python**: 3.x (inferred)

## CDN

- None detected

## Authentication

- None required
- Public API

## Bot Protection

- None