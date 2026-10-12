 
# ✅[DONE] Phase 1 — Build the development environment
Objective: 
Create a reproducible toolbox environment with all development tools.

# Tasks:
1. Inspect the host OS, architecture, available memory, disk space, and container runtime.
2. Verify Podman or Docker is working. Prefer Podman if it is already your host workflow; otherwise use Docker.
3. Create a dedicated development directory and Git repository.
4. Build a Toolbox image or container definition containing:
   - Terraform CLI
   - AWS CLI
   - Ansible Core
   - Git
   - curl, jq, and standard shell utilities
   - Python and ansible-lint
5. Install or expose the Floci CLI and container runtime access as appropriate.
6. Pin tool versions and document how to rebuild the environment.
7. Create a smoke-test script that prints tool versions and verifies Floci connectivity.

# Deliverables:
- Containerfile
- compose.yaml for Floci
- README.md
- .gitignore
- scripts/smoke-test.sh

Exit criteria: 
A new Toolbox session can run all tools and connect to Floci without relying on undocumented host configuration.

# ⚠️[IN PROGRES] Phase 2 — Understand Floci and AWS API behavior
Objective: 
Understand what Floci emulates, what persists, and how AWS clients communicate with it.

# Tasks:
1. Read the official Floci quick start and Terraform integration guide.
2. Start Floci and confirm port 4566 is reachable.
3. Inspect container logs, health endpoints, and startup behavior.
4. Configure dummy AWS credentials and a test region. Never use real AWS credentials for local testing.
5. Use AWS CLI to create, describe, list, and delete one simple resource, such as an S3 bucket.
6. Restart Floci and determine whether resources persist under the selected storage mode.
7. Record API errors and compare expected AWS behavior with actual Floci behavior.
8. Inspect the documented service support and identify the APIs required for VPC, IAM, EC2, and security groups.

#Deliverables:
- docs/floci-notes.md
- scripts/floci-smoke-test.sh
- A service compatibility checklist

Exit criteria: 
You can explain the request flow, endpoint configuration, persistence behavior, and the limits of your selected Floci version.

#Phase 3 — Map AWS concepts to Floci
Objective: 
Learn the AWS resource model before writing infrastructure code.

# Tasks:
Study and test each service in this order:
1. IAM: users, roles, policies, trust policies, and permissions.
2. VPC: address ranges, subnets, route tables, and gateways.
3. Security groups: inbound and outbound rules.
4. EC2: instance configuration, AMIs, key pairs, networking, and user data.
5. Connectivity: instance addresses, routes, ports, and HTTP access.
6. Observability: logs, errors, resource descriptions, and lifecycle behavior.

For every service, document:
- AWS purpose and dependencies.
- Required API operations.
- Terraform resource and data-source names.
- Floci support and any limitations.
- Expected behavior versus observed behavior.
- A CLI command that verifies the resource.
Important: Floci's EC2 implementation can use real Docker-backed execution, but that does not guarantee that every networking, IAM, or guest-operating-system behavior is identical to AWS. Test the specific capabilities you intend to use. See the Floci AWS service overview.
Deliverable: docs/aws-floci-compatibility.md.
Exit criteria: Every resource needed for the initial application has a documented support status and a verification method.


# Phase 4 — Create one Floci resource manually
Objective: 
Separate AWS API behavior from Terraform behavior.

# Tasks:
1. Start Floci and verify its endpoint.
2. Export test-only AWS credentials and region.
3. Create one S3 bucket through the AWS CLI.
4. Describe the bucket to prove it exists.
5. List buckets and verify the expected name.
6. Delete the bucket and verify removal.
7. Repeat the test after a restart if persistence matters.
8. Capture the commands, expected outputs, and cleanup procedure.

Example:
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566

aws s3api create-bucket \
  --bucket workshop-manual-test

aws s3api head-bucket \
  --bucket workshop-manual-test

aws s3api delete-bucket \
  --bucket workshop-manual-test

Run this only after starting Floci. The example assumes no other resource is using the same bucket name.

Exit criteria: 
A create → verify → delete lifecycle succeeds through the AWS API without Terraform.

# Phase 5 — Provision the first resource with Terraform
Objective: 
Manage the same resource declaratively and understand Terraform's lifecycle.

# Tasks:
1. Configure the official HashiCorp AWS provider with a Floci endpoint.
2. Use a local Terraform backend initially.
3. Create one S3 bucket using Terraform.
4. Run terraform fmt -check, terraform init, terraform validate, and terraform plan.
5. Apply the configuration and inspect the state.
6. Verify the bucket through the AWS CLI.
7. Change a tag or other supported attribute and observe the plan.
8. Run terraform plan again without changes; expect no infrastructure changes.
9. Run terraform destroy and verify deletion.

# Deliverables:
- terraform/first-resource/
- docs/terraform-lifecycle.md

Exit criteria: 
You can explain configuration, provider, plan, apply, state, drift, and destroy, and the same resource is managed successfully from start to finish.

# Phase 6 — Build a reusable Terraform module
Objective: 
Move from a one-off configuration to a reusable, testable module.

# Tasks:
1. Create a module directory with main.tf, variables.tf, and outputs.tf.
2. Add input validation and useful descriptions.
3. Expose only outputs needed by the calling configuration.
4. Separate module code from the root configuration that configures the provider.
5. Keep provider endpoint configuration in the root so the module is not tied to Floci.
6. Add a minimal example showing how to call the module.
7. Run formatting, validation, and a real plan against Floci.
8. Apply, inspect, and destroy the resource.
9. Document module inputs, outputs, prerequisites, and limitations.


Suggested initial structure:
terraform/
  modules/
    s3-bucket/
      main.tf
      variables.tf
      outputs.tf
  examples/
    floci-s3/
      main.tf
      provider.tf
      outputs.tf

Exit criteria: 
The example can instantiate the module, pass validation, create a resource in Floci, and clean it up.

# Phase 7 — Automate Terraform with GitHub Actions
Objective: 
Validate infrastructure changes automatically before merging them.

# Tasks:
1. Create a workflow triggered by pull requests and pushes to the main branch.
2. Pin Terraform and provider versions.
3. Run formatting and static validation.
4. Start Floci as a service container or separate Compose service.
5. Wait for readiness before running integration tests.
6. Run terraform plan against Floci.
7. For the integration stage, apply resources, verify them through AWS CLI, then destroy them.
8. Upload logs and test results on failure.
9. Require successful checks before merging.
10. Document the pipeline and its cleanup guarantees.

Keep the first pipeline local-only: it should need no AWS account credentials or production secrets.

Exit criteria: 
A pull request automatically passes formatting, validation, and a Floci-backed integration test; a deliberately invalid configuration fails the workflow.

# Phase 8 — Build the Hello World infrastructure
Objective: 
Create the first multi-resource Terraform deployment.

# Tasks
Build the infrastructure in dependency order:
1. VPC and subnet.
2. Internet gateway and route table, if required and supported.
3. Security group with narrowly scoped ingress and egress.
4. IAM role and instance profile, if supported and needed.
5. EC2 instance using an appropriate image or Floci-supported execution model.
6. Bootstrap the Hello World application using user data or a later Ansible step.
7. Expose an HTTP endpoint through the appropriate network path.
8. Test the application and confirm access restrictions.
9. Destroy the infrastructure and verify cleanup.
Start with one instance and one HTTP port. Do not add load balancers, autoscaling, or a complex network until the simple deployment works.

Exit criteria: 
Terraform provisions the expected resources, and an HTTP request returns the expected Hello World response through the supported Floci execution path.

# Phase 9 — Add Ansible configuration and hardening
Objective: 
Separate infrastructure provisioning from operating-system configuration.

# Tasks:
1. Determine whether the Floci EC2 execution model provides a real guest OS and SSH access.
2. If supported, generate a dynamic inventory from Terraform outputs or the AWS API.
3. Configure SSH authentication and least-privilege access.
4. Write a baseline Ansible role for package updates, time settings, and essential system configuration.
5. Apply server hardening appropriate to the selected Linux distribution.
6. Install and configure the web server and Hello World application.
7. Test idempotency by running the playbook twice.
8. Verify the application and security posture after configuration.
9. Document which hardening controls were implemented and how they were tested.
If Floci cannot provide the guest OS and SSH access you need, use a separate local container or VM for Ansible practice while keeping Terraform integration tests in Floci.

Exit criteria: 
Ansible can configure the target, a second run produces no unintended changes, and the application remains available after configuration.


```bash
terrafloci/
├── Containerfile
├── compose.yaml
├── .gitignore
├── README.md
├── docs/
│   ├── architecture.md
│   ├── environment-setup.md
│   ├── floci-notes.md
│   ├── aws-floci-compatibility.md
│   ├── terraform-lifecycle.md
│   ├── ci-cd.md
│   └── troubleshooting.md
├── scripts/
│   ├── smoke-test.sh
│   ├── floci-smoke-test.sh
│   └── verify-hello-world.sh
├── terraform/
│   ├── first-resource/
│   ├── modules/
│   │   ├── network/
│   │   ├── security/
│   │   └── compute/
│   └── environments/
│       └── local/
├── ansible/
│   ├── ansible.cfg
│   ├── inventories/
│   ├── playbooks/
│   └── roles/
│       ├── baseline/
│       └── webserver/
└── .github/
    └── workflows/
        ├── validate.yml
        └── integration.yml
```
