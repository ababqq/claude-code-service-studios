---
paths:
  - "infra/**"
  - "**/*.tf"
  - "**/k8s/**"
  - "**/helm/**"
  - "**/Dockerfile*"
  - ".github/workflows/**"
---

# Infrastructure Code Rules

These paths define where the product runs and how it gets there: infrastructure as code (Terraform, Pulumi),
Kubernetes manifests and Helm charts, container images and CI/CD workflows. The cloud root is
`stack.layers.cloud.root`; the provider and IaC tool are ADR decisions recorded in `stack.layers.cloud`. The
`devops-engineer` agent owns pipelines and environments, `cloud-specialist` owns provider idioms and cost, and
`sre-engineer` owns what gets alerted on.

## No secrets

- No credential, token, password, private key or connection string with a password appears in `.tf`, committed
  `.tfvars`, Helm values, Kubernetes manifests, Dockerfiles or workflow files. Reference the secret manager (AWS
  Secrets Manager or SSM Parameter Store, GCP Secret Manager, Azure Key Vault, Vault) and inject at runtime —
  External Secrets Operator, sealed or SOPS-encrypted secrets in Git. A Kubernetes `Secret` in plain YAML is
  base64, not encryption.
- CI authenticates to the cloud with OIDC federation (`id-token: write`, a role scoped to the repository and
  environment), not long-lived access keys stored as repository secrets.
- Docker build secrets use BuildKit secret mounts (`RUN --mount=type=secret,...`); `ARG` and `ENV` values are baked
  into image layers and history.
- Terraform state holds secrets in plain text: a remote backend with encryption, locking and restricted access —
  never a committed `*.tfstate`. Sensitive variables and outputs are marked `sensitive = true`.
- The `validate-commit` hook blocks known key formats and credential files; that is a backstop, not the policy.

## Least privilege

- IAM policies name the actions and resources a workload needs; `"Action": "*"` or `"Resource": "*"` needs a written
  reason in the PR. One role per service and per environment; production roles are not assumable from non-production
  workloads.
- CI roles are split: a read-only role for plan on pull requests, an apply role usable only from the protected
  branch and a protected environment with required reviewers.
- Networks are private by default: databases, caches and queues have no public endpoint and accept traffic only
  from the security groups or namespaces that need it — never `0.0.0.0/0` to a data port. Object storage blocks
  public access unless the ADR says a bucket serves public assets. Encryption at rest and TLS in transit are on.
- Kubernetes workloads: namespaced RBAC (never `cluster-admin` for an application), `runAsNonRoot`,
  `readOnlyRootFilesystem`, all capabilities dropped, no privileged containers or host mounts, resource requests
  and limits set, default-deny NetworkPolicies with explicit allows.
- Images: minimal base images pinned by digest, multi-stage builds, a non-root `USER`, no package-manager caches or
  build tools in the runtime stage; scanned in CI.
- GitHub Actions: a top-level `permissions:` of `contents: read`, widened per job only as needed; every action
  pinned to a full commit SHA; untrusted input (`github.event.*` titles, branch names, comments) passed through
  `env:`, never interpolated into `run:`; no `pull_request_target` workflow that checks out and runs pull-request
  code; `timeout-minutes` on every job.

## Plan before apply — and agents never apply

- Every change produces a reviewed plan attached to the pull request: `terraform plan -out`, `pulumi preview`,
  `helm diff` or `helm template`, `kubectl diff`. Apply runs only in the pipeline, from the merged commit, using the
  plan that was reviewed.
- A plan that destroys or replaces a stateful resource (database, bucket, volume, queue, DNS zone) is called out in
  the PR description and needs explicit approval; stateful resources carry `prevent_destroy` (or the tool's
  equivalent), deletion protection, automated backups or point-in-time recovery, and a restore that has been tested.
- **Agents write IaC and run only local, read-only commands** (`terraform fmt -check`, `terraform validate`,
  `tflint`, `helm lint`, `kubeconform`, `hadolint`, `actionlint`, config scanners such as Checkov or Trivy). Agents
  never run `apply`, `destroy`, `up`, `helm install|upgrade|uninstall`, `kubectl apply|delete` or production
  deploys — they write the command for a human to run. `infra_changes` and `production_deploys` are always-ask
  categories (`.claude/docs/automation-modes.md`), and the settings deny list blocks those commands as a backstop.
- Versions are pinned: the IaC tool version matches `stack.layers.cloud.iac` and `docs/stack-reference/VERSION.md`;
  providers and modules have version constraints and the dependency lock file (`.terraform.lock.hcl`) is committed;
  Helm chart and image versions are explicit — never `latest`.

## Tagged resources

- Every resource that supports tags or labels carries the set the cloud ADR defines — at least service, environment,
  owner and cost center — applied once (provider `default_tags`, GCP labels, Kubernetes recommended
  `app.kubernetes.io/*` labels), not repeated by hand. An untagged resource is a review finding: it cannot be
  attributed, budgeted or cleaned up.
- Names follow the ADR's pattern and include the environment, so a staging resource is never mistaken for a
  production one.

## Cost notes

- A pull request that adds or resizes a billable resource carries a cost note: the estimated monthly delta and its
  source (an Infracost run or the provider's pricing calculator, with the date), against the budget in the cloud
  ADR. Prices are never quoted from memory.
- Autoscaling has explicit minimum and maximum bounds; logs, metrics and buckets have retention and lifecycle rules;
  non-production environments scale down outside working hours or to zero; preview environments are ephemeral.
- Watch the costs that hide: NAT and cross-zone egress, log ingestion, idle load balancers, over-provisioned
  databases, unattached volumes and snapshots. Budgets and budget alerts exist per environment.

## Environments and regions

- dev, staging and production are isolated (separate accounts or projects); preview environments never hold
  production data. The same build artifact (image digest) is promoted from staging to production — build once,
  deploy many.
- Regions hold the data where `compliance.regions` and the data model allow it; storing or processing personal data
  in another country is checked against `.claude/docs/compliance/<region>.md` before the resource is created.
- Alerts reference the SLOs in `docs/ops/slo.md` and link a runbook under `docs/ops/runbooks/`.
- CI workflows run `commands.lint`, `commands.typecheck`, `commands.test` and `commands.e2e` as required checks
  (`.claude/docs/coding-standards.md`).

## Examples

**Correct** (Terraform — Moa on AWS; tags applied once, private bucket protected from deletion, database reachable
only from the API):

```hcl
provider "aws" {
  region = var.region                     # the region the cloud ADR chose (Moa: ap-northeast-2, Seoul)
  default_tags {
    tags = {
      service     = "moa"
      env         = var.env
      owner       = "team-platform"
      cost-center = "moa"
    }
  }
}

resource "aws_s3_bucket" "statements" {
  bucket = "moa-${var.env}-statements"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "statements" {
  bucket                  = aws_s3_bucket.statements.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_vpc_security_group_ingress_rule" "db_from_api" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.api.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
```

**Correct** (GitHub Actions — plan on pull requests with OIDC and least privilege):

```yaml
permissions:
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment: staging
    permissions:
      contents: read
      id-token: write                                        # OIDC — no stored cloud keys
    steps:
      - uses: actions/checkout@<full-commit-sha>             # every action pinned to a commit SHA
      - uses: aws-actions/configure-aws-credentials@<full-commit-sha>
        with:
          role-to-assume: ${{ vars.TF_PLAN_ROLE_ARN }}       # read-only plan role
          aws-region: ${{ vars.AWS_REGION }}
      - run: terraform -chdir=infra/envs/staging init -input=false
      - run: terraform -chdir=infra/envs/staging plan -input=false -out=tfplan
```

**Incorrect**:

```hcl
provider "aws" {
  access_key = var.aws_access_key          # VIOLATION: long-lived keys instead of a role
  secret_key = var.aws_secret_key
}

resource "aws_security_group_rule" "db" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]              # VIOLATION: database open to the internet
  security_group_id = aws_security_group.db.id
}                                          # VIOLATION: no tags, no cost note for the new resources
```

```yaml
on: pull_request_target
permissions: write-all                                        # VIOLATION: maximal token for every job
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4                             # VIOLATION: tag, not a commit SHA
        with:
          ref: ${{ github.event.pull_request.head.sha }}      # VIOLATION: runs untrusted PR code with secrets
      - run: echo "Deploying ${{ github.event.pull_request.title }}"  # VIOLATION: script injection
      - run: terraform apply -auto-approve                    # VIOLATION: apply without a reviewed plan
```
