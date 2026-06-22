# Site Map — httpbin.org

## Discovered Endpoints

### Core HTTP Methods

| Path | Method | Description |
|------|--------|-------------|
| `/get` | GET | Echo GET request |
| `/post` | POST | Echo POST body |
| `/put` | PUT | Echo PUT body |
| `/delete` | DELETE | Echo DELETE |
| `/patch` | PATCH | Echo PATCH body |
| `/head` | HEAD | Echo HEAD request |

### Response Manipulation

| Path | Method | Description |
|------|--------|-------------|
| `/status/{code}` | GET | Return specific status code |
| `/status/418` | GET | Return 418 I'm a teapot |

### Request Data

| Path | Method | Description |
|------|--------|-------------|
| `/headers` | GET | Echo request headers |
| `/ip` | GET | Return client IP |
| `/uuid` | GET | Return random UUID |
| `/user-agent` | GET | Return user-agent |

### Forms & Data

| Path | Method | Description |
|------|--------|-------------|
| `/forms/post` | POST | HTML form |
| `/xml` | GET | Return sample XML |
| `/json` | GET | Return sample JSON |

### Content

| Path | Method | Description |
|------|--------|-------------|
| `/encoding/utf8` | GET | UTF-8 demo |
| `/bytes/{n}` | GET | Random bytes |
| `/links/{n}` | GET | HTML with links |
| `/image` | GET | Sample image |
| `/image/png` | GET | PNG image |
| `/image/jpeg` | GET | JPEG image |
| `/image/webp` | GET | WebP image |
| `/image/svg` | GET | SVG image |

### Response Delay

| Path | Method | Description |
|------|--------|-------------|
| `/delay/{n}` | GET | Delay response by n seconds |
| `/drip` | GET | Drip response slowly |

### Authentication

| Path | Method | Description |
|------|--------|-------------|
| `/basic-auth/{user}/{passwd}` | GET | Basic auth |
| `/hidden-basic-auth/{user}/{passwd}` | GET | Hidden basic auth |
| `/digest-auth/{qop}/{user}/{passwd}` | GET | Digest auth |
| `/stream/{n}` | GET | Stream n lines |
| `/links/{n}` | GET | Redirects |

### Other

| Path | Method | Description |
|------|--------|-------------|
| `/cookies` | GET | Return cookies |
| `/cookies/set` | GET | Set cookies |
| `/redirect/{n}` | GET | Redirect n times |
| `/redirect-to` | GET | Redirect to URL |
| `/anything` | * | Echo request fully |