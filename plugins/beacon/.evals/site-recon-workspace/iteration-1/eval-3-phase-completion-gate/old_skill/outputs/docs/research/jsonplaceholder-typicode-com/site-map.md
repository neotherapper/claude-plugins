# Site Map — jsonplaceholder.typicode.com

## Root

- `https://jsonplaceholder.typicode.com/` — Main page (HTML)

## API Endpoints

### Posts
- `GET /posts` — List all posts
- `GET /posts/{id}` — Get single post
- `POST /posts` — Create post
- `PUT /posts/{id}` — Update post
- `PATCH /posts/{id}` — Patch post
- `DELETE /posts/{id}` — Delete post

### Users
- `GET /users` — List all users
- `GET /users/{id}` — Get single user

### Comments
- `GET /comments` — List all comments
- `GET /comments/{id}` — Get single comment
- `GET /posts/{id}/comments` — Get comments for a post

### Albums
- `GET /albums` — List all albums
- `GET /albums/{id}` — Get single album

### Photos
- `GET /photos` — List all photos
- `GET /photos/{id}` — Get single photo

### Todos
- `GET /todos` — List all todos
- `GET /todos/{id}` — Get single todo

### Nested Resources
- `GET /users/{id}/posts` — Posts by user
- `GET /albums/{id}/photos` — Photos in album

### Filtering
- `GET /posts?userId={id}` — Filter by user
- `GET /comments?postId={id}` — Filter by post
- `GET /todos?userId={id}` — Filter by user
- `GET /albums?userId={id}` — Filter by user

## Static Assets

- `/style.css` — Tailwind CSS

## Not Found (404)

- `/sitemap.xml` — No sitemap
- `/openapi.json` — No OpenAPI spec
- `/swagger.json` — No Swagger spec
- `/graphql` — No GraphQL endpoint