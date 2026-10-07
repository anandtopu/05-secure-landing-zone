# C11 — Infrastructure as Code: Terraform/OpenTofu and Pulumi

> **Module:** C11 — Infrastructure as Code. **Baseline (as of September 2026):** Terraform 1.16.4 is the latest stable release (1.17 in beta). It is licensed BSL 1.1, and HashiCorp has been owned by IBM since 2025-02-27. OpenTofu 1.12.6 is stable (1.13.0-rc1 is out), licensed MPL 2.0, a Linux Foundation project and CNCF Sandbox since 2025-04-23. Pulumi is at v3.264.0 and Crossplane at v2.4.x (CNCF graduated). CDK for Terraform was archived on 2025-12-10. Other tool versions are in [Tools to master](#tools-to-master).
> **Why it matters for FDEs:** at Beacon the product usually lands in the customer's cloud account as IaC: modules the customer applies, a deployer role their security team must approve, and a pipeline their change board reviews. When a Cobalt Bank reviewer asks who can read your state file or where the database password ends up, you need a precise answer on the spot. You will also face the customer's legal team when they ask why your installer depends on a BSL-licensed binary.
> **Who it's for:** engineers moving into FDE work from SWE, DevOps/SRE, QA, solutions or data engineering.
> **Estimated hours:** T1 Beginner 15-20 h · T2 Intermediate 25-30 h · T3 Advanced 25-35 h · T4 Expert 20-30 h (85-115 h total).
> **Prerequisites:** none for T1 beyond a shell and Docker. [C05](C05-networking-and-security-fundamentals.md) (IAM, OIDC and KMS) before T3. [C08](C08-cloud-platforms-aws-azure-gcp.md) before the cloud stretch goals. [C10](C10-devops-and-cicd.md) before the CI material. [C01](C01-python-mastery.md), [C02](C02-go-mastery.md) or [C03](C03-typescript-mastery.md) for Pulumi and Terratest. [C09](C09-containers-and-kubernetes.md) before Crossplane.
> **Where it is exercised:** projects [P03](../03-projects/01-foundations-microservices-and-delivery.md) (zero-downtime delivery pipeline), [P05-P08](../03-projects/02-cloud-multicloud-and-iac.md) (landing zone as code, multi-cloud active/passive, the BYOC deployer in Pulumi, multi-region HA), [P13 and P16](../03-projects/04-ai-deployment.md) (RAG in the customer VPC, air-gapped AI), [P17 and P19](../03-projects/05-edge-and-field-deployment.md) (edge fleet, on-prem installable product), [P21 and P22](../03-projects/06-security-and-reliability.md) (Kubernetes hardening, supply chain), and [P25, P27 and P28](../03-projects/07-industry-capstones.md). Drills: [D-DEP-01..15](../04-drills/03-deployment-and-incident-drills.md), [D-FIX-01..12](../04-drills/05-fix-this-broken-system-labs.md) and [D-ARC-01..20](../04-drills/04-architecture-and-api-design-drills.md). Interview questions: [T031-T060](../07-interview/03-technical-questions-cloud-k8s-devops-iac.md), [SD15-SD28](../07-interview/07-systems-design-enterprise-and-field.md), [DR01-DR15](../07-interview/10-debugging-round-scenarios.md) and [SC19-SC36](../07-interview/12-customer-scenario-questions-part2.md).
> **Fiction notice:** Beacon, Freightline and the customers (Meridian Freight, Cobalt Bank, Aegis Mission Systems, Harborview Health, Atlas Manufacturing, Northstar Retail, Solace Mutual) are fictional composites. Real products, releases and incidents are named as themselves and cited in [Sources](#sources).

## Table of contents

- [Learning objectives](#learning-objectives)
- [Core concepts](#core-concepts)
- [Subtopics](#subtopics)
- [Hands-on exercises](#hands-on-exercises)
- [Tools to master](#tools-to-master)
- [Real-world examples](#real-world-examples)
- [Common pitfalls](#common-pitfalls)
- [Field-deployment notes](#field-deployment-notes)
- [Self-assessment & exit criteria](#self-assessment--exit-criteria)
- [Curated resources](#curated-resources)
- [Sources](#sources)
- [Related](#related)

---

## Learning objectives

**T1 Beginner**
- You can write, format, validate, plan, apply and destroy a two-resource configuration with both `terraform` 1.16 and `tofu` 1.12 within 30 minutes, and explain every symbol in the plan output (`+`, `~`, `-/+`, `<=`).
- You can use typed variables with `validation`, `locals`, outputs and `for_each` over a map, and say which instances a change to the map will create or destroy before you run the plan.
- You can explain what state records, find a plaintext secret in a state file, and name three ways to keep it out, within 15 minutes.
- You can configure a remote backend with locking, reproduce a lock conflict between two terminals, and explain whether that backend needs `force-unlock`.
- You can read `.terraform.lock.hcl`, explain `~>` versus `>=` constraints, and say why the lock file is committed and module versions are not locked by it.

**T2 Intermediate**
- You can extract a reusable module with a typed interface, publish `v1.0.0`, `v1.1.0` and `v2.0.0` git tags with a changelog, and pin consumers to each, within 3 hours.
- You can refactor a live configuration (rename, `count` to `for_each`, move into a module) with `moved` blocks and get a plan with zero changes the first time you run it.
- You can bring three hand-built resources under management with `import` blocks and `-generate-config-out`, finishing with a plan that shows no changes, within 90 minutes.
- You can write a `terraform test` suite with mocked providers and `expect_failures` that runs in under 60 seconds with no cloud credentials.
- You can choose between directories, CLI workspaces, Terragrunt and Terraform Stacks for a described estate, and defend the choice in five minutes.

**T3 Advanced**
- You can gate every pull request with fmt, validate, tests, a static scanner and an OPA/Conftest policy on plan JSON, and show the gate blocking a non-compliant change.
- You can migrate an OpenTofu state to client-side encryption and rotate its key with no failed runs, within 60 minutes.
- You can keep a database password out of both state and saved plans with ephemeral values and write-only arguments, and prove it with `grep`.
- You can run an unattended drift job over N root modules that separates "drift" from "error" by exit code and reports the unmanaged-resource blind spot.
- You can design plan-on-PR and apply-on-merge with separate OIDC plan and apply roles and no long-lived cloud keys, and place Atlantis, Spacelift and HCP Terraform on that design.

**T4 Expert**
- You can ship a BYOC delivery kit: a versioned module the customer applies, a least-privilege deployer role with `ExternalId` and a permissions boundary, a test suite and a runbook, which a customer security reviewer can approve asynchronously.
- You can drive one stack per customer programmatically with the Pulumi Automation API, covering create, update and teardown, and produce an audit log of every run.
- You can deliver and run IaC in an air-gapped enclave: provider mirror, multi-platform checksums, offline `init` and tests, inside the customer's change window.
- You can brief a customer's legal and procurement team in one page on Terraform BSL 1.1 versus OpenTofu MPL 2.0 (and Vault versus OpenBao), with a migration plan and risk register.
- You can compare Terraform/OpenTofu, Pulumi, AWS CDK, Bicep and Crossplane for a named customer and recommend one that fits their skills, cloud, change control and licensing policy.

---

## Core concepts

### 1. The execution model: desired, recorded and actual

Every HCL engine keeps three views of the world, and every bug you will debug is a disagreement between two of them.

```text
   CONFIG (desired)            STATE (recorded)              REAL WORLD (actual)
   +------------------+        +---------------------+       +---------------------+
   | *.tf / *.tofu    |        | address -> real ID  |       | VPCs, IAM roles,    |
   | *.tfvars, modules|        | attributes, deps    |       | buckets, containers |
   +--------+---------+        | serial, lineage     |       +----------+----------+
            |                  +----------+----------+                  |
            |  1. build the dependency graph                             |
            |  2. refresh: read "actual" for every address in state <----+
            |  3. diff config against refreshed state
            v
   +-------------------------------------------------------------------+
   | PLAN: create (+) / update (~) / replace (-/+) / destroy (-) /     |
   |       read (<=) / move / import / forget                          |
   +--------------------------------+----------------------------------+
                                    | 4. apply walks the graph (-parallelism=10)
                                    v
                    provider API calls -> new state written (serial + 1)
```

The engine sees the real world only through state: an address such as `aws_s3_bucket.logs` maps to a provider ID that refresh reads. Hence three failure classes. Config differs from state: your change, shown in the plan. State differs from actual: drift, found by refresh. Actual exists but is missing from state: unmanaged infrastructure, which the plan never mentions. In customer estates the third class is the largest, and you rarely see "actual" yourself: you work from a plan pasted into a ticket, so read plans fluently.

### 2. HCL in depth

HCL is a declarative language of **blocks** (`resource`, `module`, `variable`), **arguments** and **expressions**, typed as `string`, `number`, `bool`, `list`, `set`, `map`, `object` and `tuple`, with `optional(type, default)` inside objects. What matters in production: `for_each` keys instances by a stable string while `count` keys them by position, so deleting item 0 replaces everything after it. `for` expressions reshape collections, and `dynamic` generates nested blocks. `validation`, `precondition` and `postcondition` reject bad input before the provider sees it, while `check` blocks warn without blocking. `lifecycle` gives you `create_before_destroy`, `prevent_destroy`, `ignore_changes` and `replace_triggered_by`.

```hcl
variable "services" {
  type = map(object({
    port   = number
    public = optional(bool, false)
  }))
  validation {
    condition     = alltrue([for s in values(var.services) : s.port >= 8000 && s.port <= 8999])
    error_message = "Freightline service ports must be in 8000-8999."
  }
}

locals {
  public_services = { for name, s in var.services : name => s if s.public }
}

resource "docker_container" "svc" {
  for_each = var.services
  name     = "freightline-${each.key}"
  image    = docker_image.stub.image_id

  ports {
    internal = 80
    external = each.value.port
  }

  dynamic "labels" {
    for_each = { owner = "beacon-fde", service = each.key }
    content {
      label = labels.key
      value = labels.value
    }
  }

  lifecycle {
    precondition {
      condition     = !(each.value.public && each.key == "billing")
      error_message = "billing must never be published directly (PCI scope)."
    }
  }
}
```

The engines' languages now diverge. Terraform added `action` blocks and `list` resources for `terraform query` (1.14), variables in module `source`/`version` and `deprecated` on variables and outputs (1.15), and `import` inside modules plus `lifecycle { destroy = false }` (1.16). OpenTofu added `lifecycle { enabled = ... }` to replace `count = var.x ? 1 : 0` (1.11) and a dynamic `prevent_destroy` plus its own `destroy = false` (1.12). For dual-engine modules, stay inside the shared core (concept 13).

### 3. Providers, source addresses and the lock file

A provider is a separate plugin binary that the engine talks to over gRPC. `source = "hashicorp/aws"` expands to `registry.terraform.io/hashicorp/aws` under Terraform and `registry.opentofu.org/hashicorp/aws` under OpenTofu. The registries serve the same releases under different addresses and signatures, so each tool writes its own lock entries. `.terraform.lock.hcl` records the exact version and hashes **per platform**. Commit it, and run `terraform providers lock` for every platform the customer uses, or installs from unpacked mirrors and plugin caches on their Linux runners can fail with checksum mismatches. The lock file covers providers, never modules, so pin modules in `source`/`version`. Use aliases for multiple accounts or regions. Provider configuration must be known at plan time, so a provider cannot be configured from a resource created in the same apply; split those into separate roots.

```hcl
provider "aws" {
  alias  = "customer"
  region = var.region
  assume_role {
    role_arn     = var.deployer_role_arn
    external_id  = var.external_id
    session_name = "beacon-fde-${var.engagement_id}"
  }
  default_tags {
    tags = { "beacon:managed" = "true", "beacon:engagement" = var.engagement_id }
  }
}
```

### 4. State: backends, locking, blast radius and encryption

State is a JSON document containing every attribute of every managed resource, including generated passwords, private keys and connection strings. **Anyone who can read state can read your secrets.** Put that sentence in every security review. Remote backends store state and serialise writers:

| Backend | Locking mechanism | Stale-lock behaviour | Notes |
|---|---|---|---|
| `s3` | `use_lockfile = true` writes a `.tflock` object using S3 conditional writes (GA in Terraform 1.11; native in OpenTofu 1.10) | A crashed run leaves the lock; clear it with `force-unlock <ID>` | `dynamodb_table` has been deprecated since 1.11, so migrate by enabling `use_lockfile` before removing it |
| `azurerm` | Blob lease | Lease can remain; `force-unlock` | Use Entra ID auth, not storage keys |
| `gcs` | Lock object next to state | `force-unlock` | Bucket versioning on |
| `pg` | Postgres advisory locks | Session-scoped: released when the holding connection closes, so a crashed run leaves no stale lock to force-unlock | Good for on-prem and labs |
| HCP Terraform / Terraform Enterprise | Workspace run queue | Managed | Remote runs, policy, private registry |
| `http` | Optional LOCK/UNLOCK endpoints | Server-defined | GitLab-managed state uses it |

```hcl
terraform {
  backend "s3" {
    bucket       = "cobalt-freightline-tfstate"
    key          = "prod/network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:us-east-1:111122223333:alias/tfstate"
    use_lockfile = true
  }
}
```

Split state by **lifecycle and ownership** (network, data, platform, app), not only by environment. **OpenTofu state encryption** (since 1.7) encrypts state and plan files on the client, with keys from PBKDF2, AWS KMS, GCP KMS, Azure Key Vault or OpenBao. Terraform has no client-side equivalent, only backend encryption plus tight bucket IAM. Regulated customers notice: with OpenTofu, bucket read access no longer means secret read access.

### 5. Module design and versioning

A module is a unit of intent with a stable interface. Its inputs are the API and its outputs are the contract. The rules that survive customer use:

- Type every input, use `object({...})` with `optional()` defaults over dozens of scalars, and validate early.
- Never put `provider` blocks inside a reusable module. The caller passes providers with `providers = { aws = aws.customer }`.
- In modules, set minimum provider versions (`>= 6.0`). In roots, use pessimistic constraints (`~> 6.66`).
- Keep nesting to two levels at most. Compose modules in the root.
- Ship `moved` blocks inside the module when you rename internals, so consumers get the refactor without a destroy.
- Mark inputs and outputs `deprecated = "..."` (Terraform 1.15+) one minor version before you remove them.

**Semver for IaC.** Breaking (major): removing or renaming a variable, changing a default so infrastructure changes, or changing an address without a `moved` block. Minor: a new optional input. Patch: a fix with no plan diff. **Distribution:** git tags (`source = "git::https://git.example.com/iac/vpc.git?ref=v1.4.0"`; git sources take no `version` argument), a private registry (HCP Terraform, TFE, GitLab, Artifactory), or OCI registries for OpenTofu 1.10+. Ship customer releases with a changelog, an upgrade guide and checksums.

### 6. Environment layouts: directories, workspaces, Terragrunt and Stacks

| Layout | How environments differ | Isolation | Best for | Failure mode |
|---|---|---|---|---|
| **Directory per env/component** (`envs/prod/network`) | Separate root per env, each calling shared modules | Separate state, backend key and credentials | Most customer estates; clear CAB diffs | Copy-paste drift between env roots |
| **CLI workspaces** | Same code, `terraform.workspace` switches values | Separate state, **same backend and credentials** | Short-lived, identical copies (feature environments, per-tenant labs) | `apply` in the wrong workspace; prod and dev share an IAM boundary |
| **Terragrunt 1.x** | `terragrunt.hcl` per unit, `terragrunt.stack.hcl` generates units, `run --all` orchestrates | Per-unit state generated for you | Large multi-account estates, DRY backends | Another tool to install and to justify to the customer's platform team |
| **Terraform Stacks** (GA in HCP Terraform) | Components in `.tfcomponent.hcl`, deployments in `.tfdeploy.hcl` | Per deployment | HCP customers who repeat one stack across regions/accounts; limits are 20 deployments, 100 components and 10k resources per Stack | HCP-only; does not exist in OpenTofu or air-gapped sites |
| **HCP Terraform workspaces/projects** | Workspace variables and variable sets | Per workspace, with RBAC | Customers already paying for HCP/TFE | Workspace sprawl; free tier caps at 500 managed resources |

Default for a Beacon deployment: directories per environment and component, calling versioned modules. Every customer reviewer and CI system understands it.

### 7. Refactoring and brownfield: `moved`, `import`, `removed` and `query`

Four blocks let you change what state says without touching infrastructure, and each change is reviewed in a plan like any other.

```hcl
moved {
  from = docker_container.api
  to   = module.orders.docker_container.this
}

import {
  for_each = var.legacy_buckets            # map: key => bucket name
  to       = aws_s3_bucket.legacy[each.key]
  id       = each.value
}

removed {
  from = aws_s3_bucket.handover
  lifecycle {
    destroy = false
  }
}
```

`moved` re-addresses a resource (a rename, `count` to `for_each`, or into a module). `import` adopts existing infrastructure; `terraform plan -generate-config-out=generated.tf` drafts HCL for it, and since 1.16 import blocks can sit inside modules. `removed` with `destroy = false` stops managing a resource without deleting it, which is how you hand an asset back. Terraform 1.14's `list` resources (`*.tfquery.hcl`) and `terraform query` discover existing infrastructure and generate import config where the provider supports it. The brownfield loop: inventory, import, generate, prune, reach a zero-change plan, commit, and only then change anything. Prefer these blocks to `state mv`/`state rm`/CLI `import`: they are reviewed, repeatable and visible to the change board.

### 8. Testing IaC: the pyramid

| Layer | Tool | Catches | Runs in |
|---|---|---|---|
| Static | `fmt -check`, `validate`, TFLint (OpenTofu 1.13 RC adds built-in `-lint`) | Syntax, type errors, deprecated arguments, provider-specific mistakes | Seconds, every commit |
| Unit | `terraform test` / `tofu test` (`*.tftest.hcl`, and `*.tofutest.hcl` for OpenTofu-only suites) with `mock_provider`, `override_resource`, `expect_failures` | Wrong logic in `for_each`/conditionals, validation gaps, contract changes | Seconds, no credentials |
| Contract/policy | Conftest on plan JSON, Checkov, Trivy config | Public buckets, wildcard IAM, missing tags or encryption | Seconds after plan |
| Integration | `terraform test` with `command = apply` in a sandbox; Terratest (Go, `TerraformBinary: "tofu"` for OpenTofu) | Things that only fail against the real API: quotas, eventual consistency, IAM propagation | Minutes and money, nightly |
| Continuous | `check` blocks, drift jobs | Post-deploy regressions | Scheduled |

Mocked unit tests are the layer FDEs underuse: they run on a locked-down customer runner with no cloud credentials and document the module contract for the reviewer.

### 9. Policy as code: where each control runs

Policy has four enforcement points, and a mature customer already owns the last one. **Pre-plan static scanning** (Checkov; Trivy, which absorbed tfsec; KICS) reads HCL fast but cannot see computed values. **Post-plan policy** runs OPA/Conftest on `terraform show -json tfplan`, so it sees resolved values and can count deletions. OPA 1.0 made Rego v1 syntax (`if`, `contains`) mandatory. **Platform policy** runs in the orchestrator: Sentinel (proprietary, HCP Terraform/TFE; the 1.17 beta notes describe "Terraform Policy" going GA), Spacelift's OPA policies and Pulumi policy packs. **Runtime guardrails** belong to the cloud: AWS SCPs, Azure Policy and GCP Organization Policy. A clean plan followed by an explicit-deny `AccessDenied` or `RequestDisallowedByPolicy` on apply means you hit that layer; ask for the policy text instead of guessing. Trivy's own action was compromised in March 2026, so pin scanners by digest and run them with no secrets in scope.

### 10. Secrets: `sensitive` is not secret

`sensitive = true` only redacts CLI output. The value is still written to state, and saved plan files contain variable values as well. Keep secrets out, in this order of preference:

| Rank | Pattern | Example | Caveat |
|---|---|---|---|
| 1 | Don't create the secret in IaC | RDS `manage_master_user_password = true`; managed identities; workload identity federation | Not every service supports it |
| 2 | Ephemeral values and write-only arguments | `variable { ephemeral = true }` or an `ephemeral` resource, then `password_wo` plus `password_wo_version` (Terraform 1.10/1.11+, OpenTofu 1.11+) | The provider must implement `*_wo`; bump the version argument to rotate |
| 3 | Pass references, not values | Pass the Secrets Manager ARN or OpenBao path; the app reads it at runtime (External Secrets Operator, CSI driver) | Needs runtime identity |
| 4 | Encrypt and restrict state | OpenTofu state encryption; backend KMS; state read access equals secret read access | Terraform has no client-side encryption |
| Never | `tfvars` in git, secrets in `output`, `TF_LOG=trace` in CI, long-lived cloud keys in pipeline variables | | |

Provider credentials follow the same rule: use OIDC federation or workload identity, never static keys. Pulumi encrypts values marked secret (`pulumi.secret()`, `pulumi config set --secret`) inside its state using a secrets provider (passphrase, a cloud KMS, Vault or Pulumi Cloud), which is closer to OpenTofu's model than to Terraform's.

### 11. Drift: detect, classify, then revert, codify or ignore

Drift comes from console hotfixes, other automation, provider default changes and controller-owned fields. Detect it with a scheduled `plan -detailed-exitcode` per root (0 no changes, 1 error, 2 changes); `-refresh-only` isolates drift from unapplied config. HCP Terraform health assessments do this as a service on the paid tiers that include them (check the customer's plan), and reconcilers (Crossplane, ACK, Argo CD) correct drift continuously. Classify every finding: **revert** (apply the code), **codify** (the hotfix was right, so change the code) or **ignore** (`ignore_changes` with a comment naming the owning controller). Plan-based detection is blind to unmanaged resources; for those you need cloud inventory (AWS Config, Azure Resource Graph) or `terraform query`.

### 12. CI for IaC: plan on PR, apply on merge

```text
 PR opened ---> fmt/validate/test ---> plan (read-only OIDC role) ---> policy on plan JSON ---> plan summary as PR comment
                                                                                                          |
 merge to main ---> plan again + apply (apply OIDC role, "production" environment approval, one run per state at a time)
```

Rules that matter in the field:
- **Two roles.** The plan role reads and writes nothing except the state lock. The apply role writes, and it is trusted only for `environment:production` or `ref:refs/heads/main`. "Read-only" is not harmless: AWS `ReadOnlyAccess` can read S3 objects and SSM parameter values, so for customers scope the plan role to the services the root actually manages.
- **Serialise per state.** Use a concurrency group per root module. Terraform refuses a saved plan whose state changed after the plan was made ("Saved plan is stale"). Keep that guard and never work around it.
- **Plan artifacts are secrets.** They contain variable values, so give them short retention, restricted access and no ticket attachments.
- **Pin everything.** Pin actions to full commit SHAs, download engines from their release sites with checksum verification (and GPG where the customer requires it), and pin scanner images by digest.

```yaml
name: iac
on:
  pull_request:
    paths: ["infra/**"]
  push:
    branches: [main]
    paths: ["infra/**"]
permissions:
  contents: read
concurrency:
  group: iac-prod-network
  cancel-in-progress: false
jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions: { contents: read, id-token: write, pull-requests: write }
    steps:
      - uses: actions/checkout@<full-commit-sha-you-reviewed>
      - run: ./ci/install-tools.sh   # pinned, checksum-verified terraform + conftest (C11-E10)
      - run: ./ci/assume-role.sh arn:aws:iam::111122223333:role/freightline-plan
      - run: terraform -chdir=infra init -input=false
      - run: terraform -chdir=infra plan -input=false -lock-timeout=5m -out=tfplan
      - run: terraform -chdir=infra show -json tfplan > plan.json && conftest test plan.json -p policy/
  apply:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    permissions: { contents: read, id-token: write }
    steps:
      - uses: actions/checkout@<full-commit-sha-you-reviewed>
      - run: ./ci/install-tools.sh
      - run: ./ci/assume-role.sh arn:aws:iam::111122223333:role/freightline-apply
      - run: terraform -chdir=infra init -input=false
      - run: terraform -chdir=infra plan -input=false -out=tfplan
      - run: terraform -chdir=infra apply -input=false tfplan
```

```bash
#!/usr/bin/env bash
# ci/assume-role.sh <role-arn>: hand the GitHub OIDC token to the AWS SDK web-identity chain (no third-party action)
set -euo pipefail
token_file="$RUNNER_TEMP/aws-web-identity-token"
curl -fsS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r .value > "$token_file"
{
  echo "AWS_ROLE_ARN=$1"
  echo "AWS_WEB_IDENTITY_TOKEN_FILE=$token_file"
  echo "AWS_ROLE_SESSION_NAME=gh-${GITHUB_RUN_ID}"
} >> "$GITHUB_ENV"
```

Replace `<full-commit-sha-you-reviewed>` with the 40-character commit you audited. The apply role's trust policy pins `token.actions.githubusercontent.com:aud` to `sts.amazonaws.com` and `:sub` to `repo:beacon-fde/freightline-infra:environment:production`. **Repositories created after 2026-07-15 get an immutable ID-based `sub`** (`repo:OWNER@OWNER-ID/REPO@REPO-ID:...`), so check a real token before writing the condition. Orchestrators: **Atlantis** (self-hosted, CNCF Sandbox since 2024) plans and applies from PR comments, applying before merge. **Spacelift** (private workers, OPA policies) and **HCP Terraform/TFE** (remote runs, Sentinel, private registry, Stacks) are managed platforms. Many customers run plain Jenkins, Azure DevOps or GitLab; build this flow in any of them.

### 13. Licensing and governance

| Component | License / owner (Sept 2026) | What customers' legal teams do with it |
|---|---|---|
| Terraform CLI | BSL 1.1 since 1.6.0; each version converts to MPL 2.0 four years after publication; IBM-owned since 2025-02-27 | End-user internal use is generally fine. Legal looks at the additional-use grant when a **vendor embeds or hosts** Terraform in a commercial product (for example a BYOC installer) |
| OpenTofu | MPL 2.0; Linux Foundation project, CNCF Sandbox since 2025-04-23 | Passes "OSI-approved only" policies; defense and public-sector customers often ask for it by name |
| HCP Terraform / TFE | Commercial SaaS / self-managed | Procurement, data residency (an EU option exists), vendor-concentration review |
| Vault / OpenBao | BSL, IBM, 2.x line / MPL 2.0 fork under the OpenSSF | Same argument, applied to the secrets tier |
| Pulumi CLI and SDKs | Apache 2.0; Pulumi Cloud and ESC are commercial | Self-managed backends avoid the SaaS dependency |
| Crossplane | Apache 2.0, CNCF graduated | Clean for OSS policies |

The engines are **"compatible core, divergent edges"**: providers, modules and most HCL work in both. Terraform-only: `action`, `query`/`list`, Stacks, Sentinel and HCP. OpenTofu-only: state encryption, `enabled`, OCI registries and dynamic `prevent_destroy`. Test dual-engine Beacon modules under both in CI. When legal asks, bring the license text, the version you ship, whether you embed the binary, and the migration cost either way; Fidelity's migration ([Real-world examples](#real-world-examples)) is the public precedent.

### 14. Beyond HCL: Pulumi, AWS CDK, Bicep and Crossplane

| Tool | Language | State | Scope | Where it wins in the field | Watch out for |
|---|---|---|---|---|---|
| **Pulumi** | TypeScript/JS, Python, Go, .NET, Java, YAML and now HCL | Pulumi Cloud or a self-managed backend (`file://`, `s3://`, `azblob://`, `gs://`) | Any cloud; can bridge Terraform providers | Real languages, **stacks** per env/tenant, **ESC** (environments, secrets, dynamic OIDC credentials for AWS/Azure/GCP/GitHub), **Automation API** (IaC embedded in your own deployer service) | Programs can hide side effects; version the SDK with the CLI |
| **AWS CDK** (v2.270.0) | TS, Python, Java, C#, Go | CloudFormation stacks | AWS only | AWS-only shops; L2/L3 constructs; CloudFormation rollback | Synth output is huge; CloudFormation limits and drift semantics |
| **Bicep** (v0.47.x) | Bicep DSL compiled to ARM | Azure itself (no state file); deployment stacks for lifecycle | Azure only | Microsoft-recommended ARM authoring; `what-if`; no state to secure | No multi-cloud; `azurerm`/`azapi` Terraform remains the multi-cloud choice |
| **Crossplane v2** | Kubernetes YAML plus composition functions | Kubernetes API (etcd) | Any cloud, plus any Kubernetes resource | Continuous reconciliation, platform APIs (a `Freightline` kind that composes a DB, bucket and Deployment), GitOps with Argo CD/Flux | v2 removed claims and native patch-and-transform, so v1 tutorials are wrong; v2 adds namespaced managed resources alongside the legacy cluster-scoped ones |
| CDK for Terraform | n/a | n/a | n/a | **Archived 2025-12-10.** Migrate with `cdktf synth --hcl`, or move to CDK or Pulumi | Do not start new work on it |

Pulumi maps onto Terraform: a **project** is a program, a **stack** is an instance with its own config and state (`dev`, `prod`, or one per customer), and `preview`/`up`/`destroy` are plan/apply/destroy. The **Automation API** (`@pulumi/pulumi/automation`, `pulumi.automation`, `github.com/pulumi/pulumi/sdk/v3/go/auto`) runs them from code but shells out to the Pulumi CLI, which must be installed wherever it runs. That is how you build a one-stack-per-customer BYOC deployer ([P07](../03-projects/02-cloud-multicloud-and-iac.md)). An ESC environment issuing short-lived AWS credentials:

```yaml
values:
  aws:
    login:
      fn::open::aws-login:
        oidc:
          roleArn: arn:aws:iam::111122223333:role/beacon-esc-deployer
          sessionName: beacon-esc
  environmentVariables:
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}
    AWS_SESSION_TOKEN: ${aws.login.sessionToken}
```

### 15. Delivering IaC to customers

```text
 BEACON (vendor, fictional)                         CUSTOMER ACCOUNT (e.g. Cobalt Bank, composite)
 +------------------------------+                  +----------------------------------------------+
 | module registry (semver)     |  signed release  | customer pipeline (Azure DevOps / Jenkins)   |
 |  beacon-byoc-aws    v3.2.0   | ---------------> |   plan -> CAB review -> apply                |
 |  beacon-deployer-role v1.4.0 |  + checksums     |   state in the CUSTOMER's backend            |
 |  CHANGELOG, UPGRADE.md, SBOM |  + runbook       |   customer-owned KMS key                     |
 +------------------------------+                  +----------------------+-----------------------+
 | Beacon CI / FDE laptop       |                                         |
 |  (only if the customer       |-- sts:AssumeRole + ExternalId --------->| beacon-deployer role  |
 |   allows vendor-run applies) |   session tags, max 1 h sessions        |  permissions boundary |
 +------------------------------+                                         |  region + tag limits  |
                                                                          +-----------------------+
```

| Delivery model | Who runs apply | State lives | Use when |
|---|---|---|---|
| Vendor-operated via cross-account role | Beacon | Beacon backend, or the customer's backend via role | Dedicated tenant; the customer accepts vendor-run changes |
| **Customer-applied modules** | Customer, in their pipeline | Customer backend | Default for BYOC in banks, healthcare and insurers |
| Marketplace / CloudFormation / Bicep one-click template | Customer console | Cloud-native | Low-touch trials |
| Air-gapped bundle (modules + provider mirror + images) | Customer's cleared operators | Enclave backend | Aegis-style classified or disconnected sites |

Delivery rules: no hard-coded account IDs, regions or CIDRs; every resource tagged `beacon:managed` plus the engagement ID; a deployer role bounded by a permissions boundary and scoped to that tag; outputs that double as the handover document; both engines tested; and "plan output plus runbook" for every change, because at regulated customers someone else types `apply`.

---

## Subtopics

**T1 Beginner**
1. Workflow and CLI
   1.1 `init`, `plan`, `apply`, `destroy`: what each phase reads and writes
   1.2 `fmt`, `validate`, `console`, `output`, `show`: daily inspection commands
   1.3 Plan symbols and `-out` plans: reading `+`, `~`, `-/+`, `<=` and "forces replacement"
2. HCL fundamentals
   2.1 Blocks, arguments, expressions and types, including `optional()`
   2.2 Variables, `validation`, `locals`, outputs and `.tfvars` precedence
   2.3 `count` versus `for_each`: why positional indexes cause replacements
3. Providers and state basics
   3.1 Source addresses, version constraints and the lock file
   3.2 Local versus remote state, locking and `force-unlock` semantics per backend
   3.3 What state contains, and why reading it equals reading secrets

**T2 Intermediate**
4. Modules
   4.1 Interface design: typed objects, defaults, no provider blocks
   4.2 Versioning: semver rules for IaC, git tags versus registries, `deprecated`
   4.3 Composition and `providers =` passing for multi-account work
5. Refactoring and brownfield
   5.1 `moved` for renames, `count` to `for_each`, and moves into modules
   5.2 `import` blocks (with `for_each`), `-generate-config-out`, pruning generated HCL
   5.3 `removed` with `destroy = false` for handovers; `terraform query` discovery
6. Layout and testing
   6.1 Directories versus workspaces versus Terragrunt versus Stacks
   6.2 `terraform test`/`tofu test`: `run`, `assert`, `mock_provider`, `expect_failures`
   6.3 TFLint, Checkov and Trivy config scanning; reading and suppressing findings

**T3 Advanced**
7. Security of the IaC supply chain
   7.1 OIDC plan/apply roles, trust conditions, the 2026 `sub` format change
   7.2 Pinning: action SHAs, engine checksums, scanner digests, provider hashes
   7.3 Plan and state artifacts as secrets: retention and access
8. Secrets and encryption
   8.1 Ephemeral variables/resources and write-only arguments with version triggers
   8.2 OpenTofu state encryption: key providers, `fallback`, `enforced`, rotation
   8.3 Runtime secret references: Secrets Manager, Key Vault, OpenBao, ESO
9. Policy, drift and orchestration
   9.1 Conftest/OPA on plan JSON (Rego v1), Sentinel/Terraform Policy, runtime guardrails
   9.2 Drift: `-detailed-exitcode`, `-refresh-only`, classify and respond, unmanaged blind spot
   9.3 Atlantis, Spacelift, HCP Terraform/TFE: run models, policy hooks, private workers

**T4 Expert**
10. Other engines
    10.1 Pulumi: projects, stacks, secrets providers, self-managed backends, ESC
    10.2 Pulumi Automation API: a deployer service with one stack per tenant
    10.3 AWS CDK, Bicep with deployment stacks, Crossplane v2 compositions: when each wins
11. Customer delivery
    11.1 BYOC modules the customer applies: interface, tags, outputs, upgrade guides
    11.2 Least-privilege deployer roles: `ExternalId`, permissions boundaries, session limits
    11.3 Air-gapped delivery: provider mirrors, module bundles, offline `init`, signed releases
12. Governance
    12.1 BSL 1.1 versus MPL 2.0, IBM ownership, embedding versus using; OpenBao versus Vault
    12.2 Terraform to OpenTofu migration: compatible core, divergent edges, rollback plan
    12.3 Evidence for regulators: plans, approvals and applied state as audit artifacts

---

## Hands-on exercises

You need Docker, `terraform` 1.16.x, `tofu` 1.12.x, `kind`, `jq` and Git. Everything except C11-E10 (costed there) runs locally or against mock providers at no cost. Use one directory per exercise, and never point both engines at the same state.

### C11-E01 — First configuration, two engines

**Tier:** T1 Beginner · **Time box:** 45 min
**Goal:** run the full lifecycle under both engines and read every plan symbol.
**Setup:** create an empty directory `e01/` with this `main.tf`:

```hcl
terraform {
  required_version = ">= 1.11.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:stable-alpine" # a moving tag is fine for a lab; pin by digest for customers
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "c11-web"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 8081
  }
}

output "url" {
  value = "http://localhost:8081"
}
```

**Steps:**
1. Initialise the directory and save a plan.

```bash
terraform init
```

```bash
terraform plan -out=tfplan
```

2. Apply the saved plan, then check the container answers.

```bash
terraform apply tfplan
```

```bash
curl -s http://localhost:8081
```

3. Run a plan with `-detailed-exitcode` and print its exit code in the same shell (a separate block would lose `$?`).

```bash
terraform plan -detailed-exitcode -input=false; echo "exit code: $?"
```

4. Change `external = 8081` to `8082`, plan again, and find the `-/+` marker and the `# forces replacement` comment on `ports`.
5. Destroy everything with `terraform destroy`. Copy the directory to `e01-tofu/`, delete `.terraform/` and `terraform.tfstate*` in the copy, and run `tofu init` and `tofu apply` there.
6. Compare the two lock files with `diff e01/.terraform.lock.hcl e01-tofu/.terraform.lock.hcl`.

**Acceptance criteria:** the curl output contains `Welcome to nginx!`. The exit code in step 3 is `0`. The step 4 plan reads `Plan: 1 to add, 0 to change, 1 to destroy.` The diff in step 6 shows provider addresses `registry.terraform.io/kreuzwerker/docker` and `registry.opentofu.org/kreuzwerker/docker`, and you can explain why the two tools write different entries.
**Stretch:** run `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64` and count the `h1:` and `zh:` hashes it adds.

### C11-E02 — `count` versus `for_each`: predict the blast radius

**Tier:** T1 Beginner · **Time box:** 40 min
**Goal:** see why positional indexes replace resources you did not touch.
**Setup:** in `e02/`, reuse the `terraform` block, provider and `docker_image.nginx` from E01, and add:

```hcl
variable "names" {
  type    = list(string)
  default = ["orders", "inventory", "billing"]
}

resource "docker_container" "by_index" {
  count = length(var.names)
  name  = "c11-idx-${var.names[count.index]}"
  image = docker_image.nginx.image_id
}

resource "docker_container" "by_key" {
  for_each = toset(var.names)
  name     = "c11-key-${each.key}"
  image    = docker_image.nginx.image_id
}
```

**Steps:**
1. Run `terraform init` and `terraform apply -auto-approve`.
2. Write down what you expect when `orders` is removed from the list.
3. Plan the removal:

```bash
terraform plan -var='names=["inventory","billing"]'
```

4. Compare the plan with your prediction, then run `terraform destroy -auto-approve`.

**Acceptance criteria:** the plan reads `Plan: 2 to add, 0 to change, 4 to destroy.` `by_index[0]` and `by_index[1]` are replaced (`-/+`) because their names shift. `by_index[2]` is destroyed. On the `for_each` side only `by_key["orders"]` is destroyed. Your written prediction matched, or you can say where it went wrong.
**Stretch:** write the three `moved` blocks that would convert `by_index` to a `for_each` keyed by name with zero changes. C11-E05 checks them.

### C11-E03 — Remote state, locking, and the secret in the state file

**Tier:** T1 Beginner · **Time box:** 60 min
**Goal:** prove that state holds secrets in plaintext, and reproduce a lock conflict.
**Setup:** start a Postgres 18 container to act as the backend.

```bash
docker run -d --name c11-pg -e POSTGRES_USER=tf -e POSTGRES_PASSWORD=tf -e POSTGRES_DB=tfstate -p 5432:5432 postgres:18
```

```bash
export PG_CONN_STR="postgres://tf:tf@localhost:5432/tfstate?sslmode=disable"
```

In `e03/`, declare `backend "pg" {}` inside the `terraform` block, require `hashicorp/random` `~> 3.9`, and add `resource "random_password" "db" { length = 24 }` plus an output `db_password` marked `sensitive = true`.

**Steps:**
1. Run `terraform init` and `terraform apply -auto-approve`, then check that `terraform output db_password` prints `<sensitive>`.
2. Pull the state and look for the value.

```bash
terraform state pull | jq -r '.resources[] | select(.type=="random_password") | .instances[0].attributes.result'
```

3. See where the backend put the state.

```bash
docker exec c11-pg psql -U tf -d tfstate -c "select id, name from terraform_remote_state.states;"
```

4. In terminal A, run `terraform apply` and leave it at the approval prompt. In terminal B, run `terraform plan`.
5. Kill terminal A's process with `kill -9`, then run `terraform plan` in B again.

**Acceptance criteria:** step 2 prints the 24-character password in plaintext despite `<sensitive>` in step 1. Step 3 lists a row named `default`. Step 4 fails in B with `Error acquiring the state lock` and `Workspace is already locked: default`. The pg backend cannot name the lock holder (the printed lock info is B's own request); find it with `select pid, granted from pg_locks where locktype = 'advisory';`. After step 5, B's plan succeeds without `force-unlock` because the advisory lock died with A's connection, whereas an S3 `.tflock` object (which records the holder) would have survived.
**Stretch:** repeat against an S3 bucket with `use_lockfile = true` in a sandbox account, find the `.tflock` object during a run, and clear a stale one with `terraform force-unlock <ID>`.

### C11-E04 — A versioned module with a semver history

**Tier:** T2 Intermediate · **Time box:** 3 h
**Goal:** publish a module the way you would publish it to a customer, and make one breaking release on purpose.
**Setup:** a bare Git repository to act as the registry.

```bash
git init --bare /tmp/c11-modules.git
```

**Steps:**
1. In a working clone, create `modules/freightline-service/`: input `service = object({ name = string, port = number, public = optional(bool, false) })` with a port `validation`, one `docker_container.this`, outputs `name` and `url`, `required_providers` at `>= 4.0`, and no `provider` block.
2. Write `README.md` and `CHANGELOG.md` (`## [1.0.0]`). Commit, tag `v1.0.0`, push with tags.
3. In `e04-consumer/`, call it twice (`orders`, `inventory`) with `source = "git::file:///tmp/c11-modules.git//modules/freightline-service?ref=v1.0.0"` and apply.
4. Release `v1.1.0`: add `labels = optional(map(string), {})` and rename the resource to `docker_container.service` with a `moved` block inside the module. Bump the consumer's `ref`, run `terraform init -upgrade`, plan.
5. Release `v1.2.0` marking `service` `deprecated = "use spec"` (Terraform 1.15+), then `v2.0.0` renaming it to `spec`, with the break under `### Breaking` and the exact consumer diff in `UPGRADE.md`.
6. Upgrade the consumer to `v2.0.0` following only `UPGRADE.md`.

**Acceptance criteria:** `git ls-remote --tags /tmp/c11-modules.git` lists every tag. The step 4 plan shows `has moved to` for both instances and `Plan: 0 to add, 0 to change, 0 to destroy.` After the `UPGRADE.md` edit, step 6 plans no changes, and a peer can do it without asking you anything.
**Stretch:** publish the same module to a private registry (GitLab or Artifactory), or push it to an OCI registry for OpenTofu 1.10+, and pin with `version = "~> 2.0"`.

### C11-E05 — Refactor with `moved`, adopt with `import`

**Tier:** T2 Intermediate · **Time box:** 2.5 h
**Goal:** change addresses and adopt hand-built infrastructure with zero unintended changes.
**Setup:** re-apply the E02 configuration with the default list. Then create three hand-built "legacy" containers by running this with each of the names `legacy-edi`, `legacy-sftp` and `legacy-rates`:

```bash
docker run -d --name legacy-edi nginx:stable-alpine
```

**Steps:**
1. Delete `by_key` and apply once. Replace `by_index` with `docker_container.svc` using `for_each = toset(var.names)`, plus one `moved` block per index (`from = docker_container.by_index[0]`, `to = docker_container.svc["orders"]`). Plan and apply.
2. Move `svc` into a local module `./modules/svc` called with `for_each`, with `moved` blocks to `module.svc["orders"].docker_container.this` and siblings. Plan and apply.
3. List the full IDs of the legacy containers:

```bash
docker ps --no-trunc --filter name=legacy- --format '{{.Names}} {{.ID}}'
```

4. Write one `import` block per container (`to = docker_container.legacy_edi`, `.legacy_sftp`, `.legacy_rates`, each with `id = "<full id>"`) and no resource blocks, then generate draft configuration.

```bash
terraform plan -generate-config-out=generated.tf
```

5. Prune `generated.tf` (drop computed and default-valued attributes; set anything that forces replacement to the imported value) and re-plan until the plan only imports. Apply.
6. Remove the `import` blocks, keep the `moved` blocks, commit.

**Acceptance criteria:** the renames in steps 1 and 2 each plan as `Plan: 0 to add, 0 to change, 0 to destroy.` with only moves listed. The final plan in step 5 reads `Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.` After apply, `terraform plan` reports `No changes.` and `terraform state list` shows the three legacy addresses.
**Stretch:** hand one legacy container back to "the customer's team" with a `removed` block (`lifecycle { destroy = false }`) and check that `docker ps` still lists it after apply.

### C11-E06 — A test suite that runs with no credentials

**Tier:** T2 Intermediate · **Time box:** 2 h
**Goal:** document and enforce a module contract with `terraform test` and mocks, under both engines.
**Setup:** in `e06/`, put the E01 `terraform` block and provider, the concept 2 configuration (`variable "services"` and `docker_container.svc`) and a `docker_image.stub` resource (any small image). Run `terraform init`; it needs the registry, not the Docker daemon.
**Steps:**
1. Create `tests/unit.tftest.hcl`:

```hcl
mock_provider "docker" {}

variables {
  services = {
    orders    = { port = 8081 }
    inventory = { port = 8082, public = true }
  }
}

run "names_are_prefixed" {
  command = plan
  assert {
    condition     = docker_container.svc["orders"].name == "freightline-orders"
    error_message = "container names must be prefixed with freightline-"
  }
}

run "rejects_port_outside_range" {
  command = plan
  variables {
    services = { orders = { port = 9100 } }
  }
  expect_failures = [var.services]
}

run "billing_is_never_public" {
  command = plan
  variables {
    services = { billing = { port = 8083, public = true } }
  }
  expect_failures = [docker_container.svc]
}
```

2. Stop Docker Desktop (or the daemon), then run the suite.

```bash
terraform test
```

3. Delete `.terraform/`, run `tofu init`, then run `tofu test`.
4. Break the contract on purpose by changing the name prefix to `fl-` in the resource. Run the suite and read the failure message.

**Acceptance criteria:** both engines report `Success! 3 passed, 0 failed.` in under 60 seconds with the Docker daemon stopped. Step 4 fails on `names_are_prefixed` with your error message.
**Stretch:** add a `command = apply` run in `tests/integration.tftest.hcl` and run it with `terraform test -filter=tests/integration.tftest.hcl` while the daemon runs. Then write it as a Terratest function (Terratest v2.0.0 splits into per-module paths such as `github.com/gruntwork-io/terratest/modules/terraform/v2` and needs Go 1.26+; v1.0.1 is frozen for security fixes only) with `TerraformBinary: "tofu"`.

### C11-E07 — A policy gate on plan JSON

**Tier:** T3 Advanced · **Time box:** 2 h
**Goal:** block a non-compliant change using values that only exist after the plan, plus a static scan.
**Setup:** the E06 root with the Docker daemon running, and Conftest 0.70.x installed.
**Steps:**
1. Write `policy/freightline.rego` in Rego v1 syntax:

```rego
package main

containers contains rc if {
	some rc in input.resource_changes
	rc.type == "docker_container"
	some action in rc.change.actions
	action in {"create", "update"}
}

has_owner(rc) if {
	some l in rc.change.after.labels
	l.label == "owner"
}

deny contains msg if {
	some rc in containers
	not has_owner(rc)
	msg := sprintf("%s: every container needs an 'owner' label", [rc.address])
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "docker_volume"
	"delete" in rc.change.actions
	msg := sprintf("%s: deleting a data volume needs a change ticket, not a pipeline", [rc.address])
}
```

2. Remove the `dynamic "labels"` block from the resource, then plan and export JSON.

```bash
terraform plan -out=tfplan
```

```bash
terraform show -json tfplan > plan.json
```

```bash
conftest test plan.json -p policy/
```

3. Put the labels back, re-plan, re-export and re-test.
4. Run a static scan of the HCL, mounting only the source directory and passing no credentials. The lab pins by version; in CI, look the digest up with `docker buildx imagetools inspect aquasec/trivy:0.74.0` and append `@sha256:<digest>` so a re-pushed tag cannot change what runs.

```bash
docker run --rm -v "$PWD:/src:ro" aquasec/trivy:0.74.0 config /src
```

**Acceptance criteria:** step 2 exits `1` and prints one `FAIL` line per container naming its address. Step 3 reports `0 failures`. You can name one finding the static scan makes that Conftest cannot (and one the other way round: Conftest sees resolved variable values and counts deletions, which HCL scanning cannot).
**Stretch:** add a `warn` rule that fires when a plan destroys more than 3 resources, and add Checkov as a second scanner, pinned by digest.

### C11-E08 — Secrets out of state, state encrypted

**Tier:** T3 Advanced · **Time box:** 90 min
**Goal:** keep a password out of state with an ephemeral value and a write-only argument, then encrypt OpenTofu state and rotate its key.
**Setup:** create a local cluster.

```bash
kind create cluster --name c11
```

**Steps:**
1. In `e08-wo/`, require `hashicorp/kubernetes` `~> 3.2` and `hashicorp/random` `~> 3.9`, configure the provider with `config_path = "~/.kube/config"` and `config_context = "kind-c11"`, and add:

```hcl
ephemeral "random_password" "db" {
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "orders_db" {
  metadata {
    name      = "orders-db"
    namespace = "default"
  }
  data_wo          = { password = ephemeral.random_password.db.result }
  data_wo_revision = 1 # bump to rotate; the value itself is never stored
}
```

2. Apply, read the real value from the cluster, then search the state for it.

```bash
kubectl get secret orders-db -o jsonpath='{.data.password}' | base64 -d
```

```bash
terraform state pull | grep -c "PASTE_THE_VALUE_HERE"
```

3. As a control, in a fresh directory `e08-control/`, create a secret `orders-db-control` from a managed `random_password` using `data` instead of `data_wo`. Apply and repeat the grep there.
4. In `e08-enc/`, create a `random_password` with local state under `tofu`. Add an `encryption` block with `key_provider "pbkdf2"` (a 16+ character passphrase from `TF_VAR_state_passphrase`), `method "aes_gcm"`, and `method "unencrypted" "migrate" {}` as the `fallback` for `state` and `plan`. Run `tofu apply`.
5. Drop the unencrypted fallback and set `enforced = true`. To rotate, add a key provider and method for the old passphrase as the fallback:

```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "new" { passphrase = var.state_passphrase }
    key_provider "pbkdf2" "old" { passphrase = var.old_state_passphrase }
    method "aes_gcm" "new" { keys = key_provider.pbkdf2.new }
    method "aes_gcm" "old" { keys = key_provider.pbkdf2.old }
    state {
      method   = method.aes_gcm.new
      enforced = true
      fallback { method = method.aes_gcm.old }
    }
    plan {
      method   = method.aes_gcm.new
      enforced = true
      fallback { method = method.aes_gcm.old }
    }
  }
}
```

6. Run `tofu apply` (it reads with the old key and writes with the new one), then delete the `old` provider, method and fallback, and run `tofu plan`.

**Acceptance criteria:** step 2's grep prints `0`, and step 3's prints `2` or more (once for `random_password.result`, once for the secret data). After step 4, `grep -c encrypted_data terraform.tfstate` prints `1` and `grep -c '"result"' terraform.tfstate` prints `0`. After step 6, `tofu plan` succeeds with only the new passphrase and fails to decrypt with only the old one.
**Stretch:** replace `pbkdf2` with the `openbao` key provider against a dev-mode OpenBao container, or `aws_kms` in a sandbox, and write down who can now decrypt the state.

### C11-E09 — An unattended drift job that tells drift from failure

**Tier:** T3 Advanced · **Time box:** 60 min
**Goal:** run a scheduled drift check over several roots, with exit codes a scheduler can act on, and demonstrate its blind spot.
**Setup:** the applied roots from E01, E02 and E05. Save this script as `drift.sh` and make it executable:

```bash
#!/usr/bin/env bash
# drift.sh <root>...  exit 0 = all clean, 2 = drift somewhere, 1 = at least one root errored
set -uo pipefail
status=0
for root in "$@"; do
  if ! terraform -chdir="$root" init -input=false -no-color >/dev/null 2>&1; then
    echo "ERROR  $root (init)"; status=1; continue
  fi
  terraform -chdir="$root" plan -refresh-only -detailed-exitcode -input=false -no-color >"$root/drift.txt" 2>&1
  case $? in
    0) echo "CLEAN  $root" ;;
    2) echo "DRIFT  $root"; [ "$status" -eq 0 ] && status=2 ;;
    *) echo "ERROR  $root (plan)"; status=1 ;;
  esac
done
exit "$status"
```

**Steps:**
1. Run `./drift.sh e01 e02 e05` on a clean estate.
2. Create drift with `docker rm -f c11-web`, then run it again.
3. Break `e02` (add an undeclared variable reference) and run it again.
4. Fix `e02`, then start an unmanaged container with `docker run -d --name shadow-api nginx:stable-alpine` and run it once more.
5. For the `c11-web` finding, decide: revert (`terraform apply`), codify (change the code) or ignore (`ignore_changes` with a comment naming the owner). Write one line of justification.

**Acceptance criteria:** step 1 prints three `CLEAN` lines and exits `0`. Step 2 prints `DRIFT  e01`, and `e01/drift.txt` contains `has been deleted`. Step 3 exits `1` even though drift is also present. Step 4 exits `2` and does not mention `shadow-api`, and you can explain why no plan-based job ever will.
**Stretch:** add an inventory check that lists running containers not present in any root's `terraform state list`. It is the laptop equivalent of AWS Config or Azure Resource Graph.

### C11-E10 — Plan on PR, apply on merge, two OIDC roles

**Tier:** T3 Advanced · **Time box:** 4 h
**Goal:** build the concept 12 pipeline end to end with no long-lived keys.
**Setup:** a free GitHub repository and an AWS sandbox account. Expected cost is under USD 0.10 (an S3 state bucket with SSE-S3 and a standard-tier SSM parameter; a customer-managed KMS key would add about USD 1 a month). Tear it down the same day.
**Steps:**
1. Bootstrap from a separate local root: the state bucket (versioned, public access blocked), the GitHub OIDC provider, and two roles. `freightline-plan` gets `ReadOnlyAccess` plus `s3:PutObject`/`s3:DeleteObject` only on `*.tflock`. `freightline-apply` can write, and its trust requires the `environment:production` `sub`.
2. Add `ci/assume-role.sh` from concept 12 and this `ci/install-tools.sh`:

```bash
#!/usr/bin/env bash
# ci/install-tools.sh: install pinned, checksum-verified terraform and conftest
set -euo pipefail
TF_VERSION="1.16.4"
CONFTEST_VERSION="0.70.1"
mkdir -p "$HOME/bin" && cd "$RUNNER_TEMP"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
grep " terraform_${TF_VERSION}_linux_amd64.zip\$" "terraform_${TF_VERSION}_SHA256SUMS" | sha256sum -c -
unzip -o -q "terraform_${TF_VERSION}_linux_amd64.zip" -d "$HOME/bin"
curl -fsSLO "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz"
curl -fsSLO "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/checksums.txt"
grep " conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz\$" checksums.txt | sha256sum -c -
tar -xzf "conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz" -C "$HOME/bin" conftest
echo "$HOME/bin" >> "$GITHUB_PATH"
```

3. Commit the concept 12 workflow with real action SHAs, an `infra/` root (S3 backend, `use_lockfile = true`), and the E07 policy adapted to require a `beacon:managed` tag. Create a `production` environment with yourself as required reviewer.
4. Open a PR adding an untagged SSM parameter, then fix it in the same PR. Merge and approve.
5. On a branch, point the plan job at the apply role and watch it fail; read the exact `sub` from the CloudTrail `AssumeRoleWithWebIdentity` event.
6. Tear down: destroy `infra/`, then delete the roles, OIDC provider and bucket (all object versions).

**Acceptance criteria:** the first PR run fails at Conftest and the second passes. The merge run waits for approval, then applies. Step 5 fails with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. The repository holds no `AWS_ACCESS_KEY_ID` secret, and the bucket is gone after step 6.
**Stretch:** port the flow to GitLab CI or Azure DevOps (what Cobalt Bank, composite, runs), and schedule E09's `drift.sh` with the plan role.

### C11-E11 — A BYOC delivery kit a customer reviewer can approve

**Tier:** T4 Expert · **Time box:** 8 h
**Goal:** produce the deployer-role module and release bundle you would send Cobalt Bank (composite) for asynchronous security review.
**Setup:** a module repo `beacon-deployer-role/` requiring `hashicorp/aws` `>= 6.0`. It needs no AWS account, because the tests mock the provider.
**Steps:**
1. Write the role. Use `jsonencode` rather than the `aws_iam_policy_document` data source, so mocked plans still contain real policy text:

```hcl
resource "aws_iam_role" "deployer" {
  name                 = "beacon-deployer"
  path                 = "/beacon/"
  max_session_duration = 3600
  permissions_boundary = aws_iam_policy.boundary.arn
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Principal = { AWS = "arn:aws:iam::${var.vendor_account_id}:role/beacon-fde-deployer" }
      Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
    }]
  })
  tags = { "beacon:managed" = "true" }
}
```

2. Write `aws_iam_policy.boundary` with four statements: allow the Beacon footprint services; deny everything except `iam:*` and `sts:*` outside `var.allowed_regions` (`aws:RequestedRegion`); deny `iam:CreateUser`, `iam:CreateAccessKey` and boundary removal; deny `ec2:TerminateInstances`, `ec2:DeleteVolume` and `ec2:DeleteSecurityGroup` unless `aws:ResourceTag/beacon:managed` is `true`. Add a `validation` that `external_id` is at least 12 characters.
3. Write `tests/role.tftest.hcl` with `mock_provider "aws" {}`, test variables, and `run` blocks with `command = plan` that assert `jsondecode(aws_iam_role.deployer.assume_role_policy).Statement[0].Condition.StringEquals["sts:ExternalId"] == var.external_id`, `max_session_duration == 3600`, and that a 6-character ExternalId fails (`expect_failures = [var.external_id]`).
4. Run the suite with `terraform test` and `tofu test`. Then run `terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64 -platform=windows_amd64`.
5. Write `README.md` (every permission and why), `CHANGELOG.md`, `UPGRADE.md` and `RUNBOOK.md` (apply, verify, rotate the ExternalId, revoke Beacon with one `terraform destroy`). Tag `v1.0.0`, run `git archive --format=tar.gz -o beacon-deployer-role-v1.0.0.tar.gz v1.0.0`, and write `SHA256SUMS`.
6. Hand the bundle to a peer playing the customer's reviewer, who may only ask in writing.

**Acceptance criteria:** both suites pass with no AWS credentials, and `sha256sum -c SHA256SUMS` passes. The reviewer can answer "what can Beacon do, where, for how long, and how do we cut it off" from the documents alone; each question they raise becomes a doc fix or a test.
**Stretch:** apply it in a sandbox with a second account as vendor. Show `aws sts assume-role` failing without the ExternalId and a `us-west-2` call being denied, then tighten the policy with IAM Access Analyzer policy generation.

### C11-E12 — One stack per tenant with the Pulumi Automation API

**Tier:** T4 Expert · **Time box:** 4 h
**Goal:** drive per-customer stacks from code, with encrypted secrets and an audit trail, on a self-managed backend.
**Setup:** install the Pulumi CLI (v3.264.0 as of September 2026). The Automation API shells out to it. Then run these, one per block:

```bash
mkdir -p c11-deployer/.state
```

```bash
cd c11-deployer
```

```bash
npm init -y
```

```bash
npm install @pulumi/pulumi @pulumi/random tsx
```

```bash
export PULUMI_CONFIG_PASSPHRASE='lab-only-passphrase-change-me'
```

**Steps:**
1. Save `deployer.ts`:

```ts
import { appendFileSync } from "node:fs";
import * as pulumi from "@pulumi/pulumi";
import { LocalWorkspace } from "@pulumi/pulumi/automation";
import * as random from "@pulumi/random";

const [tenant, action = "up"] = process.argv.slice(2);
if (!tenant || !/^[a-z][a-z0-9-]{2,30}$/.test(tenant)) {
  console.error("usage: tsx deployer.ts <tenant> [up|preview|destroy]");
  process.exit(64);
}

// Stand-in for the per-customer footprint (VPC, EKS, RDS in project P07).
const program = async () => {
  const cfg = new pulumi.Config();
  const suffix = new random.RandomPet("suffix", { length: 2 });
  const db = new random.RandomPassword("db", { length: 24, special: false });
  return {
    bucketName: pulumi.interpolate`beacon-${cfg.require("tenant")}-${suffix.id}`,
    dbPassword: db.result, // a secret output: stored as ciphertext in the stack file
  };
};

async function main(): Promise<void> {
  const stack = await LocalWorkspace.createOrSelectStack(
    { projectName: "beacon-byoc", stackName: tenant, program },
    {
      projectSettings: {
        name: "beacon-byoc",
        runtime: "nodejs",
        backend: { url: `file://${process.cwd()}/.state` },
      },
    },
  );
  await stack.setConfig("tenant", { value: tenant });
  const started = new Date().toISOString();
  const onOutput = (s: string) => process.stdout.write(s);
  let summary: unknown;
  if (action === "destroy") {
    summary = (await stack.destroy({ onOutput })).summary;
    await stack.workspace.removeStack(tenant);
  } else if (action === "preview") {
    summary = (await stack.preview({ onOutput })).changeSummary;
  } else {
    summary = (await stack.up({ onOutput })).summary;
  }
  appendFileSync("audit.jsonl", JSON.stringify({ started, finished: new Date().toISOString(), tenant, action, summary }) + "\n");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

2. Deploy two tenants, then preview one.

```bash
npx tsx deployer.ts meridian up
```

```bash
npx tsx deployer.ts northstar up
```

```bash
npx tsx deployer.ts meridian preview
```

3. Search the backend for a plaintext password and for ciphertext.

```bash
grep -rc ciphertext .state/.pulumi/stacks
```

4. Tear one tenant down with `npx tsx deployer.ts meridian destroy`.

**Acceptance criteria:** two stack files (`meridian.json`, `northstar.json`) exist under `.state/.pulumi/stacks/beacon-byoc/` before step 4, and only `northstar.json` after (ignore `.bak` backups). Step 3 reports at least one `ciphertext` per stack file, and `dbPassword` is stored as an encrypted object, never as a plain string. `audit.jsonl` has four lines with `started`, `finished` and a resource-change summary. The preview in step 2 reports only `same` operations.
**Stretch:** swap `random` for `@pulumi/aws` resources, with credentials from an ESC environment (concept 14), and run five tenants concurrently with `Promise.allSettled`. Each stack's lock should keep the runs independent.

### C11-E13 — Air-gapped delivery bundle and the licensing brief

**Tier:** T4 Expert · **Time box:** 4 h
**Goal:** prove the E11 kit initialises and tests with no network, and brief Aegis Mission Systems' (composite) legal team on the engine choice.
**Setup:** the E11 module with its multi-platform lock file, and Docker for the offline simulation.
**Steps:**
1. On the connected side, mirror the providers into a bundle (on Apple silicon, add `-platform=linux_arm64`, because the simulation container runs arm64).

```bash
terraform providers mirror -platform=linux_amd64 ../bundle/mirror
```

2. Copy the module into `../bundle/root/` and write `../bundle/offline.tfrc`:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/work/mirror"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

3. Package the bundle and write its checksum file; this is what crosses the gap.

```bash
tar -czf ../bundle.tar.gz -C .. bundle
```

```bash
sha256sum ../bundle.tar.gz > ../bundle.tar.gz.sha256
```

4. Simulate the enclave with a container that has no network at all. Run `init`, then the same command with `test` in place of `init -input=false -backend=false`.

```bash
docker run --rm --network none -v "$PWD/../bundle:/work" -w /work/root -e TF_CLI_CONFIG_FILE=/work/offline.tfrc hashicorp/terraform:1.16.4 init -input=false -backend=false
```

5. Repeat with `tofu providers mirror`. Note that its packages sit under `registry.opentofu.org/`, so the `include` patterns must change.
6. Write a one-page brief for Aegis's legal and procurement team: what Beacon ships (modules only, or an embedded binary), Terraform BSL 1.1 (four-year MPL conversion, IBM-owned), OpenTofu MPL 2.0 (Linux Foundation, CNCF Sandbox), Vault BSL versus OpenBao MPL, migration cost each way, a recommendation and a risk register. Append a table scoring Terraform, OpenTofu, Pulumi, AWS CDK, Bicep and Crossplane for Aegis.

**Acceptance criteria:** the offline `init` prints `Terraform has been successfully initialized!` and `test` passes, both with `--network none`. `sha256sum -c ../bundle.tar.gz.sha256` passes on the receiving side. You can explain how E11's multi-platform `providers lock` keeps the offline `init` from failing checksum verification. The brief fits on one page and every licensing claim cites the license text or the vendor's announcement.
**Stretch:** host the modules and providers in an internal OCI registry for OpenTofu, or as an Artifactory remote, and switch from `filesystem_mirror` to `network_mirror`.

---

## Tools to master

| Tool | Category | Tier | What you must be able to do with it | Version / status (Sept 2026) | Official docs |
|---|---|---|---|---|---|
| Terraform CLI | Engine | T1 | Full lifecycle, `test`, `query`, `import`/`moved`/`removed`, providers lock/mirror | 1.16.4 stable; 1.17 beta; BSL 1.1; IBM-owned | https://developer.hashicorp.com/terraform/docs |
| OpenTofu | Engine | T1 | Same core, plus state encryption, `enabled`, OCI registries, `tofu test` | 1.12.6 stable; 1.13.0-rc1; MPL 2.0; CNCF Sandbox (2025-04-23) | https://opentofu.org/docs/ |
| AWS provider (`hashicorp/aws`) | Provider | T1 | Read the docs for every argument you set; `assume_role`, `default_tags`, write-only args | v6.66.0 (2026-09-21) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs |
| TFLint | Static analysis | T2 | Run with provider rulesets in CI; suppress with justification | v0.64.0 | https://github.com/terraform-linters/tflint |
| Terratest | Integration tests (Go) | T3 | Apply-test-destroy against sandboxes; `TerraformBinary: "tofu"` | v2.0.0 (Sept 2026): 16 independently versioned modules under `/v2` paths, Go 1.26+; v1.0.1 frozen, security fixes only | https://terratest.gruntwork.io/ |
| Conftest + OPA | Policy as code | T3 | Rego v1 rules on plan JSON, K8s YAML and Dockerfiles; unit-test the policies | Conftest v0.70.1; OPA v1.21.0 | https://www.conftest.dev/ |
| Trivy | Scanner | T2 | `trivy config` on HCL; pinned by digest, no secrets in scope | v0.74.0; compromised Mar 2026 (GHSA-69fq-xp46-6x23); absorbed tfsec | https://trivy.dev/ |
| Checkov | Scanner | T2 | Scan HCL and plan JSON; custom checks; baseline files | | https://www.checkov.io/ |
| Sentinel / Terraform Policy | Platform policy | T3 | Read and explain a customer's HCP/TFE policy set and its enforcement levels | Terraform Policy GA noted in 1.17 beta notes | https://developer.hashicorp.com/sentinel/docs |
| Terragrunt | Orchestration | T3 | Units, `terragrunt.stack.hcl`, `run --all`, generated backends | v1.1.6; no breaking changes in minors | https://terragrunt.gruntwork.io/docs/ |
| HCP Terraform / TFE | Platform | T3 | Workspaces, projects, variable sets, run tasks, Stacks, health assessments | Free tier up to 500 resources; Stacks GA | https://developer.hashicorp.com/terraform/cloud-docs |
| Atlantis | PR automation | T3 | Configure `atlantis.yaml`, locking per project, apply-before-merge policy | v0.48.0 (bundles Terraform 1.16.3; slim images without engines); CNCF Sandbox (accepted 2024-06-18) | https://www.runatlantis.io/docs/ |
| Spacelift | Platform | T3 | Stacks, private workers, OPA policies, drift detection | | https://docs.spacelift.io/ |
| Pulumi (+ ESC, Automation API) | Engine | T4 | Stacks, secrets providers, self-managed backends, ESC OIDC, Automation API | v3.264.0; languages include HCL | https://www.pulumi.com/docs/ |
| AWS CDK | Engine | T4 | Synth and diff, L2/L3 constructs, CloudFormation drift and rollback | v2.270.0 | https://docs.aws.amazon.com/cdk/v2/guide/home.html |
| Bicep | Engine | T4 | `what-if`, modules, deployment stacks | v0.47.16 | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/ |
| Crossplane | Control plane | T4 | Providers, XRDs and compositions with functions (v2 model) | v2.4.x; CNCF graduated 2025-11-06 | https://docs.crossplane.io/ |
| OpenBao / Vault | Secrets | T3 | KV and Transit, dynamic cloud credentials, OpenTofu key provider | OpenBao v2.7.0 (MPL 2.0); Vault v2.1.1 (BSL) | https://openbao.org/docs/ |

---

## Real-world examples

1. **Fidelity Investments moves to OpenTofu (real, October 2025).** Fidelity runs 2,000+ applications, 50,000+ state files and 4M+ cloud resources. It pushed a proof of concept to production, won over its largest Terraform users first, reached 70% adoption before the CLI switch, made OpenTofu the default for new deployments with an opt-out, and changed shared pipelines centrally. **Lesson:** an engine migration is a governance and pipeline programme, not a rewrite. ([OpenTofu blog](https://opentofu.org/blog/fidelity-investment-migration/))
2. **The Trivy ecosystem compromise (real, 19-23 March 2026).** A malicious v0.69.4 was released, 76 of 77 `trivy-action` tags and all `setup-trivy` tags were force-pushed, and the payload scraped runner memory. **Lesson:** your IaC gate's scanner runs next to plan files and cloud credentials. Pin it by SHA or digest, and run it in a job with no secrets. ([GHSA-69fq-xp46-6x23](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23))
3. **tj-actions/changed-files (real, March 2025).** A mutable tag was repointed at code that dumped CI secrets into workflow logs (CVE-2025-30066). IaC pipelines use exactly this kind of action to choose which roots to plan. **Lesson:** pin full SHAs, keep `GITHUB_TOKEN` least-privilege, and treat logs as an exfiltration channel. ([CISA](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction))
4. **Cloudflare BYOIP withdrawal (real, 20 February 2026).** A cleanup task treated an empty `pending_delete` value as "all" and withdrew about 1,100 customer prefixes, causing a 6 h 7 min outage. **Lesson:** automation that deletes needs a blast-radius guard. For IaC, that means a policy counting `delete` actions, `prevent_destroy` on stateful resources, and filters that fail closed when empty. ([Cloudflare](https://blog.cloudflare.com/cloudflare-outage-february-20-2026/))
5. **CDK for Terraform archived (real, 10 December 2025).** HashiCorp sunset CDKTF, citing lack of product-market fit, and pointed users to `cdktf synth --hcl`, AWS CDK or Pulumi. **Lesson:** record the exit path for every IaC dependency you hand a customer. ([terraform-cdk](https://github.com/hashicorp/terraform-cdk))
6. **Cobalt Bank quarter-end (composite, fictional).** A Beacon upgrade needed a new subnet a week before the freeze. The FDE gave the change board the rendered plan, the plan JSON, a Conftest report and a rollback plan (revert, then re-plan). Then `terraform init` failed on the bank's runners with `x509: certificate signed by unknown authority` from the TLS-inspecting proxy. The fix was a provider mirror in the bank's Artifactory plus the corporate CA bundle, not disabling verification. **Lesson:** find out in week one where the customer's pipeline downloads providers from.

---

## Common pitfalls

| Pitfall | How it shows up in the field | Why it happens | Fix / prevention |
|---|---|---|---|
| `count` over named things | Removing one item replaces every later resource | Positional addresses | `for_each` over a map or set; `moved` to migrate (C11-E02, C11-E05) |
| `sensitive = true` treated as protection | The security review finds passwords in the state bucket and in plan artifacts | It only redacts CLI output | Managed passwords, ephemeral plus write-only arguments, encryption, tight state access (C11-E08) |
| Single-platform lock file | `init` fails in Linux CI or the enclave with a checksum mismatch (unpacked mirror or plugin cache) | Lock written by `init` on a Mac | `providers lock` for every platform (C11-E11, C11-E13) |
| `provider` blocks inside modules | The module can't take `for_each` and can't be removed cleanly | Root-module habits | Callers pass `providers = {}` |
| Workspaces as prod/dev isolation | An apply in the wrong workspace; one credential reaches every environment | Workspaces share a backend and credentials | A directory per environment, each with its own role |
| One giant state | 20-minute plans, lock contention, a huge blast radius | Everything started in `main.tf` | Split roots by lifecycle and ownership |
| `force-unlock` during a live run | Two writers, then corrupted state | A lock mistaken for a stale one | Check the holder first; restore from bucket versioning |
| Imperative `state mv`/`rm`/`import` | Environments diverge, and the change board never saw the change | Old tutorials | `moved`, `removed` and `import` blocks in a PR |
| `ignore_changes = all` | Real drift stays hidden until an incident | Noisy plans | Ignore named attributes, with a comment naming the owning controller |
| Plan passes, apply hits `AccessDenied` or `RequestDisallowedByPolicy` | A failed change inside the customer's change window | SCPs and Azure/GCP policies are invisible to plan | Get guardrail policy text during discovery; apply in a customer sandbox first |
| Engine version skew | A 1.16 module fails on the customer's 1.12 runner | `required_version` missing | Pin it, and test against the customer's version in CI |
| Engine migration treated as reversible | After moving to OpenTofu, rolling back to Terraform fails: encrypted state, `enabled` or OCI sources are unreadable to Terraform | Divergent edges adopted before the migration was signed off | Stay in the shared core until the customer commits; snapshot Terraform-readable state (as tightly restricted as the live state) and test the rollback step |
| Stale tools | tfsec, Crossplane v1 claims, new CDKTF work | Old material | Trivy, Crossplane v2 functions, no new CDKTF |

---

## Field-deployment notes

- **You usually do not run `apply`.** In banks, hospitals and insurers the customer's pipeline applies your module under their change control; you deliver a versioned module, a reproducible plan and a runbook. Debug from pasted plans and `terraform show -json` extracts; never ask for `TF_LOG=trace` from production.
- **State is regulated data.** Harborview state (composite) can hold connection strings to PHI stores, and Cobalt payments state can sit in PCI scope. Keep it in the customer's account under their KMS key, restrict it like the data it points to, and document that.
- **Change control shapes the pipeline.** Under SOX-style separation of duties, the author, approver and applier are different people. Retain plan JSON, approvals and apply logs as evidence. Drift jobs stay read-only through freezes. Agree the emergency-change path before you need it.
- **Restricted networks.** Expect TLS-inspecting proxies, blocked public registries and slow allow-lists. Plan for a `network_mirror` or Artifactory remote, internally hosted modules, and the corporate CA bundle on runners.
- **Air-gapped sites.** At an Aegis-style site (composite), everything crosses as a signed, checksummed bundle: modules, provider mirror, engine binary and a multi-platform lock file. Cleared staff run it. The MPL licence and state encryption make OpenTofu a frequent ask.
- **Legacy estates.** Import only what you will own, reach a zero-change plan before changing anything, and hand assets back with `removed` blocks.
- **Licensing reviews.** Bring the facts listed in concept 13; never answer from memory.

---

## Self-assessment & exit criteria

**T1 Beginner**
- [ ] I can read every plan symbol and predict `count` versus `for_each` blast radius (C11-E01, C11-E02).
- [ ] I can find a secret in state and name three ways to keep it out (C11-E03).
- [ ] I can explain my backend's locking and stale-lock behaviour.

You are T1 when you can read any plan a customer pastes into a ticket.

**T2 Intermediate**
- [ ] I have shipped a breaking module release with a changelog and an upgrade guide (C11-E04).
- [ ] I can refactor and import with zero unintended changes (C11-E05).
- [ ] I can write a mocked, credential-free test suite (C11-E06).
- [ ] I can defend a layout choice (directories, workspaces, Terragrunt or Stacks) for a named estate.

You are T2 when a teammate can consume your module from its README alone.

**T3 Advanced**
- [ ] My pipeline plans on PR, applies on merge, uses two OIDC roles and blocks on policy (C11-E07, C11-E10).
- [ ] I can keep secrets out of state, and encrypt and rotate OpenTofu state (C11-E08).
- [ ] My drift job separates drift from errors, and I can explain its blind spot (C11-E09).

You are T3 when a regulated customer's reviewer finds no long-lived keys, no unpinned dependencies and no secrets in your state or artifacts.

**T4 Expert**
- [ ] A reviewer approved my BYOC kit asynchronously (C11-E11).
- [ ] I drive per-tenant stacks from code with an audit trail (C11-E12).
- [ ] I can deliver and test IaC in an air gap and brief legal on licensing (C11-E13).
- [ ] I can recommend one of Terraform, OpenTofu, Pulumi, CDK, Bicep or Crossplane for a named customer and defend it.

You are T4 when customers run your modules in their own pipelines and their legal team files your licensing brief.

---

## Curated resources

| Resource | Type | Essential / Optional | Note |
|---|---|---|---|
| Brikman, *Terraform: Up & Running*, 3rd ed. (2022) | Book | Essential | Still the best tour of state, modules and testing. It predates OpenTofu, `import` blocks, `terraform test` and ephemeral values |
| Brikman, *Fundamentals of DevOps and Software Delivery* (O'Reilly, 2025) | Book | Optional | Newer and broader: IaC alongside CI/CD, networking and monitoring |
| Terraform language docs | Official docs | Essential | https://developer.hashicorp.com/terraform/language |
| OpenTofu state encryption | Official docs | Essential | https://opentofu.org/docs/language/state/encryption/ |
| Pulumi Automation API and ESC | Official docs | Essential (T4) | https://www.pulumi.com/docs/iac/automation-api/ · https://www.pulumi.com/docs/esc/ |
| Crossplane v2 docs | Official docs | Optional | https://docs.crossplane.io/ (skip v1 tutorials) |
| HashiCorp tutorials (free) | Course | Essential (T1-T2) | https://developer.hashicorp.com/terraform/tutorials ; work the state, modules, test and import tracks, then redo them with `tofu` |
| OpenTofu migration guide | Official docs | Essential (T4) | https://opentofu.org/docs/intro/migration/ ; the per-version steps you cite in a migration plan |
| Terraform Associate, exam 004 (Terraform 1.12, USD 70.50) | Certification | Optional | A customer-facing signal, not a substitute for E10-E13 |
| Terraform `LICENSE`, IBM acquisition release, Fidelity Q&A | Primary sources | Essential (T4) | Cite them in licensing briefs |

---

## Sources

- Terraform releases; LICENSE — https://github.com/hashicorp/terraform/releases ; https://github.com/hashicorp/terraform/blob/main/LICENSE
- IBM completes HashiCorp acquisition — https://newsroom.ibm.com/2025-02-27-ibm-completes-acquisition-of-hashicorp,-creates-comprehensive,-end-to-end-hybrid-cloud-platform
- Terraform Stacks; HCP pricing — https://developer.hashicorp.com/terraform/language/stacks ; https://www.hashicorp.com/en/pricing
- OpenTofu releases; state encryption — https://github.com/opentofu/opentofu/releases ; https://opentofu.org/docs/language/state/encryption/
- AWS and Kubernetes provider releases — https://github.com/hashicorp/terraform-provider-aws/releases ; https://github.com/hashicorp/terraform-provider-kubernetes/releases
- Pulumi releases; ESC — https://github.com/pulumi/pulumi/releases ; https://www.pulumi.com/docs/esc/
- Crossplane; Terragrunt — https://blog.crossplane.io/ ; https://github.com/gruntwork-io/terragrunt/releases
- OPA; Conftest; Atlantis — https://github.com/open-policy-agent/opa/releases ; https://github.com/open-policy-agent/conftest/releases ; https://www.cncf.io/projects/atlantis/
- Terratest; Trivy misconfiguration scanning (absorbed tfsec; tfsec repo is historical reference only) — https://github.com/gruntwork-io/terratest ; https://trivy.dev/latest/docs/scanner/misconfiguration/
- GitHub OIDC `sub` format — https://docs.github.com/en/actions/concepts/security/openid-connect
- OpenBao releases — https://github.com/openbao/openbao/releases
- Incident and case-study links are inline in [Real-world examples](#real-world-examples).

---

## Related

- **Modules:** [C05](C05-networking-and-security-fundamentals.md) · [C08](C08-cloud-platforms-aws-azure-gcp.md) · [C09](C09-containers-and-kubernetes.md) · [C10](C10-devops-and-cicd.md) · [C12](C12-observability-and-monitoring.md) · [C15](C15-production-readiness-and-incident-response.md) · [C16](C16-customer-facing-and-field-deployment.md) · [C17](C17-documentation-and-stakeholder-communication.md)
- **Projects:** [P03](../03-projects/01-foundations-microservices-and-delivery.md) · [P05-P08](../03-projects/02-cloud-multicloud-and-iac.md) · [P13, P16](../03-projects/04-ai-deployment.md) · [P17, P19](../03-projects/05-edge-and-field-deployment.md) · [P21, P22](../03-projects/06-security-and-reliability.md) · [P25, P27, P28](../03-projects/07-industry-capstones.md)
- **Drills:** [D-DEP-01..15](../04-drills/03-deployment-and-incident-drills.md) · [D-FIX-01..12](../04-drills/05-fix-this-broken-system-labs.md) · [D-ARC-01..20](../04-drills/04-architecture-and-api-design-drills.md)
- **Interview:** [T031-T060](../07-interview/03-technical-questions-cloud-k8s-devops-iac.md) · [SD15-SD28](../07-interview/07-systems-design-enterprise-and-field.md) · [DR01-DR15](../07-interview/10-debugging-round-scenarios.md) · [SC19-SC36](../07-interview/12-customer-scenario-questions-part2.md)
- **See also (existing repo):** [M07 CI/CD and IaC](../../01-curriculum/M07-cicd-and-iac.md) · [M15 Security and compliance](../../01-curriculum/M15-security-and-compliance.md) · [Lab series C](../../04-labs/series-c-cloud-and-devops.md) · [P4 Cloud deployment](../../03-projects/P4-cloud-deployment-and-monitoring.md) · [Production readiness checklist](../../08-templates/production-readiness-checklist.md)

**Next:** [C12 — Observability & Monitoring](C12-observability-and-monitoring.md)
