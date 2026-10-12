# terrafloci

A local workshop for learning AWS infrastructure concepts with Terraform and Floci, using Ansible for configuration management and GitHub Actions for CI/CD.

## Workspace environment

| Component | Selection | Purpose |
|---|---|---|
| Host OS | Fedora Secureblue 44 (immutable) | Development workstation |
| Development environment | Toolbox: `terrafloci` | Isolated CLI development environment |
| Container host | Podman | Runs Floci and supporting services |
| Infrastructure as Code | Terraform | Declares and manages infrastructure |
| AWS API / emulation | Floci | Local AWS-compatible API environment |
| Configuration management | Ansible | Configures and hardens supported Linux targets |
| Source control | Git | Version history and collaboration |
| CI/CD | GitHub Actions | Automated validation and integration tests |

> **Scope:** This is a local learning environment, not an AWS production environment. Floci's support for individual AWS APIs and EC2 guest execution must be verified against the selected version. A successful Terraform apply does not by itself prove an application is reachable or that Ansible can SSH into an instance.

## Learning goals

1. Build a reproducible Toolbox development environment.
2. Learn Floci startup, endpoints, logs, service support, and persistence behavior.
3. Create and verify one resource manually through the AWS CLI.
4. Manage the resource through Terraform, including plan, apply, state, and destroy.
5. Build reusable Terraform modules and validate them in GitHub Actions.
6. Build a Hello World stack using supported networking, IAM, security group, and compute functionality.
7. Use Ansible to configure and harden a supported Linux target.
8. Document and test each change before committing or pushing.

## Suggested repository layout

```text
terrafloci/
├── Containerfile
├── compose.yaml
├── README.md
├── docs/
├── scripts/
├── terraform/
│   ├── first-resource/
│   ├── modules/
│   └── environments/
│       └── local/
├── ansible/
│   ├── inventories/
│   ├── playbooks/
│   └── roles/
└── .github/
    └── workflows/
```

Add directories as each phase begins; avoid scaffolding unused modules prematurely.

## Initial setup

### 1. Create the Toolbox

On Fedora Secureblue, use the host's supported Toolbox workflow rather than installing development tools into the immutable host.

```bash
toolbox create --container terrafloci
toolbox enter terrafloci
```

If the container already exists, enter it rather than trying to create it again.

### 2. Check the available tools

Inside the Toolbox, inspect what is already installed:

```bash
git --version
terraform version
aws --version
ansible --version
podman --version
```

Some tools may not yet be installed. Record and pin versions in the environment setup documentation as the workspace is built. Podman is normally managed from the host; access to the Podman socket or host CLI from inside Toolbox should be configured deliberately rather than assumed.

### 3. Start Floci

Use the official Floci documentation for the current recommended container image, configuration, ports, and persistence options:

- [Floci documentation](https://floci.io/)
- [Floci Terraform integration](https://floci.io/floci/getting-started/terraform/)
- [Floci project on GitHub](https://github.com/floci-io/floci)

Do not assume a port, image tag, or service feature without verifying it against the version used. Once started, verify the documented endpoint and review container logs.

### 4. Use test-only AWS credentials for local emulation

Never reuse real AWS access keys for local testing. Configure dummy credentials and a test region as required by the chosen Floci setup. Use the endpoint variable only after verifying the endpoint URL for the running service.

Example environment values (adjust the endpoint if needed):

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
```

Keep local environment files, credentials, and Terraform state out of Git.

## Terraform workflow

For each Terraform change, run the relevant checks in order:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Only apply after reviewing the plan and confirming the target provider endpoint is local. After applying, verify the resource through the AWS CLI or the service's supported inspection method. Use `terraform destroy` for disposable labs and confirm cleanup.

Commit `.terraform.lock.hcl` for reproducible provider selection. Do not commit `.terraform/`, Terraform state, credentials, or secrets.

## CI/CD approach

GitHub Actions should grow in stages:

1. **Static validation:** formatting, initialization, validation, and linting.
2. **Floci integration:** start Floci, wait for readiness, apply a disposable test configuration, verify resources, and clean up.
3. **Application test:** provision supported infrastructure, check the Hello World HTTP response, test Ansible idempotency, and clean up.

Hosted GitHub runners do not share the workstation's `localhost`. Run Floci as part of the CI job or deliberately configure a suitable self-hosted runner and network. Keep the initial pipeline local-only and avoid real AWS credentials.

## Ansible approach

Before targeting an emulated EC2 instance, confirm that the chosen Floci execution mode provides a guest OS and SSH connectivity. If not, practise Ansible against a dedicated local VM or container while keeping Terraform API integration tests in Floci.

Run configuration playbooks twice as an idempotency check. Document the controls applied and how each was verified.

## Commit and push checklist

- [ ] Run formatting and validation relevant to the change.
- [ ] Run at least one targeted test case.
- [ ] Confirm tests report **PASS** or **FAIL** and capture failures.
- [ ] Review `git diff` and `git status`.
- [ ] Confirm no credentials, local `.env` files, or Terraform state are staged.
- [ ] Update the README or relevant documentation.
- [ ] Commit only after the checks pass.

## References

- [Fedora Toolbox documentation](https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/)
- [Podman documentation](https://docs.podman.io/)
- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Floci documentation](https://floci.io/)
- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Ansible documentation](https://docs.ansible.com/)
