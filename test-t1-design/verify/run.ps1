# verify runner (template). Reads env.local|env.example + cases.json → out.txt
# Only paths/fields present in cases (must match T1-04). No inventing endpoints.
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

function Load-Env($path) {
  Get-Content $path | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
    $k, $v = $_.Split('=', 2)
    Set-Item -Path "Env:$($k.Trim())" -Value $v.Trim()
  }
}

$envFile = if (Test-Path "env.local") { "env.local" } else { "env.example" }
Load-Env $envFile
$base = $env:BASE_URL.TrimEnd('/')
$svc = $env:SVC
$success = $env:SUCCESS_CODE
if (-not $base) { throw "BASE_URL empty — copy env.example to env.local" }

$cases = Get-Content "cases.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$lines = @("VERIFY $(Get-Date -Format o)", "ENV_FILE=$envFile", "BASE=$base")
$fail = 0

foreach ($c in $cases) {
  $path = $c.path -replace '\{svc\}', $svc
  $url = "$base$path"
  $headers = @{}
  foreach ($p in $c.headers.PSObject.Properties) {
    $val = [regex]::Replace([string]$p.Value, '\$\{([A-Z0-9_]+)\}', {
      param($m) $name = $m.Groups[1].Value; (Get-Item "Env:$name").Value
    })
    $headers[$p.Name] = $val
  }
  $body = if ($c.body) { $c.body | ConvertTo-Json -Compress -Depth 8 } else { $null }
  $status = 0; $text = ""
  try {
    $resp = Invoke-WebRequest -Uri $url -Method $c.method -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing
    $status = [int]$resp.StatusCode; $text = $resp.Content
  } catch {
    if ($_.Exception.Response) {
      $status = [int]$_.Exception.Response.StatusCode
      $reader = [IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
      $text = $reader.ReadToEnd(); $reader.Close()
    } else { $text = $_.Exception.Message }
  }
  $ok = $false
  $httpOk = -not $c.expect.http -or ($c.expect.http -contains $status)
  if ($c.expect.deny) {
    $ok = $httpOk -and ($status -in 401, 403 -or ($success -and $text -notlike "*$success*"))
  } elseif ($c.expect.successCodeFromHandbook -and $success) {
    $ok = $httpOk -and ($text -like "*`"code`":$success*" -or $text -like "*`"code`":`"$success`"*")
  } else { $ok = $httpOk }
  $tag = if ($ok) { "PASS" } else { "FAIL"; $fail++ }
  $lines += "$tag id=$($c.id) ac=$($c.ac) card=$($c.card) http=$status $url"
  if (-not $ok) { $lines += "BODY_SNIP $(($text -replace '\s+', ' ').Substring(0, [Math]::Min(400, $text.Length)))" }
}

$lines += "RESULT fail=$fail"
$lines | Set-Content "out.txt" -Encoding UTF8
Write-Output $lines[-1]
if ($fail -gt 0) { exit 1 }
