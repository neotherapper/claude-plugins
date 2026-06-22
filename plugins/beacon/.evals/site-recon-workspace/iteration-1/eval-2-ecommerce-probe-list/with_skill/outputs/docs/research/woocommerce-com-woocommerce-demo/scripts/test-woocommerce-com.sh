#!/bin/bash
# Test script for woocommerce.com Store API

BASE_URL="https://woocommerce.com"

echo "=== WooCommerce Store API Tests ==="

echo -e "\n--- Products API ---"
curl -s "${BASE_URL}/wp-json/wc/store/v1/products?per_page=2" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{p[\"id\"]}: {p[\"name\"]} - {p[\"prices\"][\"currency_code\"]}{p[\"prices\"][\"price\"]}') for p in d]"

echo -e "\n--- Categories API ---"
curl -s "${BASE_URL}/wp-json/wc/store/v1/products/categories?per_page=5" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(c['name']) for c in d]"

echo -e "\n--- Tags API ---"
curl -s "${BASE_URL}/wp-json/wc/store/v1/products/tags?per_page=5" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(t['name']) for t in d]"

echo -e "\n--- Collection Data API ---"
curl -s "${BASE_URL}/wp-json/wc/store/v1/products/collection-data" | python3 -m json.tool

echo -e "\n--- Cart Fragments AJAX ---"
curl -s "${BASE_URL}/?wc-ajax=get_refreshed_fragments" | python3 -c "import sys,json; d=json.load(sys.stdin); print('cart_hash:', d.get('cart_hash'))"

echo -e "\n=== Tests Complete ==="