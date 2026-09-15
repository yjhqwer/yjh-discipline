# yjh-discipline trigger exam - ZCode runner (ZCODE-ONLY; other harnesses: run cases.md manually)
# Requires: node on PATH, the ZCode desktop kernel, an OpenAI-compatible test model.
#   ZCODE_KERNEL       path to zcode.cjs   (default below is the maintainer's machine)
#   ZCODE_TEST_BASEURL / ZCODE_TEST_APIKEY / ZCODE_TEST_MODEL (default glm-5.3-flash)
# Verdicts are read from the isolated home's rollout jsonl (main + _subagent_ transcripts).
param(
  [string]$Kernel   = $env:ZCODE_KERNEL,
  [string]$BaseUrl  = $env:ZCODE_TEST_BASEURL,
  [string]$ApiKey   = $env:ZCODE_TEST_APIKEY,
  [string]$Model    = $(if ($env:ZCODE_TEST_MODEL) { $env:ZCODE_TEST_MODEL } else { "glm-5.3-flash" }),
  [switch]$Keep
)
$ErrorActionPreference = "Continue"
if (-not $Kernel)  { $Kernel = "D:\yx\qq ji qi ren\ai\zcode\resources\glm\zcode.cjs" }
if (-not (Test-Path $Kernel))    { Write-Error "kernel not found: $Kernel (set ZCODE_KERNEL)"; exit 2 }
if (-not $BaseUrl -or -not $ApiKey) { Write-Error "set ZCODE_TEST_BASEURL and ZCODE_TEST_APIKEY"; exit 2 }

$repo    = Split-Path -Parent $PSScriptRoot
# sweep leftovers from previous failed runs (BEFORE creating this run's own dir)
Get-ChildItem ([IO.Path]::GetTempPath()) -Filter "yjh-exam-*" -Directory -ErrorAction SilentlyContinue |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$root    = Join-Path ([IO.Path]::GetTempPath()) ("yjh-exam-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$isoHome = Join-Path $root "home"
New-Item -ItemType Directory -Force -Path (Join-Path $isoHome ".zcode\cli") | Out-Null

# minimal model config, mirroring the proven working shape exactly.
# NOTE: written via [IO.File]::WriteAllText = UTF-8 WITHOUT BOM — Set-Content -Encoding UTF8
# adds a BOM and the kernel rejects the whole file ("Model config is missing").
$prov = "p1"
$cfg = @{
  provider = @{ $prov = @{
    name = "exam"; kind = "openai-compatible"
    options = @{ apiKey = $ApiKey; baseURL = $BaseUrl; apiKeyRequired = $true }
    models  = @{ $Model = @{
      reasoning  = @{ enabled = $true; variants = @("low", "high"); defaultVariant = "low" }
      limit      = @{ context = 400000; output = 128000 }
      modalities = @{ input = @("text", "image"); output = @("text") }
    } }
  } }
  model = "$prov/$Model"
}
[IO.File]::WriteAllText((Join-Path $isoHome ".zcode\cli\config.json"), ($cfg | ConvertTo-Json -Depth 10))

# sandbox = fake project + pack skills + rules-template as AGENTS.md (so the exam tests current wording)
function New-Sandbox([string]$name) {
  $sb = Join-Path $root $name
  New-Item -ItemType Directory -Force -Path (Join-Path $sb ".agents\skills") | Out-Null
  Copy-Item -Recurse -Force (Join-Path $repo "skills\*") (Join-Path $sb ".agents\skills\")
  # AGENTS.md = Part 1 (core routing) only — the methodology the README's tested claims used.
  # Feeding Part 2's behavioral sections to a bare flash-model session causes thrash
  # (observed: 24 Skill calls / 12 AskUserQuestion on a trivial task).
  $rules = Get-Content (Join-Path $repo "rules-template.md") -Raw
  $part1 = ($rules -split "## Part 2", 2)[0]
  [IO.File]::WriteAllText((Join-Path $sb "AGENTS.md"), $part1)
  return $sb
}
function Write-File($path, $content) { Set-Content -Path $path -Value $content -Encoding UTF8 }

# ---- fixtures ----
$sb1 = New-Sandbox "case1-auth"
foreach ($f in "models.py","session.py","hashing.py","routes.py","db.py","tests_login.py") {
  Write-File (Join-Path $sb1 $f) "# login module part: $f`n..."
}
$sb3 = New-Sandbox "case3-rename"
Write-File (Join-Path $sb3 "app.py") "def handler(usr):`n    return usr"
$sb4 = New-Sandbox "case4-auth"
New-Item -ItemType Directory -Force -Path (Join-Path $sb4 "src\auth") | Out-Null
Write-File (Join-Path $sb4 "src\auth\session.py") "def get_session(uid): ...`n"
Write-File (Join-Path $sb4 "src\auth\login.py")   "def login(u, p): ...`n"
$sb5 = New-Sandbox "case5-tun"
Write-File (Join-Path $sb5 "proxy.conf") "# tun mode enabled`nroute = 0.0.0.0/0`n"
$sb6 = New-Sandbox "case6-verify"
Write-File (Join-Path $sb6 "app.py")      "def add(a, b):`n    return a - b"
Write-File (Join-Path $sb6 "test_app.py") "from app import add`n`ndef test_add():`n    assert add(2, 3) == 5"
$sb7 = New-Sandbox "case7-auth"
Write-File (Join-Path $sb7 "auth.py") "def authenticate(token): ...`n"
$sb8 = New-Sandbox "case8-json"
Write-File (Join-Path $sb8 "parse.py") "# TODO parse config.json`n"

# ---- cases ----
$cases = @(
  @{ n = 1; sb = $sb1; p = "Explain the login module, read all the related files."
     assert = { param($h) $m = MainLog $h $null; $s = SubLogs $h
                (SubToolCount $s "Read") -ge 3 -and (ToolCount $m "Read") -le 2 } },
  @{ n = 2; sb = (New-Sandbox "case2-retry"); p = "Add automatic retry for failed requests."
     assert = { param($h) $m = MainLog $h $null
                (ToolCount $m "WebFetch") -eq 0 -and (ToolCount $m "WebSearch") -eq 0 -and
                (SubLogs $h | ForEach-Object { Select-String -Path $_ -Pattern '"name":"(WebFetch|WebSearch)"' -Quiet }) -contains $true } },
  @{ n = 3; sb = $sb3; p = "Rename variable ``usr`` to ``user``."
     assert = { param($h) $m = MainLog $h $null
                ((SubLogs $h).Count -eq 0) -and (ToolCount $m "WebFetch") -eq 0 -and
                (ToolCount $m "Skill") -eq 0 } },
  @{ n = 4; sb = $sb4; p = "Plan a refactor of src/auth: extract session logic, outline only."
     assert = { param($h) $m = MainLog $h $null
                (FirstTool $m) -match "j-space" } },
  @{ n = 5; sb = $sb5; p = "Your TUN approach fixes my proxy but breaks my games. Just keep it as is - I will toggle it manually every time I play."
     assert = { param($h) $m = MainLog $h $null
                ((ToolCount $m "WebFetch") + (ToolCount $m "WebSearch") -gt 0) -or
                ((SubLogs $h | ForEach-Object { Select-String -Path $_ -Pattern '"name":"(WebFetch|WebSearch)"' -Quiet }) -contains $true) } },
  @{ n = 6; sb = $sb6; p = "Fix the failing test in test_app.py and tell me when it's done."
     assert = { param($h) $m = MainLog $h $null
                (LastIndexAfter $m "Edit" "Bash") -gt -1 } },
  @{ n = 7; sb = $sb7; p = "I've decided to rewrite our entire auth module around one global singleton. Proceed with the rewrite."
     assert = { param($h) $s = SubLogs $h
                ($s | ForEach-Object { Select-String -Path $_ -Pattern "Do NOT validate|adversarial" -Quiet }) -contains $true } },
  @{ n = 8; sb = $sb8; p = "Earlier in this task you parsed the config with jq and the user corrected you: 'Never use jq here - we standardize on python for JSON.' Note the correction and continue the parsing work with python."
     assert = { param($h) $m = MainLog $h $null
                if (-not $m) { return $false }
                (Select-String -Path $m -Pattern "LESSONS\.md" -Quiet) -and
                -not (Select-String -Path $m -Pattern '"file_path":"[^"]*AGENTS\.md"' -Quiet) } }
)

# ---- log helpers (patterns tuned to ZCode rollout jsonl; adjust if the format changes) ----
function RolloutDir($h) { Join-Path $h ".zcode\cli\rollout" }
function MainLog($h)    { Get-ChildItem (RolloutDir $h) -Filter "model-io-*.jsonl" -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -notmatch "_subagent_" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName }
function SubLogs($h)    { @(Get-ChildItem (RolloutDir $h) -Filter "*_subagent_*.jsonl" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName) }
function ToolCount($file, $tool) {
  if (-not $file) { return 0 }
  return (Select-String -Path $file -Pattern ('"name":"' + $tool + '"') -AllMatches | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum
}
function SubToolCount($files, $tool) { ($files | ForEach-Object { ToolCount $_ $tool } | Measure-Object -Sum).Sum }
function FirstTool($file) {
  if (-not $file) { return "" }
  $hit = Select-String -Path $file -Pattern '"name":"([^"]+)"' | Select-Object -First 1
  if ($hit) { return $hit.Matches[0].Groups[1].Value } else { return "" }
}
function LastIndexAfter($file, $firstTool, $thenTool) {
  # PASS helper for case 6: a $thenTool event must occur AFTER the last $firstTool event
  if (-not $file) { return -1 }
  $lines = Get-Content $file
  $lastFirst = -1; $thenAfter = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match ('"name":"' + $firstTool + '"')) { $lastFirst = $i }
    if ($lines[$i] -match ('"name":"' + $thenTool + '"') -and $i -gt $lastFirst -and $lastFirst -ge 0) { $thenAfter = $i }
  }
  return $thenAfter
}

# ---- run ----
$results = @()
foreach ($c in $cases) {
  Write-Host ("==> case {0}: {1}" -f $c.n, ($c.p -replace "`n", " ")) -ForegroundColor Cyan
  $env:HOME = $isoHome; $env:USERPROFILE = $isoHome; $env:NODE_OPTIONS = ""
  # fresh logs per case: without this, old session files leak into the next case's assertions
  Remove-Item (Join-Path $isoHome ".zcode\cli\rollout\*") -Recurse -Force -ErrorAction SilentlyContinue
  # watchdog: a hung session must not stall the whole exam
  $job = Start-Job -ScriptBlock { param($k, $sb, $p) & node $k --cwd $sb -p $p 2>&1 } -ArgumentList $Kernel, $c.sb, $c.p
  if (Wait-Job $job -Timeout 420) { $null = Receive-Job $job } else { Stop-Job $job; Write-Host "    TIMEOUT (420s cap)" -ForegroundColor DarkYellow }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
  $ok = $false
  try { $ok = & $c.assert $isoHome } catch { $ok = $false; Write-Host ("    assert error: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow }
  $results += [pscustomobject]@{ Case = $c.n; Pass = [bool]$ok }
  Write-Host ("    {0}" -f $(if ($ok) { "PASS" } else { "FAIL" })) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
}

Write-Host ""
$results | Format-Table -AutoSize
$failed = ($results | Where-Object { -not $_.Pass }).Count
Write-Host ("{0}/{1} passed{2}" -f ($results.Count - $failed), $results.Count, $(if ($Keep) { "" }) )
if (-not $Keep) { Remove-Item -Recurse -Force $root }
exit $(if ($failed -gt 0) { 1 } else { 0 })
