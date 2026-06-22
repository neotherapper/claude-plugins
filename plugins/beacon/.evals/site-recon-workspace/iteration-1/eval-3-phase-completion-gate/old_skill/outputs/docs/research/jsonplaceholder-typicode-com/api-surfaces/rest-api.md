# REST API — JSONPlaceholder

A free fake REST API for testing and prototyping.

## Base URL

```
https://jsonplaceholder.typicode.com
```

## Authentication

None required. Public API.

## Rate Limits

- 1000 requests per window
- Track via headers: `X-Ratelimit-Limit`, `X-Ratelimit-Remaining`, `X-Ratelimit-Reset`

## Resources

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/posts` | List all posts (100) |
| GET | `/posts/{id}` | Get single post |
| POST | `/posts` | Create post |
| PUT | `/posts/{id}` | Update post (full) |
| PATCH | `/posts/{id}` | Update post (partial) |
| DELETE | `/posts/{id}` | Delete post |

**Response:** `POST /posts` returns created object with `id: 101`

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | List all users (10) |
| GET | `/users/{id}` | Get single user |

### Comments

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/comments` | List all comments (500) |
| GET | `/comments/{id}` | Get single comment |
| GET | `/posts/{id}/comments` | Get comments for post |

### Albums

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/albums` | List all albums (100) |
| GET | `/albums/{id}` | Get single album |

### Photos

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/photos` | List all photos (5000) |
| GET | `/photos/{id}` | Get single photo |

### Todos

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/todos` | List all todos (200) |
| GET | `/todos/{id}` | Get single todo |

## Query Parameters

- `?userId={id}` — Filter by user
- `?postId={id}` — Filter by post

## Nested Routes

- `/users/{id}/posts` — Posts by user
- `/posts/{id}/comments` — Comments on post
- `/albums/{id}/photos` — Photos in album

## Example Request

```bash
# Get all posts
curl https://jsonplaceholder.typicode.com/posts

# Get posts by user 1
curl "https://jsonplaceholder.typicode.com/posts?userId=1"

# Create post
curl -X POST https://jsonplaceholder.typicode.com/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"foo","body":"bar","userId":1}'
```

## Example Response

```json
{
  "userId": 1,
  "id": 101,
  "title": "foo",
  "body": "bar"
}
```

## Notes

- IDs 1-100 exist for all resources
- POST/PUT/DELETE operations return the modified object but don't persist changes
- All data is fictional and reset on each request