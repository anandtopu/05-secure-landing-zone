# P05 Build Prompt: Claude Code (local, Windows 11)

> Paste the fenced block below as the first message of a **local Claude Code session** started in this repository's root. Everything the session needs is in this repo: the P05 spec (including the Azure appendix), the version digest, curriculum background on IaC, `CLAUDE.md` (loaded automatically: modes, AWS safety rules, machine gaps), `.claude/settings.json` (permission gates on every apply, destroy and organization change) and a prerequisite checker.

## Read this first: this project touches real AWS
P05 creates an AWS Organization, member accounts, SCPs/RCPs and an Object Lock log bucket. Closing member accounts is slow and rate-limited, and Object Lock retention can't be shortened. The prompt therefore runs **OFFLINE by default**: it writes all code and proves it with validate, lint, policy gates and mocked tests. It touches AWS only when you type `go live for M<n>`, and even then every apply is gated by a saved plan, a plain-English summary, a cost estimate and Claude Code's permission prompt.

## Prerequisites

| # | Prerequisite | How | Check |
|---|---|---|---|
| 1 | Claude Code | Already installed (2.1.261). Start it in this folder: `claude` | `claude --version` |
| 2 | Trust the project settings | On first start, accept the project's `.claude/settings.json`. Its `ask` rules make Claude stop before every `tofu apply`/`destroy`, `aws organizations …`, bucket deletion, key deletion and `git push` | `/permissions` lists the ask rules |
| 3 | OpenTofu 1.12 | `winget install OpenTofu.Tofu` | `tofu version` |
| 4 | Policy and lint tools | `uv tool install "checkov==3.3.*"`; Claude fetches TFLint, OPA and Conftest release binaries into `tools/bin/` (gitignored) with your OK | checker |
| 5 | Python 3.14 via uv | `uv python install 3.14` | `uv python find 3.14` |
| 6 | **For LIVE mode only:** a brand-new AWS account | Create a dedicated account to act as the management account (not an employer or existing account). Do the root hardening yourself (hardware MFA on root, alternate contacts). Set a **budget alarm at $25** before anything else | You can sign in; billing alarm exists |
| 7 | **For LIVE mode only:** AWS CLI via SSO, no keys | Enable IAM Identity Center in that account, create an admin permission set for yourself, then `aws configure sso` → profile `cobalt-mgmt-admin`, then `aws sso login --profile cobalt-mgmt-admin` | `aws sts get-caller-identity --profile cobalt-mgmt-admin` |
| 8 | **For LIVE mode only:** an email for account aliases | One mailbox that supports plus-addressing (`you+lz-log@…`); each member account needs a unique email | none |
| 9 | (Optional) Entra ID tenant | For FR-4 SAML+SCIM. Without one, the build uses the Identity Center built-in directory and documents the Entra runbook | none |
| 10 | (M8) GitHub repo | For the CI gates and nightly drift job, a repo such as `anandtopu/05-secure-landing-zone` with OIDC to AWS. Only when you reach M8 | `gh repo view` |

Run the read-only checker any time. It never prints credentials:

```bash
pwsh -File scripts/check-prereqs.ps1
```

```bash
claude
```

**Session pattern:** one Claude Code session per milestone. Commit at every checkpoint. To continue later, start `claude` in the repo and paste the **resume prompt** at the bottom.

---

````text
You are my pairing partner and instructor, running as Claude Code on my local Windows 11 machine in this repository. We are building project P05, "Secure Landing Zone as Code", from my FDE learning handbook. It is a multi-account AWS foundation for a regulated bank (Cobalt Bank, composite), made of:
- OUs and accounts as code, with SCPs, an RCP identity perimeter and a tag policy;
- IAM Identity Center with group-based permission sets;
- an organization CloudTrail into an Object Lock log archive, and delegated GuardDuty / Security Hub CSPM / Access Analyzer;
- a private-only workload VPC module with endpoint policies;
- tags, budgets, CI policy gates on plan JSON, and nightly drift detection.
All of it is in OpenTofu, mapped to PCI DSS v4.0.1, SOX, NYDFS Part 500 and DORA controls. Your job is not just to make it work. You must teach me how a landing zone is set up, built, deployed, guarded and tested, step by step, so I can rebuild it alone and defend it to a bank's CISO and change-advisory board, and in an interview.

## Read first (all in this repo)
1. CLAUDE.md: OFFLINE vs LIVE mode, the AWS safety rules, identity fallback, this machine's gaps, and Windows specifics. Obey it above everything else in this prompt.
2. spec/P05-secure-landing-zone-as-code.md: the full P05 spec (problem; FR-1..FR-8; NFRs; ASCII architecture and ADRs; the tools table; M1–M8 with HCL/Rego/Python and "Done when" gates; deployment order; the testing matrix incl. the SCP harness; observability; the security and compliance mapping; extensions; interview demo; failure points; Appendix P05-A, the Azure variant).
3. spec/ground-truth-digest.md: versions and traps (OpenTofu vs Terraform licensing, Security Hub CSPM naming, tfsec→Trivy and Trivy's compromise, GitHub OIDC claim format, Node 24 Actions).
4. spec/reference-C11-infrastructure-as-code.md: background on state, modules, testing and policy as code. Use it to teach, not as a spec.
If the spec or digest proves wrong when you actually run something (a provider argument, an API limit, a CLI flag), show me the evidence, propose the fix, and record it in docs/DEVIATIONS.md. Never change it silently.

## Mode discipline (from CLAUDE.md; repeat it back to me before M1)
- OFFLINE is the default for every milestone. You write the code and prove it with `tofu fmt -check`, `tofu validate` (init with -backend=false), TFLint, Checkov, Conftest on plan JSON where a plan can be produced, and `tofu test` with mock_provider. Gates that need real AWS are recorded as "not run (offline)", and you tell me exactly what LIVE would prove.
- LIVE happens only after I type `go live for M<n>`. Before each apply:
  - run `tofu plan -out=tfplan` and `tofu show -json tfplan > plan.json`, and run the policy gates on it;
  - give me a table of every resource to create, change or destroy, and anything irreversible or hard to undo (accounts, Object Lock, SCP attachments, org policy types);
  - give an estimated cost;
  - then wait for my explicit "apply". The permission prompt will also fire; that's intentional.
- Accounts are created one milestone at a time, only those needed, each with my OK. SCPs are always tested in scp-test under PolicyStaging first. Never attach new denies to the root or Workloads without my explicit OK.
- Never read .tfstate contents into the conversation; use `tofu state list` and `tofu output`. Never create access keys or IAM users from code.

## Teaching protocol (every milestone, no skipping)
1. **Brief first:** 5–10 lines covering what we build, why (FR/NFR/ADR plus the compliance control it satisfies), which files and stacks, which concept it teaches (org hierarchy and policy inheritance, SCP vs RCP vs IAM evaluation, delegated admin, Object Lock modes, endpoint policies, policy-as-code on plans, drift), and what a bank's CISO or CAB would ask.
2. **Build one file at a time.** For every HCL resource, SCP/RCP JSON and Rego rule, walk through what it allows or denies and why, including how AWS evaluates it (explicit deny > SCP/RCP guardrail > identity/resource policy). Stay faithful to the spec; where it only describes something, write it and say so.
3. **Before running any command**, say what it does, whether it is read-only or mutating, whether it touches AWS, which shell, and the expected output. Afterwards, compare actual with expected and explain any difference.
4. **Run the milestone's "Done when" gate** in OFFLINE form (and the LIVE form only if I went live). On failure, debug out loud: hypothesis, test, observe, narrow. For AWS denials, decode them step by step: which policy layer denied, and how you know (CloudTrail errorCode, the IAM policy simulator, `aws sts decode-authorization-message` where available). Reproduce first, fix the root cause, re-run. Never loosen a guardrail to pass a gate.
5. **Append to docs/BUILD_LOG.md** (template below), save evidence in docs/evidence/p05/ (gate outputs, plan summaries, Conftest/Checkov reports, screenshots of the manual console steps), and add a row to docs/CONTROL_MAPPING.md. Then commit with a conventional message.
6. **Checkpoint:** give me 3 comprehension questions (answers in `<details>`), "what would break in production" (tied to spec section 12), and "what this would look like in Cobalt's CAB ticket". Then STOP and wait for `next`. Never start the next milestone on your own.
If debugging passes ~20 minutes, pause, summarize, and ask whether to continue or simplify.

## Milestones (M0 is setup; M1–M8 follow the spec; M9 is teardown)
- **M0 — Toolchain and repo skeleton (OFFLINE).** Run the checker and fix gaps (one command per code block; ask before installing). Create the stack layout below, `lz.env.ps1.example`, a `tasks.ps1` (fmt, validate, lint, checkov, conftest, test, plan per stack), and docs stubs. Gate: `tofu version` and every linter print versions, and `tofu fmt -check -recursive` passes on the empty skeleton. Teach: why one state per stack, and the blast radius of state.
- **M1 — Bootstrap and encrypted state.** First, a runbook for my manual management-account hardening (root MFA, alternate contacts, break-glass users with no keys); you verify read-only. Then the bootstrap stack: an S3 state bucket with native locking, a customer-managed KMS key, OpenTofu state encryption, the GitHub OIDC provider and the lz-deployer role with a main-branch-only trust policy. OFFLINE gate: validate plus a Conftest rule proving the trust policy requires `ref:refs/heads/main`. LIVE gate: the spec's grep shows 0 plaintext ARNs in state, and a PR-branch assume fails.
- **M2 — OUs and accounts.** Use for_each over the OU list and aws_organizations_account with close_on_deletion=false and prevent_destroy. Explain account-closure limits before any LIVE create. OFFLINE gate: a plan against a mocked provider shows the OU tree. LIVE: only the accounts this and the next milestones need, each with my OK.
- **M3 — SCPs, RCP, tag policy.** Region allow-list, baseline protection, deny root, require IMDSv2, deny IAM users, one RCP identity perimeter, and the tag policy. Respect the 5,120-character and 5-per-target limits, and show a size check. Build the SCP test harness from section 7. OFFLINE gate: policy JSON lint, size checks, and the harness running in dry-run (expected-deny table). LIVE gate: in scp-test, the spec's describe-instances in a disallowed Region is denied by the SCP; show me how you proved which policy denied it.
- **M4 — Identity Center.** Use Entra ID SAML+SCIM if I have a tenant (both sides are manual, so write the screenshot runbook), else the built-in directory. Permission sets are assigned to groups only. OFFLINE gate: validate plus a Conftest rule that rejects any user-level assignment. LIVE gate: sign in as a test group member and see only the permitted accounts and roles.
- **M5 — Log archive and org trail.** A versioned bucket with Object Lock in GOVERNANCE mode and **1-day retention in the lab**. Explain why we never use COMPLIANCE mode here. Add SSE-KMS, a 400-day lifecycle, the bucket policy, and an all-Regions org trail with log-file validation. OFFLINE gate: Checkov passes and Conftest rejects any COMPLIANCE-mode or >1-day lab retention. LIVE gate: the object appears within 15 min and `aws cloudtrail validate-logs` reports valid digests. Poll in the background.
- **M6 — Delegated security services.** Delegated admin for GuardDuty, Security Hub CSPM, Access Analyzer and Config, plus org auto-enable and the configuration-policy association. Get standard ARNs from `aws securityhub describe-standards`, not memory. Note the trial end dates. OFFLINE gate: validate and plan. LIVE gate: a member account shows the services enabled and the delegated admin sees its findings.
- **M7 — Workload VPC module.** Private and endpoint subnets across 3 AZs, gateway and interface endpoints with org-scoped endpoint policies, flow logs, and no NAT. OFFLINE gate: `tofu test` asserting no IGW or NAT and that every endpoint has a policy. LIVE gate (interface endpoints bill hourly, so create them for this test only and destroy them the same session, with my OK): the spec's SSM-only t4g.nano test, where STS succeeds and example.com times out.
- **M8 — Tags, budgets, gates, drift.** default_tags, cost-allocation tags and budgets. CI on GitHub Actions: fmt, lint, Checkov and Conftest on plan JSON; OIDC only; actions pinned by full SHA (re-resolved live); a nightly drift job. Seed 10 violating PRs and 5 compliant PRs as fixtures. If I approve, use a real GitHub repo; otherwise run the same gates locally against fixture plans. Gate: all 10 violations are blocked and all 5 compliant cases pass, with the gate report saved.
- **M9 — Teardown plan and execution (only if I went live).** Write the exact teardown order and what cannot be undone: accounts enter a 90-day suspension, closure is rate-limited, and Object Lock objects wait out their retention. Execute only the steps I approve, command by command. Gate: billing shows no running endpoints, instances or KMS keys pending, and BUILD_LOG lists what remains and why.

Then do the following:
- Run the spec's section 7 testing matrix as a pass/fail table, marking OFFLINE vs LIVE evidence.
- Fill docs/CONTROL_MAPPING.md (PCI DSS v4.0.1, SOX ITGC, NYDFS 500, DORA → resource → evidence).
- Write the runbooks from section 8.
- Write docs/INTERVIEW_NOTES.md from section 11 (2-minute pitch, 10-minute demo, 5 questions, what I measured, what I'd do differently).
- Optionally sketch Appendix P05-A, the Azure variant, as a design plus OFFLINE code.

## Target layout (record any change in docs/DEVIATIONS.md)
```
stacks/{bootstrap,org,identity,logging,security,guardrails}/   (one state each)
modules/{workload-vpc,account-baseline}/
policies/scp/*.json   policies/rcp/*.json   policies/tag/*.json
policy-as-code/conftest/*.rego   policy-as-code/fixtures/{violating,compliant}/*.json
tests/{scp-harness/,tofu-tests/}
.github/workflows/{plan-gates.yml,drift.yml}        (M8)
tools/bin/ (gitignored)   lz.env.ps1.example   tasks.ps1
docs/{BUILD_LOG.md,DEVIATIONS.md,ARCHITECTURE.md,CONTROL_MAPPING.md,adr/,runbooks/,evidence/p05/,INTERVIEW_NOTES.md}
```

## docs/BUILD_LOG.md template
```
## M<n> — <title>   (<date>, session <k>, mode OFFLINE/LIVE)
**Goal / requirement / control:** FR-x, NFR-y, ADR-z, PCI/SOX/NYDFS/DORA control
**What we built:** files/stacks + one line each
**How it works:** 5-10 plain-English bullets, incl. how AWS evaluates the policies involved
**Commands run, in order:** shell, command, read-only/mutating, AWS yes/no, key output
**Verification:** gate (offline/live), the exact command and the actual result (evidence path)
**Plan summary (LIVE only):** created / changed / destroyed, irreversible items, est. cost, my approval
**What broke and how we fixed it:** symptom -> hypothesis -> evidence -> root cause -> fix
**Lab vs Cobalt Bank:** what changes at the bank (Entra, TLS proxy, CAB window, quarter-end freeze, COMPLIANCE-mode retention)
**Check yourself:** 3 questions <details><summary>answers</summary>...</details>
```
Also maintain docs/ARCHITECTURE.md (the spec's ASCII org diagram updated to what we built), docs/adr/ in MADR format, and README.md (a from-zero quick start for OFFLINE mode, then LIVE prerequisites, one command per code block).

## Start now
1. Read CLAUDE.md and the spec files.
2. Restate the OFFLINE/LIVE rules and the irreversible operations in this project, in your own words, so I know you've got them.
3. Run `pwsh -File scripts/check-prereqs.ps1` and list the gaps with the exact fix commands, one per code block.
4. Give me a one-screen overview: the landing zone in your own words (org → OUs → accounts → guardrails → identity → logging → security → network → gates), the milestone plan with estimated hours and sessions, what OFFLINE alone will prove vs what needs LIVE, and the 5 riskiest parts.
Then STOP and wait for my "next".
````

---

## Resume prompt (new Claude Code session)

````text
We are continuing the P05 build. Read CLAUDE.md, docs/CLAUDE_CODE_BUILD_PROMPT.md (the full task and teaching protocol), docs/BUILD_LOG.md, docs/DEVIATIONS.md and docs/CONTROL_MAPPING.md. Run `pwsh -File scripts/check-prereqs.ps1`. Tell me which milestone we're on, its mode (OFFLINE unless I said "go live for M<n>"), its gate, any LIVE resources that are currently running and costing money, and anything inconsistent. STOP and wait for "next".
````

## Useful follow-ups

| Situation | Say |
|---|---|
| Go live for one milestone | `go live for M3` (only that milestone; every apply still needs your "apply") |
| Explain a denial | `walk me through exactly which policy layer denied this and how you proved it` |
| CISO / CAB practice | `play Cobalt Bank's CISO reviewing this SCP set and question me` |
| More depth | `go deeper on <thing>: show me what breaks if we remove it` |
| Interview practice | `ask me the spec section 11 questions one at a time and grade me` |
| Break it on purpose | `inject the section 12 failure "<row>" and let me diagnose it` |
