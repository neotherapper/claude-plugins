# Site Map — jsonplaceholder.typicode.com

## Static Pages

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| / | GET | 200 | Landing page / API documentation |

## REST API Endpoints

### Posts

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /posts | GET | 200 | List all posts (100) |
| /posts | POST | 201 | Create new post |
| /posts/:id | GET | 200 | Get single post |
| /posts/:id | PUT | 200 | Update post |
| /posts/:id | PATCH | 200 | Patch post |
| /posts/:id | DELETE | 200 | Delete post |
| /posts?userId=X | GET | 200 | Filter by userId |

### Comments

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /comments | GET | 200 | List all comments (500) |
| /comments/:id | GET | 200 | Get single comment |
| /comments?postId=X | GET | 200 | Filter by postId |

### Users

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /users | GET | 200 | List all users (10) |
| /users/:id | GET | 200 | Get single user |

### Albums

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /albums | GET | 200 | List all albums (100) |
| /albums/:id | GET | 200 | Get single album |
| /albums?userId=X | GET | 200 | Filter by userId |

### Photos

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /photos | GET | 200 | List all photos (5000) |
| /photos/:id | GET | 200 | Get single photo |
| /photos?albumId=X | GET | 200 | Filter by albumId |

### Todos

| Path | Method | Status | Notes |
|------|--------|--------|-------|
| /todos | GET | 200 | List all todos (200) |
| /todos/:id | GET | 200 | Get single todo |
| /todos?userId=X | GET | 200 | Filter by userId |

## Not Found (404)

- /openapi.json
- /swagger.json
- /docs
- /api-docs
- /graphql

## Resources

- **Data Source:** json-server with db.json
- **Relationships:** posts→comments, posts→users, albums→photos, users→todos