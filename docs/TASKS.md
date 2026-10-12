Terraform + Floci: Local AWS Workshop Roadmap
The objective is to build a repeatable, local AWS-like development environment where you can learn AWS concepts, provision infrastructure with Terraform, automate validation with GitHub Actions, deploy a Hello World application, and manage server configuration with Ansible.
The best approach is to progress from manual experimentation → Terraform modules → automated CI/CD → application deployment → configuration hardening. Each phase should produce a working result before you move to the next.
1. Target architecture
Development workstation
Linux + Toolbox container + Git


Local development services
Terraform
Provisioning and state


Floci
Local AWS API emulation


GitHub Actions
CI/CD and validation


Ansible
Configuration and hardening





Simulated AWS infrastructure
VPC / networking


Security groups


IAM


EC2 / compute




Hello World application
HTTP endpoint + automated verification



One important distinction: Floci is a local AWS emulation environment, not the AWS cloud itself. Which AWS APIs and Terraform resources work depends on the Floci version, its implemented services, and the Terraform provider's API behavior. In particular, successful Terraform resource creation does not automatically mean that an actual EC2 guest operating system has booted or that Ansible can connect to it.
We will verify those capabilities before building on them.
2. Phase-by-phase implementation plan
Suggested order: complete each phase's exit criteria before advancing. The time estimates are planning estimates, not fixed deadlines.

Phase 1 — Build the development environment
Foundation
1–2 days

Objective: Create a reproducible toolbox environment with all development tools.
Tasks:
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
Deliverables:
- Containerfile
- compose.yaml for Floci
- README.md
- .gitignore
- scripts/smoke-test.sh
Exit criteria: A new Toolbox session can run all tools and connect to Floci without relying on undocumented host configuration.




Phase 2 — Understand Floci and AWS API behavior
Manual learning
2–3 days

Objective: Understand what Floci emulates, what persists, and how AWS clients communicate with it.
Tasks:
1. Read the official Floci quick start and Terraform integration guide.
2. Start Floci and confirm port 4566 is reachable.
3. Inspect container logs, health endpoints, and startup behavior.
4. Configure dummy AWS credentials and a test region. Never use real AWS credentials for local testing.
5. Use AWS CLI to create, describe, list, and delete one simple resource, such as an S3 bucket.
6. Restart Floci and determine whether resources persist under the selected storage mode.
7. Record API errors and compare expected AWS behavior with actual Floci behavior.
8. Inspect the documented service support and identify the APIs required for VPC, IAM, EC2, and security groups.
Deliverables:
- docs/floci-notes.md
- scripts/floci-smoke-test.sh
- A service compatibility checklist
Exit criteria: You can explain the request flow, endpoint configuration, persistence behavior, and the limits of your selected Floci version.




Phase 3 — Map AWS concepts to Floci
Service discovery
2–3 days

Objective: Learn the AWS resource model before writing infrastructure code.
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




Phase 4 — Create one Floci resource manually
Hands-on lab
0.5–1 day

Objective: Separate AWS API behavior from Terraform behavior.
Tasks:
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
Exit criteria: A create → verify → delete lifecycle succeeds through the AWS API without Terraform.




Phase 5 — Provision the first resource with Terraform
First IaC
1–2 days

Objective: Manage the same resource declaratively and understand Terraform's lifecycle.
Tasks:
1. Configure the official HashiCorp AWS provider with a Floci endpoint.
2. Use a local Terraform backend initially.
3. Create one S3 bucket using Terraform.
4. Run terraform fmt -check, terraform init, terraform validate, and terraform plan.
5. Apply the configuration and inspect the state.
6. Verify the bucket through the AWS CLI.
7. Change a tag or other supported attribute and observe the plan.
8. Run terraform plan again without changes; expect no infrastructure changes.
9. Run terraform destroy and verify deletion.
Deliverables:
- terraform/first-resource/
- docs/terraform-lifecycle.md
Exit criteria: You can explain configuration, provider, plan, apply, state, drift, and destroy, and the same resource is managed successfully from start to finish.




Phase 6 — Build a reusable Terraform module
Reusable IaC
2–4 days

Objective: Move from a one-off configuration to a reusable, testable module.
Tasks:
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


Exit criteria: The example can instantiate the module, pass validation, create a resource in Floci, and clean it up.




Phase 7 — Automate Terraform with GitHub Actions
CI/CD
2–3 days

Objective: Validate infrastructure changes automatically before merging them.
Tasks:
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
Exit criteria: A pull request automatically passes formatting, validation, and a Floci-backed integration test; a deliberately invalid configuration fails the workflow.




Phase 8 — Build the Hello World infrastructure
Full infrastructure
3–5 days

Objective: Create the first multi-resource Terraform deployment.
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
Exit criteria: Terraform provisions the expected resources, and an HTTP request returns the expected Hello World response through the supported Floci execution path.




Phase 9 — Add Ansible configuration and hardening
Configuration management
2–4 days

Objective: Separate infrastructure provisioning from operating-system configuration.
Tasks:
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
Exit criteria: Ansible can configure the target, a second run produces no unintended changes, and the application remains available after configuration.



3. Recommended repository structure
Use one repository for the workshop initially. This makes it easier to understand how the container environment, Terraform code, CI/CD, and Ansible playbooks work together.
terraform-floci-workshop/
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


Create the directories gradually. Do not build every module or playbook at the beginning.
The recommended Terraform module layout follows HashiCorp's standard structure, with resource definitions, inputs, outputs, examples, and documentation. 

HashiCorp Developer
+1



4. CI/CD design: build the pipeline in stages
Use three levels of validation rather than starting with a complicated deployment workflow.

Stage 1 — Static validation
Runs on every pull request.
- terraform fmt -check -recursive
- terraform init -backend=false
- terraform validate
- ansible-lint when Ansible code exists
- ShellCheck when shell scripts exist
No resources should be created in this stage.




Stage 2 — Floci integration tests
Runs after static validation.
- Start Floci in a container.
- Wait for the endpoint to become ready.
- Run terraform plan.
- Apply a disposable test configuration.
- Verify the resulting resources through the AWS CLI.
- Destroy the resources even if verification fails.
- Collect logs when the test fails.
This stage proves the configuration can interact with Floci, rather than merely being syntactically correct.




Stage 3 — Application deployment test
Introduced when the Hello World stack works.
- Provision the networking and compute resources.
- Install or start the application.
- Request the HTTP endpoint.
- Assert that the response contains Hello World.
- Run the Ansible idempotency test.
- Clean up the test environment.
Keep integration tests isolated from persistent state used by other runs.



Terraform's validate command checks configuration consistency, but it does not prove that the remote service or provider API works. That is why the second stage is necessary. 

HashiCorp Developer
+1



Important CI detail: A GitHub-hosted runner's localhost is not your personal workstation. Run Floci inside the job or use an explicitly configured runner and network. For the first implementation, a service container or a Compose-based job on a suitable runner is preferable to depending on your home development machine.
5. Testing standards for every change
Use a consistent pass/fail checklist. Before every commit and push, run the checks appropriate to the change.
Pre-commit checklist
0/15



Environment
[ ] Tool versions can be displayed
[ ] Floci endpoint is reachable
[ ] Smoke test passes

Terraform
[ ] Formatting passes
[ ] Initialization and validation pass
[ ] Plan matches the intended change
[ ] Apply and resource verification pass
[ ] Destroy and cleanup pass

Application
[ ] HTTP request returns the expected response
[ ] Security group permits only intended access
[ ] Ansible playbook succeeds twice

Repository
[ ] Documentation updated
[ ] No secrets or state files staged
[ ] Git diff reviewed
[ ] Commit message describes the change

ResetCopy checklist

The checklist is a tracking aid, not an automatic test runner. Only mark a check complete after executing it and observing the result.
Also add these repository protections:
- Ignore .terraform/, *.tfstate, *.tfstate.*, and local secrets.
- Commit .terraform.lock.hcl for reproducible provider selection.
- Keep test credentials local and dummy-only.
- Avoid broad ingress rules such as unrestricted SSH.
- Use least-privilege GitHub token permissions.
- Make CI cleanup reliable, and use disposable resource names.
6. Additional work: Ansible and server hardening
Treat Ansible as a separate configuration layer. Terraform creates the infrastructure; Ansible configures the operating system and application.
Area	Tasks	Verification
Access	SSH keys, users, privilege escalation	Intended user can connect
Packages	Updates and required packages	Expected package versions
SSH	Disable root login and password login where appropriate	Effective SSH configuration
Firewall	Restrict management and application ports	Only intended connections work
Web server	Install and configure Nginx or Apache	HTTP response succeeds
Service management	Enable and start services	Service survives restart
Idempotency	Repeat the same playbook	No unintended changes on the second run
Documentation	Record implemented controls	Another person can reproduce the setup
Do not assume that an emulated EC2 resource provides a normal Linux host. Confirm guest execution, SSH connectivity, and networking before integrating Ansible with Terraform outputs.
7. Later extension: agentic engineering
Once the manual workflow and CI/CD pipeline are stable, introduce specialized agents. Each agent should have a limited scope, explicit rules, and tests.
Workshop coordinator
Assigns tasks, checks dependencies, and summarizes test results


Terraform agent
Modules, plans, validation, state safety


AWS agent
Service concepts, IAM, API compatibility


Floci agent
Local service behavior, logs, reproduction


Ansible agent
Playbooks, idempotency, hardening


Container agent
Toolbox, Podman/Docker, images, networking and volumes




For each agent, eventually create:
- A SKILL.md describing its responsibilities and workflow.
- Rules that define what it must not change.
- Official documentation references.
- Reusable scripts and test cases.
- A standard report containing PASS or FAIL, test output, and unresolved issues.
Begin with advisory agents that propose changes and run safe checks. Require human approval for destructive operations, pushes, and deployment actions.
8. Milestones and final acceptance criteria
Use these milestones to track the entire workshop.
Workshop progress
0 of 8

[ ] M1 — Development environment
Reproducible Toolbox environment; tools and Floci connectivity verified.


[ ] M2 — Floci fundamentals
Manual AWS CLI lifecycle works; supported services and limitations documented.


[ ] M3 — First Terraform resource
Terraform provisions, verifies, and destroys one resource.


[ ] M4 — Reusable module
Module is documented, validated, and instantiated through a root configuration.


[ ] M5 — Terraform CI/CD
Pull requests run static and Floci-backed integration checks.


[ ] M6 — Hello World
Terraform provisions the supported infrastructure and an HTTP test passes.


[ ] M7 — Ansible hardening
Configuration and hardening run successfully and idempotently.


[ ] M8 — Agentic engineering
Specialized agents follow documented scopes and report verified results.


Copy milestone report
Recommended immediate next step
Start with Phase 1 only. Before creating any Terraform module, establish the container runtime, Toolbox environment, and Floci endpoint. Then test the environment with one smoke test.
Official references to keep nearby:
- Floci documentation
- Floci with Terraform
- Terraform module development
- Terraform validation
- GitHub Actions documentation
- Ansible documentation
This sequence ensures that each layer is understood and tested before the next one depends on it.
