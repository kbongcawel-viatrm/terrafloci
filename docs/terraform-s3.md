# S3 bucket module and Floci test

## Layout

- `terraform/modules/s3-bucket/` contains the reusable AWS S3 bucket module.
- `terraform/live/local/s3-bucket/terragrunt.hcl` is the Terragrunt caller and generates the AWS provider configuration for Floci.
- Terraform uses a local backend at `terraform/live/local/s3-bucket/terraform.tfstate`. Do not commit that state.

The module accepts `bucket_name` (required), `force_destroy` (defaults to `false`), and `tags` (defaults to an empty map). It exports the bucket name, ARN, and region. Bucket naming validation is intentionally a practical subset of S3's naming rules; AWS remains authoritative.

## Toolbox test

Start Floci using the repository's existing Floci Compose workflow, then run in the toolbox:

```bash
bash scripts/test-terragrunt-s3.sh
```

The script uses dummy AWS credentials, defaults to `http://localhost:4566` and `us-west-1`, creates a unique test bucket, verifies it with `aws s3api head-bucket`, and destroys it. Override `AWS_ENDPOINT_URL`, `AWS_DEFAULT_REGION`, or `TF_VAR_bucket_name` if needed. The configured provider endpoint ensures Terraform requests go to Floci, not AWS.

## GitHub Actions

`.github/workflows/terraform-floci.yml` runs on pull requests and pushes to `main`. It starts Floci on the runner, waits for its health endpoint, installs Terraform 1.16.5 and Terragrunt 1.1.6, validates, and executes the disposable integration script. No AWS account, production credentials, or persistent remote state are used. The job uses the `floci/floci:latest` image, so the Floci image itself is not version-pinned yet.

Destroy runs after a successful apply and is also attempted by the test script's exit trap after subsequent failures. If apply partially creates a bucket but exits before Terraform records a successful apply, automatic cleanup may not be complete; the CI job is isolated and disposable. Inspect workflow logs when integration tests fail.

The local Ansible playbook is not invoked on GitHub: it is specifically written to shell into the Fedora `terrafloci` Toolbox, whereas GitHub-hosted runners are Ubuntu. CI installs the equivalent Terraform/Terragrunt tools directly on the runner instead.