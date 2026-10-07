# Prerequisite check for the P05 (Secure Landing Zone as Code) build on Windows 11. Read-only: it installs nothing.
# Usage: pwsh -File scripts/check-prereqs.ps1
$ErrorActionPreference = 'Continue'
$toolsBin = Join-Path $PSScriptRoot '..\tools\bin'
if (Test-Path $toolsBin) { $env:PATH = (Resolve-Path $toolsBin).Path + [IO.Path]::PathSeparator + $env:PATH }

function Ver($name, [scriptblock]$probe) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { return 'NOT ON PATH' }
    $ErrorActionPreference = 'Stop'
    try {
        $out = @(& $probe)
        if ($LASTEXITCODE -ne 0) { return "ERROR (exit $LASTEXITCODE)" }
        if ($out.Count -eq 0) { return 'UNKNOWN (no version output)' }
        return $out[0].ToString().Trim()
    }
    catch { return "UNAVAILABLE ($($_.Exception.Message))" }
}

$rows = @(
    @{ Tool = 'claude';    Want = 'Claude Code';     Have = Ver 'claude'    { claude --version } ;     Fix = 'npm i -g @anthropic-ai/claude-code (or the desktop app)' }
    @{ Tool = 'aws';       Want = 'AWS CLI v2';      Have = Ver 'aws'       { aws --version } ;        Fix = 'winget install Amazon.AWSCLI' }
    @{ Tool = 'tofu';      Want = 'OpenTofu 1.12.x'; Have = Ver 'tofu'      { tofu version } ;         Fix = 'GitHub release opentofu/opentofu v1.12.x -> ~/.local/bin (verify SHA256SUMS)' }
    @{ Tool = 'terraform'; Want = 'optional';        Have = Ver 'terraform' { terraform version } ;    Fix = '(optional) winget install Hashicorp.Terraform' }
    @{ Tool = 'tflint';    Want = '0.64.x';          Have = Ver 'tflint'    { tflint --version } ;     Fix = 'GitHub release terraform-linters/tflint -> ~/.local/bin' }
    @{ Tool = 'checkov';   Want = '3.3.x';           Have = Ver 'checkov'   { checkov --version } ;    Fix = 'uv tool install "checkov==3.3.*" (then fix checkov.cmd, see CLAUDE.md)' }
    @{ Tool = 'opa';       Want = '1.21.x';          Have = Ver 'opa'       { opa version } ;          Fix = 'GitHub release open-policy-agent/opa -> ~/.local/bin' }
    @{ Tool = 'conftest';  Want = '0.70.x';          Have = Ver 'conftest'  { conftest --version } ;   Fix = 'GitHub release open-policy-agent/conftest v0.70.x -> ~/.local/bin' }
    @{ Tool = 'uv';        Want = '0.12.x';          Have = Ver 'uv'        { uv --version } ;         Fix = 'uv self update' }
    @{ Tool = 'gh';        Want = 'logged in (M8)';  Have = Ver 'gh'        { gh --version } ;         Fix = 'winget install GitHub.cli; gh auth login' }
    @{ Tool = 'git';       Want = '2.4x+';           Have = Ver 'git'       { git --version } ;        Fix = 'winget install Git.Git' }
)
$rows | ForEach-Object { [pscustomobject]$_ } | Format-Table Tool, Want, Have, Fix -AutoSize -Wrap

# AWS identity: read-only, prints account and ARN only (never credentials)
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $profileName = if ($env:AWS_PROFILE) { $env:AWS_PROFILE } else { '(default)' }
    "AWS_PROFILE        : $profileName   AWS_REGION: $($env:AWS_REGION)"
    $id = aws sts get-caller-identity --query '[Account,Arn]' --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $id) { "Caller identity    : $id" } else { 'Caller identity    : not signed in (run: aws sso login --profile <profile>)  [fine for OFFLINE mode]' }
    $org = aws organizations describe-organization --query 'Organization.[Id,MasterAccountId]' --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $org) { "Organization       : $org  (an org already exists in this account!)" } else { 'Organization       : none visible (expected before M2 LIVE)' }
}
$py = if (Get-Command uv -ErrorAction SilentlyContinue) { uv python find 3.14 2>$null } else { $null }
'Python 3.14 via uv : ' + $(if ($py) { $py } else { 'not installed -> uv python install 3.14' })
'Mode reminder      : OFFLINE by default; LIVE only after you type "go live for M<n>".'
