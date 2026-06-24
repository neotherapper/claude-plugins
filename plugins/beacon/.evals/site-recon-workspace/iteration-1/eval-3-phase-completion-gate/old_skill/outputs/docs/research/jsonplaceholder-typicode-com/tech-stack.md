# Tech Stack — jsonplaceholder.typicode.com

## Framework

- **Backend:** Express (Node.js)
- **Evidence:** `X-Powered-By: Express` HTTP header

## CDN & Hosting

- **CDN:** Cloudflare (cf-ray, cf-cache-status headers)
- **Hosting:** Heroku (via: 2.0 heroku-router)

## Frontend

- **CSS Framework:** Tailwind CSS v2.1.4
- **UI:** Static HTML with embedded content

## API Type

- REST API (JSON)
- No authentication required

## Rate Limiting

- `X-Ratelimit-Limit: 1000`
- `X-Ratelimit-Remaining: 999`

## Summary

JSONPlaceholder is a free fake REST API for testing and prototyping.
It provides fake data in JSON format for testing JSON APIs.