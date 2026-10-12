#!/usr/bin/env bash

set -euo pipefail

# Configuration
AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-1}"

ENDPOINT="$AWS_ENDPOINT_URL"
REGION="$AWS_DEFAULT_REGION"
BUCKET="terrafloci-test-$(date +%s)-$$"
BUCKET_CREATED=false

# Dummy credentials for local testing only
export AWS_ACCESS_KEY_ID="dummy_id"
export AWS_SECRET_ACCESS_KEY="dummy_key"
export AWS_DEFAULT_REGION="$REGION"
export AWS_EC2_METADATA_DISABLED=true
export AWS_PAGER=""

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
NC=$'\033[0m'

pass() {
    printf '%sPASS%s: %s\n' "$GREEN" "$NC" "$1"
}

fail() {
    printf '%sFAIL%s: %s\n' "$RED" "$NC" "$1" >&2
    exit 1
}

cleanup() {
    if [[ "$BUCKET_CREATED" == true ]]; then
        aws s3api delete-bucket \
            --bucket "$BUCKET" \
            --endpoint-url "$ENDPOINT" \
            >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# 1. Check dependencies
command -v curl >/dev/null 2>&1 ||
    fail "curl is not installed"

command -v aws >/dev/null 2>&1 ||
    fail "AWS CLI is not installed"

pass "Required commands are installed"

# 2. Check endpoint connectivity
if ! curl --silent --show-error \
    --output /dev/null \
    --max-time 5 \
    "$ENDPOINT"; then
    fail "Floci endpoint is unreachable: $ENDPOINT"
fi

pass "Floci endpoint is reachable"

# 3. Check the S3 API
if ! aws s3api list-buckets \
    --endpoint-url "$ENDPOINT" \
    >/dev/null; then
    fail "S3 ListBuckets API request failed"
fi

pass "S3 ListBuckets API works"

# 4. Create a test bucket
if [[ "$REGION" == "us-east-1" ]]; then
    if ! aws s3api create-bucket \
        --bucket "$BUCKET" \
        --endpoint-url "$ENDPOINT" \
        >/dev/null; then
        fail "CreateBucket API request failed"
    fi
else
    if ! aws s3api create-bucket \
        --bucket "$BUCKET" \
        --endpoint-url "$ENDPOINT" \
        --create-bucket-configuration \
        "LocationConstraint=$REGION" \
        >/dev/null; then
        fail "CreateBucket API request failed"
    fi
fi

BUCKET_CREATED=true
pass "S3 bucket creation works"

# 5. Verify the bucket exists
if ! aws s3api head-bucket \
    --bucket "$BUCKET" \
    --endpoint-url "$ENDPOINT"; then
    fail "Bucket verification failed"
fi

pass "Bucket verification works"

# 6. Verify the bucket appears in the listing
if ! aws s3api list-buckets \
    --endpoint-url "$ENDPOINT" \
    --query "Buckets[?Name=='$BUCKET'].Name" \
    --output text |
    grep -Fxq "$BUCKET"; then
    fail "Bucket was not found in ListBuckets"
fi

pass "Bucket listing works"

# 7. Delete the test bucket
if ! aws s3api delete-bucket \
    --bucket "$BUCKET" \
    --endpoint-url "$ENDPOINT" \
    >/dev/null; then
    fail "DeleteBucket API request failed"
fi

BUCKET_CREATED=false
pass "Bucket deletion works"

printf '\n%sPASS%s: Floci smoke test completed successfully\n' \
    "$GREEN" "$NC"
