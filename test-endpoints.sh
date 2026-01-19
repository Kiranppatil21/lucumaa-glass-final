#!/usr/bin/env bash
# Test all endpoints after deployment to verify they work

BASE_URL="https://lucumaaglass.in"

echo "🧪 Testing Glass ERP Endpoints..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
passed_count=0
failed_count=0

function test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local method="${4:-GET}"
    local data="${5:-}"
    
    test_count=$((test_count + 1))
    
    echo -n "Testing $name... "
    
    if [ -z "$data" ]; then
        response_code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url")
    else
        response_code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    if [ "$response_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $response_code)"
        passed_count=$((passed_count + 1))
    else
        echo -e "${RED}❌ FAIL${NC} (Expected $expected_status, got $response_code)"
        failed_count=$((failed_count + 1))
    fi
}

echo "📡 Testing Core Endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test health endpoint
test_endpoint "Health Check" "$BASE_URL/health" "200"

# Test API health
test_endpoint "API Health" "$BASE_URL/api/health" "200"

echo ""
echo "🔐 Testing Authentication Endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test login endpoint structure (should return 400 for empty body, not 404)
test_endpoint "Login Endpoint" "$BASE_URL/api/auth/login" "422" "POST" "{}"

# Test register endpoint structure
test_endpoint "Register Endpoint" "$BASE_URL/api/auth/register" "422" "POST" "{}"

# Test forgot password endpoint
test_endpoint "Forgot Password" "$BASE_URL/api/auth/forgot-password" "422" "POST" "{}"

echo ""
echo "📦 Testing Order Endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test order tracking endpoint (404 is OK - means endpoint exists but order not found)
test_endpoint "Order Tracking" "$BASE_URL/api/erp/customer/orders/TEST-123/track" "404"

echo ""
echo "🔧 Testing Job Work Endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test labour rates (public endpoint)
test_endpoint "Labour Rates" "$BASE_URL/api/erp/job-work/labour-rates" "200"

# Test job work calculation endpoint
test_endpoint "Job Work Calculate" "$BASE_URL/api/erp/job-work/calculate" "422" "POST" "{}"

echo ""
echo "🎨 Testing 3D Configurator Endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test glass pricing
test_endpoint "Glass Pricing" "$BASE_URL/api/glass-configurator/pricing" "200"

# Test glass types
test_endpoint "Glass Types" "$BASE_URL/api/glass-configurator/glass-types" "200"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total Tests: $test_count"
echo -e "${GREEN}Passed: $passed_count${NC}"
echo -e "${RED}Failed: $failed_count${NC}"
echo ""

if [ $failed_count -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
