# CLAUDE.md: rules for building P05 (Secure Landing Zone as Code) in this repo

This repo is where **P05, the Secure Landing Zone as Code** from the FDE Onboarding Handbook gets built with **Claude Code running locally on Windows 11**. The build is meant to teach, not only to produce code. `docs/CLAUDE_CODE_BUILD_PROMPT.md` is the task; follow its teaching protocol exactly.

## Source of truth
- `spec/P05-secure-landing-zone-as-code.md` is the P05 spec (sections 1–12 plus Appendix P05-A, the Azure variant; milestones M1–M8 with "Done when" gates). The spec wins over memory.
- `spec/ground-truth-digest.md` lists verified versions and dates as of September 2026, plus traps. For P05 these include: Terraform is BSL and IBM-owned while OpenTofu is MPL; tfsec now lives in Trivy (and Trivy was compromised 2026-03-19..23, so pin it by digest); Security Hub is now "Security Hub CSPM"; CloudTrail Lake is closed to new customers; Azure AD is now Entra ID; Node 20 GitHub Actions no longer run; GitHub OIDC `sub` claims are ID-based for repos created after 2026-07-15.
- `spec/reference-C11-infrastructure-as-code.md` is curriculum background (state, modules, testing, policy as code).
- `spec/sources.md` holds the external references. Relative links inside `spec/` point into the handbook repo; ignore them.
- If a version, resource argument or API behaves differently when you actually run it, show the evidence, propose a fix, and record it in `docs/DEVIATIONS.md`. Never change it silently.

## THIS PROJECT CHANGES A REAL AWS ACCOUNT: read this twice
- P05 creates an **AWS Organization** and **member accounts**, attaches **SCPs/RCPs that can lock people out**, enables org-wide security services, and writes an **Object Lock** bucket. Closing member accounts is slow and rate-limited: closed accounts sit suspended for 90 days, and only a limited share of member accounts can be closed per rolling 30 days. Object Lock retention cannot be shortened once set. Creating an organization also moves a Free-plan account to the Paid plan.
- **Use a dedicated, brand-new AWS account** as the management account. Never use an employer's or an existing personal production account. Confirm this with me explicitly before M1.
- **Two modes. Default is OFFLINE:**
  - **OFFLINE (default):** write all HCL; run `tofu init -backend=false`, `tofu validate`, `tofu fmt -check`, TFLint, Checkov and Conftest, and plan against mocks where possible (`tofu test` with `mock_provider`). Nothing touches AWS. Gates that need real AWS are recorded as "not run (offline)".
  - **LIVE:** only after I type the exact phrase `go live for M<n>` for that milestone. Then every `tofu apply` (and any mutating AWS CLI call) is preceded by a saved plan (`tofu plan -out`), a plain-English summary of every resource it creates, changes or destroys, and an estimated cost. Claude Code's permission prompt will also stop you; that is intentional (`.claude/settings.json`). I approve each apply individually.
- Account count: the spec lists 7 accounts. In LIVE mode, propose creating only what the current milestone needs (start with `log-archive`, `security-tooling` and `scp-test`), and get my OK for each additional account. Account emails use plus-addressing on an address I give you.
- Test every SCP in `scp-test` under the PolicyStaging OU first. Never attach a new deny policy to the root or to Workloads without my explicit OK. Keep a written break-glass path: the management account is never restricted by SCPs.
- Costs: follow the spec's cost table. Create interface endpoints only for the M7 test and destroy them the same session. No NAT gateways. GuardDuty and Security Hub CSPM are on trial; note the trial end dates in BUILD_LOG.
- Teardown is its own milestone (M9) with a written plan. Never run `tofu destroy` or `aws organizations close-account` without my explicit OK for that exact command.

## Identity (FR-4)
The spec federates IAM Identity Center with Entra ID (SAML + SCIM). If I don't have an Entra tenant, use the **Identity Center built-in directory** with groups, and record it as a deviation. The permission-set and group-assignment code stays identical, and the Entra steps are written up as a runbook.

## This machine (checked 2026-10-07)
| Tool | Found | Needed | Action |
|---|---|---|---|
| Claude Code | 2.1.261 | current | OK |
| AWS CLI | 2.34.48 | v2 | OK; configure **SSO / Identity Center** login (`aws configure sso`), never long-lived keys |
| OpenTofu | **missing** | 1.12.x | `winget install OpenTofu.Tofu` (or the GitHub release) |
| Terraform | 1.15.3 | optional | Spec code is OpenTofu 1.12 / Terraform 1.16-compatible. Use `tofu`; keep Terraform only for comparison (licence note: BSL) |
| TFLint | **missing** | 0.64.x | GitHub release into `tools/bin/` |
| Checkov | **missing** | 3.3.x | `uv tool install checkov==3.3.*` |
| OPA / Conftest | **missing** | 1.21 / 0.70.x | GitHub releases into `tools/bin/` |
| Trivy | **missing** | optional | Container image pinned by **digest** only (see the compromise note) |
| Python / uv | 3.12 / 0.11.7 | 3.14 via uv | `uv python install 3.14` |
| gh | 2.94.0, logged in | for M8 CI | OK |
Run `pwsh -File scripts/check-prereqs.ps1` at the start of every session.

## Windows specifics
- Use PowerShell 7 by default. The spec's `lz.env` is bash-style. Create a PowerShell equivalent, `lz.env.ps1`, that sets `$env:AWS_PROFILE`, `$env:AWS_REGION` and, if I'm behind a proxy, `$env:HTTPS_PROXY` and `$env:AWS_CA_BUNDLE`. Both files are gitignored.
- Long operations (`tofu apply` of the org stack, waiting for account creation, waiting for CloudTrail delivery up to 15 min) run in the background and are polled.

## Safety rules (non-negotiable)
- Never create IAM access keys and never create IAM users from code. The spec's M1 break-glass users (console password + hardware MFA, no access keys) are created **by me, by hand**; you write the runbook and verify the result read-only. Never store AWS secrets in files, never print credentials or read `.tfstate` contents into the conversation (state can hold sensitive values). Use `tofu output` or `tofu state list` for inspection.
- Never kill processes by name. Never run destructive commands outside this project.
- Never weaken a guardrail to make a gate pass. If an SCP blocks something legitimate, explain why and propose a scoped exception for me to approve.
- No force-push or history rewrite. Commit after each milestone. Push or open PRs only when I ask (M8's CI needs a GitHub repo; ask me first).

## Working style
- Teaching protocol: brief → build one file at a time and explain it → explain each command and its expected output → run the gate (offline or live) → log in `docs/BUILD_LOG.md` → commit → checkpoint quiz → STOP and wait for "next".
- Conventional commits: `feat(m3-guardrails): region allow-list and deny-root SCPs`, `ci(m8): conftest gate on plan json`.
