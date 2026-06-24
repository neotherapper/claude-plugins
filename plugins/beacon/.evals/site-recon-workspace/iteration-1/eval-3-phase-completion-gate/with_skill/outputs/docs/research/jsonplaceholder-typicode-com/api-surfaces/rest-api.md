# REST API Surface — jsonplaceholder.typicode.com

## Overview

JSONPlaceholder is a free fake REST API for testing and prototyping. It provides a complete fake API with resources like posts, comments, users, albums, photos, and todos.

## Base URL

```
https://jsonplaceholder.typicode.com
```

## Authentication

**None required** — Public API with no authentication

## Resources

### Posts
- `GET /posts` — List all posts
- `GET /posts/:id` — Get single post
- `POST /posts` — Create post
- `PUT /posts/:id` — Update post
- `PATCH /posts/:id` — Patch post
- `DELETE /posts/:id` — Delete post

### Comments
- `GET /comments` — List all comments
- `GET /comments/:id` — Get single comment

### Users
- `GET /users` — List all users
- `GET /users/:id` — Get single user

### Albums
- `GET /albums` — List all albums
- `GET /albums/:id` — Get single album

### Photos
- `GET /photos` — List all photos
- `GET /photos/:id` — Get single photo

### Todos
- `GET /todos` — List all todos
- `GET /todos/:id` — Get single todo

## Filtering

Query parameters for filtering:
- `?userId=1` — Filter by user
- `?postId=1` — Filter by post
- `?albumId=1` — Filter by album

Example:
```bash
curl https://jsonplaceholder.typicode.com/posts?userId=1
```

## Nested Routes

- `/posts/1/comments` — Comments for post 1
- `/users/1/posts` — Posts by user 1
- `/albums/1/photos` — Photos in album 1

## Pagination

- `_page=1` — Page number
- `_limit=10` — Items per page

## Example Usage

```bash
# Get all posts
curl https://jsonplaceholder.typicode.com/posts

# Get single post
curl https://jsonplaceholder.typicode.com/posts/1

# Create post
curl -X POST https://jsonplaceholder.typicode.com/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"foo","body":"bar","userId":1}'

# Update post
curl -X PUT https://jsonplaceholder.typicode.com/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"id":1,"title":"foo","body":"bar","userId":1}'

# Delete post
curl -X DELETE https://jsonplaceholder.typicode.com/posts/1
```

## Rate Limits

- 1000 requests per window
- Headers show remaining count

## Source

- GitHub: [typicode/jsonplaceholder](https://github.com/typicode/jsonplaceholder)
- Powered by: json-server