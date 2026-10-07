## P05 — Secure Landing Zone as Code

### Metadata

| Field | Value |
|---|---|
| ID | P05 |
| Tier | **T2 Intermediate** (M1-M5); **T3 Advanced** (SCP/RCP design, policy gates, drift: M6-M8) |
| Time estimate | 35-50 hours |
| Industry framing | Cobalt Bank (fictional): US bank with an EU subsidiary; Azure plus on-prem today; PCI DSS v4.0.1, SOX, NYDFS Part 500, EU DORA; weekly CAB, quarter-end freezes, TLS-inspecting proxy |
| Required categories covered | Security hardening; infrastructure as code |
| Languages | HCL (OpenTofu 1.12, Terraform 1.16-compatible), Rego (OPA 1.x), Python 3.14, YAML |
| Cloud(s) | AWS; Azure variant in [Appendix P05-A](#appendix-p05-a--azure-variant) |
| Cost and keeping it near $0 | Organizations, SCPs, Identity Center, tag policies, action-free budgets and an org trail's first copy of management events are free; GuardDuty and Security Hub CSPM have 30-day trials; KMS is about $1 per key-month. Interface endpoints bill hourly per AZ, so create them only for the M7 test; no NAT gateway. Expect under $15. Creating an organization moves a Free-plan account to the Paid plan (remaining credits still apply). Emulators can't prove an SCP denies anything: run policy gates offline on plan JSON and test SCPs in real accounts. |
| Prerequisites | [C05](../02-curriculum/C05-networking-and-security-fundamentals.md), [C08](../02-curriculum/C08-cloud-platforms-aws-azure-gcp.md), [C10](../02-curriculum/C10-devops-and-cicd.md), [C11](../02-curriculum/C11-infrastructure-as-code.md) |

### 1. Problem statement

**Context (composite scenario).** Cobalt Bank is Azure-first. Its fraud team bought Beacon, whose fraud-analytics data plane runs in AWS in BYOC mode ([P07](#p07--byoc-deployer-in-pulumi)). Cobalt's only AWS footprint is two shadow accounts opened on corporate cards, with IAM users holding year-old access keys, which Internal Audit has logged as a SOX ITGC finding (no change evidence, no access review). The Cloud CoE rules that no vendor workload lands until an organization passes Cobalt's Cloud Control Framework, and the contract includes 25 FDE days to co-build it with Cobalt's two-person AWS team.

**Constraints.**
- **Identity:** Microsoft Entra ID is the only IdP (phishing-resistant MFA, conditional access). No IAM users except sealed break-glass users.
- **Compliance:** PCI DSS v4.0.1 is the only active version (all requirements mandatory since 2025-03-31), and the fraud platform handles tokenized card data. SOX ITGCs need approval evidence for every change. NYDFS Part 500's final phase (universal MFA, asset inventory) has applied since 2025-11-01. The EU subsidiary brings DORA (applicable since 2025-01-17): a register of ICT third-party arrangements, with exit plans.
- **Change control:** weekly CAB; nothing changes in the two weeks around quarter-end.
- **Network:** CI runs on self-hosted GitHub runners in Cobalt's data center, behind a proxy that re-signs TLS with Cobalt's root CA.
- **Region:** US only, and, after October 2025, no workloads in us-east-1.

**Stakeholders.** CISO-office security architect (approves guardrails), Cloud CoE lead (owns it after handover), Internal Audit, Network Engineering, FinOps, the fraud program sponsor.

**Success criteria.** (1) Every account's CloudTrail events reach the log archive within 15 minutes, and log validation passes. (2) Zero IAM users outside two management-account break-glass users. (3) 100% of at least 20 SCP test cases pass. (4) CI blocks 10 of 10 seeded violations with 0 of 5 false blocks. (5) Out-of-band changes are detected within 24 hours. (6) A new baselined account comes from one PR in under 30 minutes.

### 2. Requirements

**Functional.**
- **FR-1** Organization (all features) with OUs Security, Infrastructure, Workloads/{Prod, NonProd}, Sandbox, PolicyStaging, Suspended.
- **FR-2** Accounts as code: `log-archive`, `security-tooling`, `automation`, `network`, `fraud-prod`, `fraud-nonprod`, `scp-test`.
- **FR-3** SCPs (Region allow-list, security-baseline protection, deny root, require IMDSv2, deny IAM users), one RCP identity perimeter, a tag policy.
- **FR-4** IAM Identity Center federated with Entra ID (SAML + SCIM); permission sets assigned to groups only.
- **FR-5** Organization trail (all Regions, log-file validation, SSE-KMS) into an Object Lock bucket in `log-archive`.
- **FR-6** GuardDuty, Security Hub CSPM and IAM Access Analyzer run from `security-tooling` as delegated admin, auto-enabled org-wide.
- **FR-7** Workload VPC module: private subnets only, gateway and interface endpoints, org-scoped endpoint policies, flow logs.
- **FR-8** Mandatory tags, cost-allocation tags and budgets; CI gates (fmt, lint, Checkov, Conftest on plan JSON); nightly drift detection.

**Non-functional.**

| Attribute | Target |
|---|---|
| Log delivery | p95 under 15 min to `log-archive` |
| Log retention | 400 days (PCI DSS 10.5.1 asks for 12 months, 3 immediately available) |
| CI plan + gates | Under 6 min per stack |
| Drift detection | Every 24 h per stack |
| Account vending | Under 30 min from merge |
| Lab platform run cost | Under $25/month excluding workloads |

**Constraints.** OpenTofu/Terraform only; no long-lived keys in CI; runners trust Cobalt's CA; state encrypted with customer-managed KMS keys.

**Out of scope.** Direct Connect/Transit Gateway to on-prem ([P20](05-edge-and-field-deployment.md#p20--hybrid-connectivity-and-network-troubleshooting-lab)); deploying Beacon (P07); SIEM integration beyond an export point; Control Tower (ADR-2).

### 3. Architecture

```text
  Microsoft Entra ID (Cobalt) --SAML+SCIM--> IAM Identity Center (home us-east-2, replica us-west-2)
  GitHub Actions (self-hosted runners, TLS proxy) --OIDC--> automation: lz-plan / lz-deployer roles
 +------------------------------------ AWS Organization o-cobalt0example ------------------------------------+
 | MANAGEMENT: Organizations, SCP/RCP/tag policies, billing, 2 sealed break-glass IAM users, org trail owner  |
 | ==== trust boundary: SCPs do NOT apply to the management account -> keep it nearly empty ====            |
 | OU Security                     OU Infrastructure            OU Workloads                                  |
 | +----------------------+        +---------------------+      +-------------------+ +-------------------+   |
 | | log-archive          |<-logs--| automation          |      | Prod: fraud-prod  | | NonProd:          |   |
 | |  S3 Object Lock, KMS |        |  tfstate S3 + KMS   |      |  VPC private only | |  fraud-nonprod    |   |
 | |  trail, flow logs,   |<-------|  CI roles (OIDC)    |      |  + VPC endpoints  | |  same baseline    |   |
 | |  Config snapshots    |        +---------------------+      +---------+---------+ +---------+---------+   |
 | +----------------------+        | network (IPAM, TGW  |                | findings, flow logs  |             |
 | | security-tooling     |<-------|  later: P20)        |<---------------+----------------------+             |
 | |  GuardDuty, SecHub   |        +---------------------+   OU Sandbox | OU PolicyStaging (scp-test)          |
 | |  CSPM, Access Analyzer (delegated admin)              |   OU Suspended (DenyAll SCP)                        |
 | +----------------------+                                                                                   |
 +-----------------------------------------------------------------------------------------------------------+
  SCPs @Root: ProtectSecurityBaseline, DenyRoot, DenyLeaveOrg | @Workloads+Infrastructure: RegionAllowList,
  RequireIMDSv2, DenyIAMUsers | RCP @Root: org identity perimeter (+ Beacon provisioning account exception)
```

Inside a workload VPC: three private subnets, no IGW, no NAT; free S3/DynamoDB gateway endpoints; interface endpoints (STS, SSM, SSM Messages, EC2 Messages, Logs, KMS, ECR API/DKR) in an endpoint subnet whose security group allows 443 from the VPC only; endpoint policies allow org principals only.

| Component | Responsibility | Technology | Why | Alternative considered |
|---|---|---|---|---|
| Org + OUs | Grouping, policy inheritance | AWS Organizations | Needed for SCPs, RCPs, delegated admin | Control Tower (ADR-2) |
| Guardrails | Preventive controls in member accounts | SCPs + one RCP | Apply regardless of in-account IAM | Permission boundaries (account admins can bypass) |
| Workforce identity | MFA, group-based roles | Identity Center + Entra ID | One IdP, no IAM users | Direct SAML per account |
| Audit archive | Tamper-resistant logs | Org trail → S3 Object Lock + SSE-KMS | Separate account survives a compromised workload admin | CloudTrail Lake (closed to new customers since 2026-05-31) |
| Detection | Threats and posture | GuardDuty, Security Hub CSPM, Access Analyzer | Managed, org-wide, delegated | Third-party CNAPP |
| IaC + state | Reviewable change, locking | OpenTofu 1.12; S3 `use_lockfile`; KMS | ADR-1, ADR-3 | HCP Terraform; DynamoDB locks |
| Gates + drift | Stop bad plans; catch console edits | Checkov + Conftest; nightly `plan -detailed-exitcode` | ADR-4 | Sentinel (HCP-only) |

**ADR-1: IaC engine.** *Options:* Terraform 1.16 (BSL 1.1), OpenTofu 1.12 (MPL 2.0), CloudFormation StackSets. *Choice:* OpenTofu, written to the compatible core. *Consequences:* client-side state/plan encryption and `enabled`; no Terraform-only `action`/`query` blocks; README records that Terraform 1.16 was tested on M1-M7.

**ADR-2: Hand-built org vs Control Tower.** *Choice:* hand-built, because Cobalt wants every guardrail under its own review and a learning project must expose every part. *Consequences:* you own the new-account baseline. At handover, recommend Control Tower if the customer's platform team is small.

**ADR-3: State.** *Choice:* S3 in `automation` with `use_lockfile = true`, SSE-KMS, versioning, plus OpenTofu encryption under a second key; bootstrap runs once on local state and is migrated. *Consequences:* S3 read access alone reveals nothing; the management account holds no state.

**ADR-4: Gates on plan JSON with Checkov and Conftest.** Modules and `for_each` hide real values until plan time. Checkov supplies maintained checks; Conftest encodes Cobalt's rules (tags, Regions, public access, KMS on log stores). *Consequences:* two tools to pin, plus an exception process (inline skip + ticket) the security architect reviews monthly.

**ADR-5: Home Region.** *Choice:* us-east-2 home, us-west-2 second; Identity Center replicated to us-west-2 (multi-Region replication GA 2026-02-03; needs a multi-Region KMS key). *Consequences:* global control planes (IAM, Organizations, Route 53) still sit in us-east-1, so break-glass must not depend on Identity Center.

### 4. Tools & technologies

| Tool | Version / status (Sept 2026) | Notes |
|---|---|---|
| OpenTofu | 1.12.6; 1.13.0-rc1 | Encryption since 1.7; S3 native locking since 1.10 |
| `hashicorp/aws` | 6.66.0 | Per-resource `region` argument since v6 |
| Checkov | 3.3.19 | `--framework terraform_plan` |
| Conftest / OPA | 0.70.1 / 1.21 | Rego v1 keywords (`if`, `contains`) mandatory |
| TFLint | 0.64.0 | AWS ruleset |
| Trivy (optional) | 0.74.0 | Absorbed tfsec; compromised 2026-03-19..23 (GHSA-69fq-xp46-6x23), so pin by digest |
| GitHub Actions | checkout v7.0.1, configure-aws-credentials v6.3.0, setup-opentofu v2.0.2 | Pin full SHAs; Node 20 actions stopped working 2026-09-23 |
| Security Hub | Original service renamed **Security Hub CSPM**; new Security Hub GA 2025-12-02 | This build configures CSPM in code |
| CloudTrail | Trails supported; Lake closed to new customers 2026-05-31 | Query the archive with Athena |

### 5. Step-by-step implementation plan

Layout: `bootstrap/`, `org/`, `identity/`, `logging/`, `security/`, `modules/vpc/`, `guardrails/`, `policy/` (Rego + tests + `.checkov.yaml`), `tests/scp/`, `.github/workflows/`.

**M1 — Bootstrap and encrypted state.** Harden the management account by hand (hardware MFA on root, alternate contacts, two break-glass IAM users whose passwords are sealed with two different officers). Apply `bootstrap/` with local state: organization, `automation` account, state bucket, two KMS keys. Then add the blocks below and run `tofu init -migrate-state`.

```hcl
terraform {
  backend "s3" {
    bucket       = "cobalt-lz-tfstate-us-east-2"
    key          = "org/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    kms_key_id   = "alias/lz-tfstate-sse"
    use_lockfile = true
  }
  encryption {
    key_provider "aws_kms" "state" {
      kms_key_id = "alias/lz-tfstate-encryption"
      region     = "us-east-2"
      key_spec   = "AES_256"
    }
    method "aes_gcm" "state" { keys = key_provider.aws_kms.state }
    state {
      method   = method.aes_gcm.state
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
```

Create `lz-plan` (read-only, trusted from PRs) and `lz-deployer` (write, trusted only from the `prod` environment with two required reviewers); the split is your SOX segregation-of-duties evidence. Cobalt's repo was created after 2026-07-15, so GitHub issues the immutable ID-based `sub`; a `repo:cobalt-bank/landing-zone:*` pattern would never match:

```json
{ "Effect": "Allow",
  "Principal": { "Federated": "arn:aws:iam::222233334444:oidc-provider/token.actions.githubusercontent.com" },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": { "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub": "repo:cobalt-bank@81234567/landing-zone@90876543:environment:prod" } } }
```

*Done when:* `aws s3 cp s3://cobalt-lz-tfstate-us-east-2/org/terraform.tfstate - | grep -c '"arn:aws'` prints `0`, and an apply attempted from a PR branch fails on `sts:AssumeRoleWithWebIdentity`.

**M2 — OUs and accounts.** `aws_organizations_organizational_unit` with `for_each` over the OU list, and `aws_organizations_account` per account (`close_on_deletion = false`, `lifecycle { prevent_destroy = true }`). Every account needs a unique email (use plus-addressing), and a closed account stays suspended for 90 days. *Done when:* `aws organizations list-accounts --query 'Accounts[].[Name,Status]' --output text` lists seven `ACTIVE` accounts.

**M3 — SCPs, RCP, tag policy.** Three rules to remember: SCPs never restrict the management account; one SCP document is at most 5,120 characters; at most five SCPs attach to one target. Region allow-list (start from AWS's current example, since the global-service list changes):

```json
{ "Version": "2012-10-17",
  "Statement": [{ "Sid": "RegionAllowList", "Effect": "Deny",
    "NotAction": ["account:*","budgets:*","ce:*","cloudfront:*","globalaccelerator:*","health:*","iam:*",
                  "organizations:*","route53:*","route53domains:*","shield:*","sso:*","sts:*","support:*",
                  "trustedadvisor:*","waf:*","wafv2:*","s3:GetAccountPublicAccessBlock",
                  "s3:PutAccountPublicAccessBlock","s3:ListAllMyBuckets"],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": { "aws:RequestedRegion": ["us-east-2", "us-west-2"] },
      "ArnNotLike": { "aws:PrincipalArn": ["arn:aws:iam::*:role/lz-deployer", "arn:aws:iam::*:role/cobalt-breakglass"] } } }] }
```

`ProtectSecurityBaseline` denies `cloudtrail:StopLogging|DeleteTrail|UpdateTrail`, `guardduty:DeleteDetector|UpdateDetector|DisassociateFromAdministratorAccount`, `securityhub:DisableSecurityHub`, `config:StopConfigurationRecorder|DeleteConfigurationRecorder`, `access-analyzer:DeleteAnalyzer` and `organizations:LeaveOrganization` to everyone except `lz-deployer`. It must also protect the exempt role names themselves: deny `iam:CreateRole`, `iam:UpdateAssumeRolePolicy`, `iam:AttachRolePolicy`, `iam:PutRolePolicy` and `iam:DeleteRole` on `arn:aws:iam::*:role/lz-deployer` and `arn:aws:iam::*:role/cobalt-breakglass` to every other principal. Otherwise an account admin creates a role with an exempt name and walks around every SCP that uses `ArnNotLike`. `DenyRoot` denies `*` where `aws:PrincipalArn` is like `arn:aws:iam::*:root`. The RCP adds the resource-side perimeter. Within one condition operator the keys are ANDed, so the deny fires only for callers outside the org *and* outside Beacon's provisioning account:

```json
{ "Version": "2012-10-17",
  "Statement": [{ "Sid": "OrgIdentityPerimeter", "Effect": "Deny", "Principal": "*",
    "Action": ["s3:*", "kms:*", "sts:AssumeRole", "sqs:*", "secretsmanager:*"],
    "Resource": "*",
    "Condition": {
      "StringNotEqualsIfExists": { "aws:PrincipalOrgID": "o-cobalt0example", "aws:PrincipalAccount": ["111122223333"] },
      "BoolIfExists": { "aws:PrincipalIsAWSService": "false" } } }] }
```

Attach every new policy to PolicyStaging first and run the harness (section 7); promoting to Workloads is a CAB change. *Done when:* in `scp-test`, `aws ec2 describe-instances --region eu-west-1` fails with `explicit deny in a service control policy`, and the same call in us-east-2 succeeds.

**M4 — Identity Center.** Set the identity source to Entra ID (SAML metadata exchange plus SCIM provisioning from the Entra enterprise app; manual on both sides, so screenshot it into the runbook). Replicate a customer-managed multi-Region KMS key to us-west-2, then add the Identity Center replica there. Define `aws_ssoadmin_permission_set` (`ReadOnly`, `SecurityAudit`, `PlatformAdmin` with `session_duration = "PT1H"`) and `aws_ssoadmin_account_assignment` with `principal_type = "GROUP"` only. Production gets ReadOnly and SecurityAudit; production admin is an Entra PIM-approved group that SCIM syncs. *Done when:* a test user in the Entra group assumes ReadOnly in `fraud-prod` from the access portal, and `tests/iam_users.py` finds zero IAM users in all member accounts.

**M5 — Log archive and org trail.** In `log-archive`: versioned bucket, Object Lock (governance mode, 1-day retention in the lab), SSE-KMS, 400-day lifecycle. The bucket policy allows `cloudtrail.amazonaws.com` `s3:GetBucketAcl` on the bucket and `s3:PutObject` on both `AWSLogs/<mgmt-account-id>/*` and `AWSLogs/o-cobalt0example/*`, each with `s3:x-amz-acl = bucket-owner-full-control` and an `aws:SourceArn` pin to the trail ARN (the confused-deputy guard). The trail key policy grants CloudTrail `kms:GenerateDataKey*` under the same condition.

```hcl
resource "aws_cloudtrail" "org" {
  name                          = "cobalt-org-trail"
  s3_bucket_name                = var.log_archive_bucket
  kms_key_id                    = var.trail_kms_key_arn
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}
```

*Done when:* within 15 minutes of an API call in `fraud-nonprod`, an object exists under `AWSLogs/o-cobalt0example/<account-id>/CloudTrail/us-east-2/`, and `aws cloudtrail validate-logs` reports every digest valid.

**M6 — Delegated security services.** From the management account, register `security-tooling` as delegated admin for GuardDuty, Security Hub CSPM, Access Analyzer and Config. Then apply the org configuration *inside* `security-tooling` through a provider alias:

```hcl
resource "aws_guardduty_organization_configuration" "this" {
  provider                         = aws.security_tooling
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.admin.id
}
resource "aws_securityhub_organization_configuration" "this" {
  provider              = aws.security_tooling
  auto_enable           = false
  auto_enable_standards = "NONE"
  organization_configuration { configuration_type = "CENTRAL" }
  depends_on            = [aws_securityhub_finding_aggregator.this]
}
resource "aws_securityhub_configuration_policy" "baseline" {
  provider = aws.security_tooling
  name     = "cobalt-baseline"
  configuration_policy {
    service_enabled       = true
    enabled_standard_arns = ["arn:aws:securityhub:us-east-2::standards/aws-foundational-security-best-practices/v/1.0.0"]
    security_controls_configuration { disabled_control_identifiers = [] }
  }
  depends_on = [aws_securityhub_organization_configuration.this]
}
```

Associate the policy with the org root (`aws_securityhub_configuration_policy_association`). Get further standard ARNs (CIS, PCI DSS) from `aws securityhub describe-standards` rather than typing them. Enable the new Security Hub from the admin account and record in an ADR that it stays outside IaC until your provider version has a v2 resource. *Done when:* `aws guardduty list-members --detector-id <id>` shows every account `Enabled`, and `aws guardduty create-sample-findings` in `fraud-nonprod` surfaces in `security-tooling` within 5 minutes.

**M7 — Workload VPC module.** Private and endpoint subnets across three AZs, gateway endpoints, `aws_vpc_endpoint` interface endpoints via `for_each` with `private_dns_enabled = true`, flow logs to `log-archive`, and a rule-less default security group. Every endpoint gets this policy:

```hcl
data "aws_iam_policy_document" "endpoint_org_only" {
  statement {
    actions   = ["*"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.org_id]
    }
  }
}
```

*Done when:* on a t4g.nano in a private subnet, reached only through SSM Session Manager, `aws sts get-caller-identity --region us-east-2` succeeds and `curl -m 5 https://example.com` times out. Destroy the instance and interface endpoints the same day.

**M8 — Tags, budgets, gates, drift.** Put `default_tags` (`cost-center`, `owner`, `environment`, `data-classification`) on every provider, activate them with `aws_ce_cost_allocation_tag`, and create budgets per account and per cost center (`TagKeyValue` filter `user:cost-center$fraud-analytics`) that alert at 50/80/100%. Add Conftest rules; the tag rule:

```rego
package main

required_tags := {"cost-center", "owner", "environment", "data-classification"}

deny contains msg if {
  some rc in input.resource_changes
  rc.mode == "managed"
  some action in rc.change.actions
  action in {"create", "update"}
  tags := object.get(rc.change.after, "tags_all", null)
  is_object(tags)
  missing := required_tags - {k | some k, _ in tags}
  count(missing) > 0
  msg := sprintf("%s is missing required tags %v", [rc.address, missing])
}
```

Seed 10 violating PRs (untagged bucket, public-access block off, trail without validation, 0.0.0.0/0 ingress, unencrypted log bucket, and five more) and 5 compliant PRs. The nightly drift job runs `tofu plan -detailed-exitcode` (0 = clean, 1 = error, 2 = drift) and opens a `drift` issue on exit code 2. *Done when:* 10/10 seeded PRs fail with a named rule, 5/5 compliant PRs pass, and a console edit produces a `drift` issue by the next morning.

### 6. Deployment instructions

**Order.** `bootstrap` → `org` → `identity` → `logging` → `security` → workload stacks (VPC module) → `guardrails`. Production applies happen only in approved CAB windows, from `main`, through `lz-deployer`.

**Environment.** Create `lz.env` with the contents below (it holds no secrets because credentials come from Identity Center locally and OIDC in CI), then load it in every new shell:

```text
# lz.env (file contents; load with source, do not paste line by line)
export AWS_PROFILE=cobalt-mgmt-admin
export AWS_REGION=us-east-2
export AWS_CA_BUNDLE=/etc/ssl/certs/cobalt-root-ca.pem        # AWS CLI/boto3 behind the TLS-inspecting proxy
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/cobalt-root-ca.pem   # Checkov
export HTTPS_PROXY=http://proxy.cobalt.example:8080
export NO_PROXY=169.254.169.254,localhost,127.0.0.1
```

```bash
source lz.env
```

Per stack (shown for `org`):

```bash
tofu -chdir=org init -input=false
```

```bash
tofu -chdir=org plan -input=false -out=org.tfplan -var-file=../env/cobalt.tfvars
```

```bash
tofu -chdir=org show -json org.tfplan > org.plan.json
```

```bash
checkov -f org.plan.json --framework terraform_plan --config-file policy/.checkov.yaml
```

```bash
conftest test org.plan.json --policy policy/
```

```bash
tofu -chdir=org apply org.tfplan
```

**CI.** The PR workflow runs the same steps per stack in a matrix with `permissions: { contents: read, id-token: write }`, assumes `lz-plan`, and pins actions by SHA (`actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`, `opentofu/setup-opentofu@a1320f892987e89d278cc92dc5adc984fb93aca4 # v2.0.2`, `aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0`). Checkov and Conftest are baked into the runner image and verified by checksum, so no scanner is downloaded at run time. The apply workflow runs on merge with `environment: prod`, re-plans and applies; it never applies a PR-built plan.

**Verify.**

```bash
uv run --with boto3 --with pytest pytest tests/scp -q
```

**Rollback.** Revert the merge commit and let the pipeline apply it. The one fast path, for an SCP that blocks production, is detaching it with management-account credentials and filing a retroactive emergency change:

```bash
aws organizations detach-policy --policy-id p-regionallow --target-id ou-wkld-exampleid
```

**Teardown.** Destroy interface endpoints first (hourly billing). Before the trials end, set GuardDuty/Security Hub CSPM auto-enable to `NONE`, disassociate members, destroy `security`. Empty the log bucket (governance-mode objects need `s3:BypassGovernanceRetention`, or wait out the 1-day retention), destroy `logging` and `identity`, close member accounts with `aws organizations close-account` (rate-limited; closed accounts stay suspended 90 days), then delete the organization.

### 7. Testing & validation

| Test | Tool | Pass threshold |
|---|---|---|
| VPC module unit tests | `tofu test` with `mock_provider "aws" {}` (3 private subnets, no public IPs, private DNS on every endpoint) | 100%, $0 |
| Rego unit tests | `conftest verify --policy policy/` | Every rule has a firing and a silent fixture; 100% |
| Seeded-PR gates | CI on 15 fixture branches | 10/10 blocked, 0/5 false blocks |
| SCP/RCP integration | Python harness in `scp-test` | ≥20 cases, 100%, on every policy change |
| Log delivery | API call, then poll S3 | ≤15 min; `validate-logs` all valid |
| Detection path | `create-sample-findings` | Alert ≤10 min |
| Drift | Console edit to a canary resource | Issue ≤24 h |
| Break-glass | Quarterly drill without Identity Center | Sign-in works; alert ≤5 min |

Harness core (`tests/scp/test_scp.py`). Assert on the phrase `service control policy`: a generic `AccessDenied` could come from the runner role's own IAM policy and pass for the wrong reason.

```python
import os
import boto3
import pytest
from botocore.exceptions import ClientError

@pytest.fixture(scope="session")
def session():
    acct = os.environ["SCP_TEST_ACCOUNT_ID"]
    c = boto3.client("sts").assume_role(RoleArn=f"arn:aws:iam::{acct}:role/scp-test-runner",
                                        RoleSessionName="scp-harness")["Credentials"]
    return boto3.Session(aws_access_key_id=c["AccessKeyId"], aws_secret_access_key=c["SecretAccessKey"],
                         aws_session_token=c["SessionToken"])

DENIED = [
    ("ec2", "eu-west-1", "describe_instances", {}),
    ("iam", "us-east-2", "create_user", {"UserName": "scp-harness-should-fail"}),
    ("guardduty", "us-east-2", "delete_detector", {"DetectorId": "0" * 32}),
]

@pytest.mark.parametrize("svc,region,op,kwargs", DENIED)
def test_denied_by_scp(session, svc, region, op, kwargs):
    with pytest.raises(ClientError) as exc:
        getattr(session.client(svc, region_name=region), op)(**kwargs)
    assert "service control policy" in str(exc.value)

def test_allowed_in_home_region(session):
    session.client("ec2", region_name="us-east-2").describe_instances()
```

### 8. Observability & operations

- **Instrumentation.** EventBridge in `security-tooling` routes GuardDuty findings of severity 7 or higher, CRITICAL Security Hub CSPM findings and Access Analyzer external-access findings to the SOC's SNS topic. Rules for root/break-glass `ConsoleLogin` and `organizations:*Policy*` calls live in the management account **in us-east-1**, where IAM, STS global-endpoint and Organizations events are delivered. Drift and harness jobs publish pass/fail metrics.
- **Dashboard.** Compliance score per account; open findings by severity and age; newest trail object per account (delivery lag); drift status per stack; last harness result; budget burn per cost center.
- **Alerts.** Root or break-glass sign-in → page SOC and CoE lead. No trail object for an account in 60 min → page platform on-call. SCP/RCP attach, detach or update → security architect, must match a change ticket. Drift → ticket to the stack owner. Budget 80% forecast → FinOps.
- **Runbook entries.** *Trail delivery stalled:* `aws cloudtrail get-trail-status --name cobalt-org-trail`, read `LatestDeliveryError`, diff the KMS and bucket policies against Git, fix through the pipeline, and record the gap for auditors (missing logs are a PCI DSS Req. 10 finding). *Break-glass used:* confirm on the bridge, pull the session's CloudTrail events, rotate and re-seal within 24 h. *Drift:* find the actor in CloudTrail, codify emergency fixes, revert the rest by applying, never edit state by hand. *SCP blocks legitimate work:* reproduce it in `scp-test`, add the harness case, change the policy through PolicyStaging.

### 9. Security & compliance

| Threat | Control | Residual risk |
|---|---|---|
| Stolen CI credentials | OIDC with exact `sub`; plan/apply role split; `prod` environment with 2 reviewers | Malicious approved PR (CODEOWNERS on `org/policies/`) |
| Workload admin disables logging/detection | Root SCP; trail owned by management account | Management-account compromise; keep it empty, alert on every sign-in |
| Log tampering | Separate account, Object Lock, KMS, log validation | Governance mode is bypassable; use compliance mode in production |
| Exfiltration to foreign accounts | RCP perimeter + org-only endpoint policies | Services not yet covered by RCPs |
| Confused deputy on bucket/keys | `aws:SourceArn` / `aws:SourceOrgID` | Misconfiguration, caught by Conftest |

**Compliance mapping (proposed; Cobalt's assessors decide what counts).** PCI DSS v4.0.1 Req. 7-8 (8.4.2 MFA for CDE access) → Identity Center permission sets plus Entra conditional access. Req. 10 (10.5.1 retention) → org trail, Object Lock, 400-day lifecycle, `validate-logs` output. SOX ITGC change management → PRs with required reviews linked to CAB tickets; SOX access → group-only assignments plus quarterly export. NYDFS Part 500 MFA and asset inventory → Entra MFA; Config aggregator. DORA ICT third-party risk (register of information, Art. 30 contract terms) → `vendor=beacon` tags and the documented RCP exception. Background: [M15](../../01-curriculum/M15-security-and-compliance.md).

### 10. Extensions for advanced learners

1. **T3: Account vending by PR** from an `accounts/*.yaml` catalog. *Hard because* account creation is asynchronous and a partial failure leaves a live account you can't simply delete.
2. **T3: Complete the data perimeter** with `aws:ResourceOrgID` on identity policies. *Hard because* AWS services acting on your behalf and vendors like Beacon need precise exceptions, and a mistake looks like an application bug.
3. **T3: Dual-engine CI** (OpenTofu and Terraform), diffing the plans. *Hard because* the engines diverge (encryption, `enabled`, `action`), so staying in the common core has to be enforced.
4. **T4: Control Tower migration** of this org without recreating accounts. *Hard because* existing trails, Config recorders and OUs collide with what Control Tower wants to own.
5. **T4: Signed nightly evidence pack** in the log archive. *Hard because* auditors need point-in-time evidence that stays defensible later, and not every control is observable through an API.

### 11. How to demonstrate it in interviews

**2-minute pitch.** "A bank had bought our platform but couldn't go live: it had no governed AWS footprint, and two shadow accounts had become an audit finding. With their platform team I built the organization as code in OpenTofu, with encrypted state and OIDC-only CI. It has seven accounts, Entra federation with zero IAM users, an org trail into an Object Lock archive, delegated GuardDuty and Security Hub, and SCPs plus a resource control policy. What I'd highlight is the evidence: 24 SCP cases that assert *which* policy denied a call, gates that blocked 10 of 10 seeded violations with no false blocks, and nightly drift detection. Audit accepted the PR history as change evidence. Next time I'd bring the auditors in during week one."

**10-minute demo.** (1) OU diagram and SCP layers. (2) One SCP: `NotAction` and the principal exemption. (3) Run the harness live. (4) A seeded PR failing Conftest. (5) Grep the raw state object for ARNs: zero hits. (6) An API call arriving in the log archive. (7) A GuardDuty sample finding in the admin account. (8) Last night's drift issue. (9) The compliance mapping and one evidence file. (10) What you'd change.

**Likely questions.**
1. *"Why not Control Tower?"* Cobalt wanted every guardrail in its own review flow; for a thin platform team I'd recommend Control Tower plus custom SCPs, and explain who then owns drift.
2. *"How do you test an SCP?"* PolicyStaging OU, a dedicated account, deny and allow cases that assert the denying policy type. Over-denying is an outage; under-denying is a finding.
3. *"What doesn't an SCP protect?"* The management account and service-linked roles. Hence an empty management account and the RCP on the resource side.
4. *"Secrets in state?"* None by design; use ephemeral values and write-only arguments where needed. State is also encrypted client-side.
5. *"GuardDuty fires during the quarter-end freeze. Now what?"* Detection never freezes; response uses the emergency-change path with retroactive CAB approval, recorded by the same pipeline.

**Artifacts.** OU diagram, ADRs, harness output, seeded-PR results, raw-state screenshot, log-delivery timings, compliance mapping. **Metrics.** Harness pass rate, block and false-block rates, log-delivery p95, drift detection time, vending time, monthly cost. **Differently.** Agree the evidence format with Internal Audit before coding, and start with compliance-mode Object Lock in a dedicated production archive.

### 12. Common failure points while building

1. **The OIDC trust never matches.** New repos use `repo:owner@ID/repo@ID:...`. *Fix:* decode a real token in a debug step and match that exact `sub`.
2. **Org trail delivery error.** The KMS key policy lacks `kms:GenerateDataKey*` for CloudTrail, or the bucket policy lacks the org prefix. *Fix:* both statements, both pinned with `aws:SourceArn`.
3. **The Region SCP breaks global services.** *Fix:* start from AWS's current example and test real console flows in PolicyStaging.
4. **Delegated-admin config applied in the wrong account.** *Fix:* a provider alias into `security-tooling`, plus a `check` block that asserts the caller account.
5. **The RCP locks out the vendor.** Beacon's provisioner gets `AccessDenied` on `sts:AssumeRole`. *Fix:* an account-scoped exception recorded in the DORA register; never disable the RCP.
6. **Alerts that never fire.** IAM/Organizations events arrive in us-east-1, not us-east-2. *Fix:* put those EventBridge rules in us-east-1.
7. **ECR pulls and SSM agent updates fail inside the workload VPC.** The org-only policy on the S3 gateway endpoint also blocks AWS-owned buckets: ECR image layers are served from `prod-us-east-2-starport-layer-bucket`. *Fix:* add an endpoint-policy statement allowing `s3:GetObject` on `arn:aws:s3:::prod-us-east-2-starport-layer-bucket/*` (plus the SSM and OS-package buckets you actually use), and cover it with a harness case that pulls an image from a private subnet.

### Appendix P05-A — Azure variant

Cobalt's Azure estate gets the same controls with different semantics. Build it with the Azure Verified Modules pattern module `Azure/avm-ptn-alz/azurerm` (0.21.0); `caf-enterprise-scale` was scheduled for archive on 2026-08-01.

| AWS (P05) | Azure | Difference to explain |
|---|---|---|
| OUs | Management groups | Subscriptions are the account equivalent |
| SCP (deny-only) | Azure Policy `deny` | Policy can also `audit`, `modify`, `deployIfNotExists` |
| Identity Center | Entra ID + Azure RBAC | No federation hop |
| JIT elevation | Entra ID PIM | Needs Entra ID P2 or Entra ID Governance |
| Org trail | Activity Log + diagnostic settings to Log Analytics and immutable storage | Diagnostic settings are deployed per resource type |
| GuardDuty/Security Hub CSPM | Defender for Cloud plans | Enabled per subscription and plan |

```hcl
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  management_group_id  = azurerm_management_group.landing_zones.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  parameters           = jsonencode({ listOfAllowedLocations = { value = ["eastus2", "centralus"] } })
}

resource "azurerm_pim_eligible_role_assignment" "platform_contributor" {
  scope              = azurerm_management_group.landing_zones.id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = data.azuread_group.cloud_platform.object_id
  schedule {
    start_date_time = time_static.now.rfc3339
    expiration { duration_hours = 8 }
  }
  justification = "Eligible, not active, Contributor"
}
```

Set the PIM role settings (MFA on activation, approval by the security architect, 4-hour maximum, ticket number). Two current traps: VNets created with API versions after 2026-03-31 get private subnets with no default outbound access, so VMs need a NAT gateway or firewall route; and old scripts say "Azure AD", but the product is Microsoft Entra ID (APIs unchanged). *Done when:* a deployment to `westeurope` is denied by `allowed-locations`, and Contributor activation requires MFA and approval, visible in the Entra audit log.

---

