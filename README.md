# P05 — Secure Landing Zone as Code (Cobalt Bank, composite scenario)

A learning build from the FDE Onboarding Handbook: a multi-account AWS foundation for a regulated bank, built in OpenTofu. It covers:
- an AWS Organization with OUs and accounts as code;
- SCPs, an RCP identity perimeter and a tag policy;
- IAM Identity Center, an org CloudTrail into an Object Lock archive, and delegated security services;
- a private-only VPC module;
- CI policy gates on plan JSON and drift detection.

All of it is mapped to PCI DSS v4.0.1, SOX, NYDFS 500 and DORA.

**Status:** not built yet. The build is done with **Claude Code running locally on Windows**, following [`docs/CLAUDE_CODE_BUILD_PROMPT.md`](docs/CLAUDE_CODE_BUILD_PROMPT.md). **OFFLINE by default**: nothing touches AWS until you type `go live for M<n>`.

| Path | What it is |
|---|---|
| [`spec/P05-secure-landing-zone-as-code.md`](spec/P05-secure-landing-zone-as-code.md) | The P05 spec (incl. the Azure appendix): source of truth |
| [`spec/ground-truth-digest.md`](spec/ground-truth-digest.md) | Verified versions and dates (Sept 2026) |
| [`spec/reference-C11-infrastructure-as-code.md`](spec/reference-C11-infrastructure-as-code.md) | IaC curriculum background |
| [`CLAUDE.md`](CLAUDE.md) | Rules Claude Code loads automatically: modes, AWS safety, machine gaps |
| [`.claude/settings.json`](.claude/settings.json) | Permission gates: ask before every apply, destroy, org change, deletion or push |
| [`scripts/check-prereqs.ps1`](scripts/check-prereqs.ps1) | Read-only prerequisite and AWS-identity checker (never prints credentials) |
| [`docs/CLAUDE_CODE_BUILD_PROMPT.md`](docs/CLAUDE_CODE_BUILD_PROMPT.md) | Prerequisites, the kickoff prompt and the resume prompt |
