#!/bin/bash
# Test order creation with email on VPS

echo "🧪 Testing order creation with email..."

# Get token
TOKEN=$(ssh root@147.79.104.84 'curl -s -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"admin@lucumaaglass.in\",\"password\":\"admin123\"}" | python3 -c "import sys, json; print(json.load(sys.stdin)[\"token\"])"' 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get auth token"
    exit 1
fi

echo "✅ Got auth token"

# Create order
ssh root@147.79.104.84 "curl -s -X POST http://localhost:8000/api/orders/with-design \
  -H \"Authorization: Bearer $TOKEN\" \
  -H \"Content-Type: application/json\" \
  -d '{
    \"customer_name\": \"Email Test\",
    \"customer_email\": \"kiranpatil86@gmail.com\",
    \"customer_phone\": \"9876543210\",
    \"glass_config\": {
      \"width_mm\": 1000,
      \"height_mm\": 800,
      \"thickness_mm\": 6,
      \"glass_type\": \"tempered\",
      \"color_name\": \"clear\",
      \"application\": \"door\",
      \"cutouts\": [
        {\"type\": \"Heart\", \"shape\": \"heart\", \"x\": 300, \"y\": 300, \"diameter\": 100},
        {\"type\": \"Star\", \"shape\": \"star\", \"x\": 600, \"y\": 300, \"diameter\": 100},
        {\"type\": \"Hole\", \"shape\": \"circle\", \"x\": 450, \"y\": 550, \"diameter\": 80}
      ]
    },
    \"quantity\": 1,
    \"notes\": \"Test with email PDF\"
  }' | python3 -m json.tool"

echo ""
echo "⏳ Waiting 5 seconds for email to be sent..."
sleep 5

echo ""
echo "📧 Checking email logs..."
ssh root@147.79.104.84 "tail -50 /tmp/backend.log | grep -i 'email\|sent' | tail -5"

echo ""
echo "✅ Order created! Check email: kiranpatil86@gmail.com for confirmation with PDF"
