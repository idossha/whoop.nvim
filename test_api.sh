#!/bin/bash

# Whoop API v2 Test Script
# This script tests the Whoop API endpoints using curl

# Configuration - replace these with your actual values
ACCESS_TOKEN="${WHOOP_ACCESS_TOKEN:-}"
API_BASE="https://api.prod.whoop.com/developer"

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: WHOOP_ACCESS_TOKEN environment variable not set"
    echo ""
    echo "To get your access token:"
    echo "1. Look in ~/.local/share/nvim/whoop/tokens.json (or your OS equivalent)"
    echo "2. Copy the access_token value"
    echo "3. Run: export WHOOP_ACCESS_TOKEN='your_token_here'"
    echo "4. Run this script again"
    echo ""
    echo "Current tokens.json content:"
    cat ~/.local/share/nvim/whoop/tokens.json 2>/dev/null || echo "File not found"
    exit 1
fi

echo "Using access token: ${ACCESS_TOKEN:0:20}... (length: ${#ACCESS_TOKEN})"

echo "Testing Whoop API v2..."
echo "API Base: $API_BASE"
echo ""

# Test 1: Profile endpoint
echo "Test 1: Profile endpoint"
echo "GET $API_BASE/v2/user/profile/basic"
PROFILE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$API_BASE/v2/user/profile/basic")
PROFILE_HTTP_CODE=$(echo "$PROFILE_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
PROFILE_BODY=$(echo "$PROFILE_RESPONSE" | sed '/HTTP_CODE:/d')
echo "Status: $PROFILE_HTTP_CODE"
if [ "$PROFILE_HTTP_CODE" = "200" ]; then
    echo "✓ Profile endpoint working"
    echo "Response: $PROFILE_BODY"
else
    echo "✗ Profile endpoint failed"
    echo "Response: $PROFILE_BODY"
fi
echo ""

# Test 2: Recovery endpoint
echo "Test 2: Recovery endpoint"
END_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_DATE=$(date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ")
echo "Date range: $START_DATE to $END_DATE"
URL="$API_BASE/v2/recovery?start=$(echo "$START_DATE" | sed 's/:/%3A/g')&end=$(echo "$END_DATE" | sed 's/:/%3A/g')"
echo "GET $URL"
RECOVERY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$URL")
RECOVERY_HTTP_CODE=$(echo "$RECOVERY_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RECOVERY_BODY=$(echo "$RECOVERY_RESPONSE" | sed '/HTTP_CODE:/d')
echo "Status: $RECOVERY_HTTP_CODE"
if [ "$RECOVERY_HTTP_CODE" = "200" ]; then
    echo "✓ Recovery endpoint working"
    RECORDS=$(echo "$RECOVERY_BODY" | grep -o '"records"' | wc -l)
    echo "Records found"
else
    echo "✗ Recovery endpoint failed"
    echo "Response: $RECOVERY_BODY"
fi
echo ""

# Test 3: Sleep endpoint
echo "Test 3: Sleep endpoint"
URL="$API_BASE/v2/activity/sleep?start=$(echo "$START_DATE" | sed 's/:/%3A/g')&end=$(echo "$END_DATE" | sed 's/:/%3A/g')"
echo "GET $URL"
SLEEP_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$URL")
SLEEP_HTTP_CODE=$(echo "$SLEEP_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Status: $SLEEP_HTTP_CODE"
if [ "$SLEEP_HTTP_CODE" = "200" ]; then
    echo "✓ Sleep endpoint working"
else
    echo "✗ Sleep endpoint failed"
fi
echo ""

# Test 4: Workout endpoint
echo "Test 4: Workout endpoint"
URL="$API_BASE/v2/activity/workout?start=$(echo "$START_DATE" | sed 's/:/%3A/g')&end=$(echo "$END_DATE" | sed 's/:/%3A/g')"
echo "GET $URL"
WORKOUT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$URL")
WORKOUT_HTTP_CODE=$(echo "$WORKOUT_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Status: $WORKOUT_HTTP_CODE"
if [ "$WORKOUT_HTTP_CODE" = "200" ]; then
    echo "✓ Workout endpoint working"
else
    echo "✗ Workout endpoint failed"
fi
echo ""

echo "=================================="
echo "Test Summary:"
echo "=================================="
[ "$PROFILE_HTTP_CODE" = "200" ] && echo "✓ Profile" || echo "✗ Profile"
[ "$RECOVERY_HTTP_CODE" = "200" ] && echo "✓ Recovery" || echo "✗ Recovery"
[ "$SLEEP_HTTP_CODE" = "200" ] && echo "✓ Sleep" || echo "✗ Sleep"
[ "$WORKOUT_HTTP_CODE" = "200" ] && echo "✓ Workout" || echo "✗ Workout"
