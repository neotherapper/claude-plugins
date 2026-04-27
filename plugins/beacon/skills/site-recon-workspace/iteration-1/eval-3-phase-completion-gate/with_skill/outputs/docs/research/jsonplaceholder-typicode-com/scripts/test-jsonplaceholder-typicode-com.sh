#!/bin/bash
# Smoke test for jsonplaceholder.typicode.com

BASE_URL="https://jsonplaceholder.typicode.com"

echo "=== JSONPlaceholder Smoke Tests ==="

echo -e "\n1. GET /posts"
curl -s "$BASE_URL/posts" | head -c 200

echo -e "\n\n2. GET /posts/1"
curl -s "$BASE_URL/posts/1"

echo -e "\n\n3. POST /posts"
curl -s -X POST "$BASE_URL/posts" \
  -H "Content-Type: application/json" \
  -d '{"title":"test","body":"test body","userId":1}'

echo -e "\n\n4. PUT /posts/1"
curl -s -X PUT "$BASE_URL/posts/1" \
  -H "Content-Type: application/json" \
  -d '{"id":1,"title":"updated","body":"updated","userId":1}'

echo -e "\n\n5. DELETE /posts/1"
curl -s -X DELETE "$BASE_URL/posts/1"

echo -e "\n\n6. GET /users"
curl -s "$BASE_URL/users" | head -c 200

echo -e "\n\n7. GET /comments?postId=1"
curl -s "$BASE_URL/comments?postId=1" | head -c 200

echo -e "\n\n=== All tests complete ==="