#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_DIR="$ROOT_DIR/terraform/live/local/s3-bucket"
REGION="${AWS_DEFAULT_REGION:-us-west-1}"
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
BUCKET="${TF_VAR_bucket_name:-terrafloci-test-$(date +%s)-$$}"
APPLIED=false

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="$REGION"
export AWS_EC2_METADATA_DISABLED=true
export AWS_PAGER=""
export AWS_ENDPOINT_URL="$ENDPOINT"
export TF_VAR_bucket_name="$BUCKET"

cleanup() {
  local status=$?
  if [[ "$APPLIED" == true ]]; then
    (cd "$UNIT_DIR" && terragrunt run --non-interactive -- destroy -auto-approve) || status=$?
  fi
  exit "$status"
}
trap cleanup EXIT

command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 127; }
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 127; }
command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 127; }
curl --fail --silent --show-error --max-time 5 "$ENDPOINT" >/dev/null

terraform -chdir="$ROOT_DIR/terraform/modules/s3-bucket" fmt -check -recursive
(
  cd "$UNIT_DIR"
  terragrunt run --non-interactive -- init -input=false
  terragrunt run --non-interactive -- validate
  terragrunt run --non-interactive -- plan -input=false -out=tfplan
  terragrunt run --non-interactive -- apply -input=false -auto-approve tfplan
)
APPLIED=true

aws s3api head-bucket --bucket "$BUCKET" --endpoint-url "$ENDPOINT"
printf 'PASS: Terragrunt created and AWS CLI verified bucket %s at %s\n' "$BUCKET" "$ENDPOINT"

(cd "$UNIT_DIR" && terragrunt run --non-interactive -- destroy -input=false -auto-approve)
APPLIED=false
printf 'PASS: Terragrunt destroyed bucket %s\n' "$BUCKET"