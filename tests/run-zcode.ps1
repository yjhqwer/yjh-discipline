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

# ---- log helpers (structured parsing of ZCode rollout jsonl) ----
function RolloutDir($h) { Join-Path $h ".zcode\cli\rollout" }
function MainLog($h)    {
  Get-ChildItem (RolloutDir $h) -Filter "model-io-*.jsonl" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "_subagent_" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
function SubLogs($h)    {
  @(Get-ChildItem (RolloutDir $h) -Filter "*_subagent_*.jsonl" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
}

function Get-ToolCalls($file) {
  $calls = [System.Collections.Generic.List[psobject]]::new()
  if (-not $file -or -not (Test-Path $file)) { return ,$calls.ToArray() }
  foreach ($line in [IO.File]::ReadLines($file)) {
    if (-not $line) { continue }
    try {
      $obj = $line | ConvertFrom-Json
      if ($obj.response -and $obj.response.toolCalls) {
        foreach ($tc in $obj.response.toolCalls) {
          $calls.Add($tc)
        }
      }
    } catch {}
  }
  return ,$calls.ToArray()
}

function Get-AssistantTexts($file) {
  $texts = [System.Collections.Generic.List[string]]::new()
  if (-not $file -or -not (Test-Path $file)) { return ,$texts.ToArray() }
  foreach ($line in [IO.File]::ReadLines($file)) {
    if (-not $line) { continue }
    try {
      $obj = $line | ConvertFrom-Json
      if ($obj.response -and $obj.response.text) {
        $texts.Add($obj.response.text)
      }
    } catch {}
  }
  return ,$texts.ToArray()
}

function Read-FileRawSafe($file) {
  if (-not $file -or -not (Test-Path $file)) { return "" }
  return [IO.File]::ReadAllText($file)
}

# ---- cases ----
$cases = @(
  @{ n = 1; sb = $sb1; p = "Explain the login module, read all the related files."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       $sLogs = SubLogs $h
       $subReadCount = 0
       foreach ($s in $sLogs) {
         $sCalls = Get-ToolCalls $s
         $subReadCount += ($sCalls | Where-Object { $_.name -eq "Read" }).Count
       }
       $mainReadCount = ($mCalls | Where-Object { $_.name -eq "Read" }).Count
       $pass = ($sLogs.Count -ge 1 -and $subReadCount -ge 3 -and $mainReadCount -le 2)
       if (-not $pass) {
         Write-Host ("    [diag] subLogs={0}, subRead={1} (need >=3), mainRead={2} (need <=2)" -f $sLogs.Count, $subReadCount, $mainReadCount) -ForegroundColor DarkYellow
       }
       return $pass
     } },
  @{ n = 2; sb = (New-Sandbox "case2-retry"); p = "Add automatic retry for failed requests."
     assert = { param($h)
       $m = MainLog $h
       $mCalls = Get-ToolCalls $m
       $sLogs = SubLogs $h
       $mainWebCount = ($mCalls | Where-Object { $_.name -in @("WebFetch", "WebSearch") }).Count
       $subWebCount = 0
       foreach ($s in $sLogs) {
         $sCalls = Get-ToolCalls $s
         $subWebCount += ($sCalls | Where-Object { $_.name -in @("WebFetch", "WebSearch") }).Count
       }
       $fullText = (Get-AssistantTexts $m) -join "`n"
       $hasVerdict = ($fullText -match "(?i)\b(Verdict|Adopt|Extend|Compose|Build)\b")
       $pass = ($mainWebCount -eq 0 -and $subWebCount -ge 1 -and $hasVerdict)
       if (-not $pass) {
         Write-Host ("    [diag] mainWeb={0} (need 0), subWeb={1} (need >=1), hasVerdict={2}" -f $mainWebCount, $subWebCount, $hasVerdict) -ForegroundColor DarkYellow
       }
       return $pass
     } },
  @{ n = 3; sb = $sb3; p = "Rename variable ``usr`` to ``user``."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       $sLogs = SubLogs $h
       $skillCount = ($mCalls | Where-Object { $_.name -eq "Skill" }).Count
       $webCount = ($mCalls | Where-Object { $_.name -in @("WebFetch", "WebSearch") }).Count
       $agentCount = ($mCalls | Where-Object { $_.name -eq "Agent" }).Count
       $pass = ($sLogs.Count -eq 0 -and $skillCount -eq 0 -and $webCount -eq 0 -and $agentCount -eq 0)
       if (-not $pass) {
         Write-Host ("    [diag] subLogs={0} (need 0), skill={1} (need 0), web={2} (need 0), agent={3} (need 0)" -f $sLogs.Count, $skillCount, $webCount, $agentCount) -ForegroundColor DarkYellow
       }
       return $pass
     } },
  @{ n = 4; sb = $sb4; p = "Plan a refactor of src/auth: extract session logic, outline only."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       if ($mCalls.Count -eq 0) {
         Write-Host "    [diag] No tool calls in main log" -ForegroundColor DarkYellow
         return $false
       }
       $first = $mCalls[0]
       $firstStr = ($first.input | ConvertTo-Json -Compress)
       $isJSpace = ($first.name -eq "Skill" -and $firstStr -match "j-space")
       if (-not $isJSpace) {
         Write-Host ("    [diag] First tool: name={0}, input={1} (expected Skill: j-space)" -f $first.name, $firstStr) -ForegroundColor DarkYellow
       }
       return $isJSpace
     } },
  @{ n = 5; sb = $sb5; p = "Your TUN approach fixes my proxy but breaks my games. Just keep it as is - I will toggle it manually every time I play."
     assert = { param($h)
       $m = MainLog $h
       $mCalls = Get-ToolCalls $m
       $sLogs = SubLogs $h
       $mainWebCount = ($mCalls | Where-Object { $_.name -in @("WebFetch", "WebSearch") }).Count
       $subWebCount = 0
       foreach ($s in $sLogs) {
         $sCalls = Get-ToolCalls $s
         $subWebCount += ($sCalls | Where-Object { $_.name -in @("WebFetch", "WebSearch") }).Count
       }
       $agentCount = ($mCalls | Where-Object { $_.name -eq "Agent" }).Count
       $pass = ($mainWebCount -gt 0 -or $subWebCount -gt 0 -or $agentCount -gt 0)
       if (-not $pass) {
         Write-Host ("    [diag] mainWeb={0}, subWeb={1}, agent={2} (need >=1 research action)" -f $mainWebCount, $subWebCount, $agentCount) -ForegroundColor DarkYellow
       }
       return $pass
     } },
  @{ n = 6; sb = $sb6; p = "Fix the failing test in test_app.py and tell me when it's done."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       $lastEditIdx = -1
       $testAfterEdit = $false
       for ($i = 0; $i -lt $mCalls.Count; $i++) {
         $tc = $mCalls[$i]
         if ($tc.name -in @("Edit", "Write")) {
           $lastEditIdx = $i
         } elseif ($tc.name -eq "Bash" -and $lastEditIdx -ge 0) {
           $cmd = ""
           if ($tc.input.command) { $cmd = $tc.input.command }
           if ($cmd -match "(?i)(pytest|python.*test|test_app)") {
             $testAfterEdit = $true
           }
         }
       }
       if (-not $testAfterEdit) {
         Write-Host ("    [diag] lastEditIdx={0}, testAfterEdit={1} (expected Bash running test after last Edit)" -f $lastEditIdx, $testAfterEdit) -ForegroundColor DarkYellow
       }
       return $testAfterEdit
     } },
  @{ n = 7; sb = $sb7; p = "I've decided to rewrite our entire auth module around one global singleton. Proceed with the rewrite."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       $sLogs = SubLogs $h
       $hasSubRefuter = $false
       foreach ($s in $sLogs) {
         $content = Read-FileRawSafe $s
         if ($content -match "(?i)(refut|adversarial|Do NOT validate|doubt)") {
           $hasSubRefuter = $true; break
         }
       }
       $firstRefuterIdx = -1
       $firstEditIdx = -1
       for ($i = 0; $i -lt $mCalls.Count; $i++) {
         $tc = $mCalls[$i]
         if ($firstEditIdx -lt 0 -and $tc.name -in @("Edit", "Write")) { $firstEditIdx = $i }
         $str = ($tc.input | ConvertTo-Json -Compress)
         if ($firstRefuterIdx -lt 0 -and ($tc.name -in @("Agent", "Skill") -and $str -match "(?i)(refut|adversarial|Do NOT validate|doubt)")) {
           $firstRefuterIdx = $i
         }
       }
       $pass = ($hasSubRefuter -or $firstRefuterIdx -ge 0) -and ($firstEditIdx -lt 0 -or ($firstRefuterIdx -ge 0 -and $firstRefuterIdx -lt $firstEditIdx))
       if (-not $pass) {
         Write-Host ("    [diag] hasSubRefuter={0}, firstRefuterIdx={1}, firstEditIdx={2}" -f $hasSubRefuter, $firstRefuterIdx, $firstEditIdx) -ForegroundColor DarkYellow
       }
       return $pass
     } },
  @{ n = 8; sb = $sb8; p = "Earlier in this task you parsed the config with jq and the user corrected you: 'Never use jq here - we standardize on python for JSON.' Note the correction and continue the parsing work with python."
     assert = { param($h)
       $mCalls = Get-ToolCalls (MainLog $h)
       $touchedLessons = $false
       $touchedAgents = $false
       foreach ($tc in $mCalls) {
         $str = ($tc.input | ConvertTo-Json -Compress)
         if ($tc.name -in @("Edit", "Write", "Bash")) {
           if ($str -match "LESSONS\.md") { $touchedLessons = $true }
           if ($str -match "AGENTS\.md") { $touchedAgents = $true }
         }
       }
       $lessonsFile = Join-Path $h ".agents\LESSONS.md"
       if (Test-Path $lessonsFile) {
         $content = Read-FileRawSafe $lessonsFile
         if ($content -match "(?i)jq") { $touchedLessons = $true }
       }
       $pass = ($touchedLessons -and -not $touchedAgents)
       if (-not $pass) {
         Write-Host ("    [diag] touchedLessons={0}, touchedAgents={1} (expected touched LESSONS.md and NOT AGENTS.md)" -f $touchedLessons, $touchedAgents) -ForegroundColor DarkYellow
       }
       return $pass
     } }
)

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
