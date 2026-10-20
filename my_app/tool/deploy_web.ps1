$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$deployDir  = "build/web_deploy"
$mainOutDir = "build/web_main"
$adminOutDir= "build/web_admin"

function Reset-Dir([string]$path) {
  if (Test-Path $path) { Remove-Item $path -Recurse -Force }
  New-Item -ItemType Directory -Path $path | Out-Null
}

function Force-HtmlRenderer([string]$indexPath) {
  if (!(Test-Path $indexPath)) { return }

  $content = Get-Content $indexPath -Raw

  # Case 1: index.html already contains window.flutterWebRenderer
  if ($content -match "window\.flutterWebRenderer") {
    $content = $content -replace 'window\.flutterWebRenderer\s*=\s*"(auto|html|canvaskit)"\s*;', 'window.flutterWebRenderer = "html";'
  }
  # Case 2: newer template calls initializeEngine() with no args
  elseif ($content -match 'initializeEngine\(\)') {
    $content = $content -replace 'initializeEngine\(\)', 'initializeEngine({ renderer: "html" })'
  }
  # Case 3: fallback: inject window.flutterWebRenderer before flutter.js include (if found)
  elseif ($content -match '<script[^>]+src="flutter\.js"') {
    $inject = "  <script>window.flutterWebRenderer = `"html`";</script>`r`n"
    $content = $content -replace '(\s*<script[^>]+src="flutter\.js"[^>]*></script>)', ($inject + '$1')
  }

  Set-Content -Path $indexPath -Value $content -Encoding UTF8
}

Write-Host "Detecting supported flutter build flags..."
$helpText = (& flutter build web -h 2>&1 | Out-String)
$hasWebRendererFlag = $helpText -match "--web-renderer"
$hasPwaStrategyFlag = $helpText -match "--pwa-strategy"

Write-Host "Cleaning previous staged builds..."
if (Test-Path $mainOutDir)  { Remove-Item $mainOutDir  -Recurse -Force }
if (Test-Path $adminOutDir) { Remove-Item $adminOutDir -Recurse -Force }

# ---------- BUILD MAIN ----------
Write-Host "Building MAIN web..."
$mainArgs = @("build","web","--release","--no-source-maps","--base-href","/")

if ($hasPwaStrategyFlag) { $mainArgs += "--pwa-strategy=none" }
if ($hasWebRendererFlag) { $mainArgs += @("--web-renderer","html") }

& flutter @mainArgs
if ($LASTEXITCODE -ne 0) { throw "MAIN build failed." }
if (!(Test-Path "build/web")) { throw "MAIN build failed: build/web not found." }

Move-Item "build/web" $mainOutDir -Force
Force-HtmlRenderer "$mainOutDir/index.html"

# ---------- BUILD ADMIN ----------
Write-Host "Building ADMIN web..."
$adminArgs = @("build","web","--release","--no-source-maps","-t","lib/admin/main.dart","--base-href","/admin/")

if ($hasPwaStrategyFlag) { $adminArgs += "--pwa-strategy=none" }
if ($hasWebRendererFlag) { $adminArgs += @("--web-renderer","html") }

& flutter @adminArgs
if ($LASTEXITCODE -ne 0) { throw "ADMIN build failed." }
if (!(Test-Path "build/web")) { throw "ADMIN build failed: build/web not found." }

Move-Item "build/web" $adminOutDir -Force
Force-HtmlRenderer "$adminOutDir/index.html"

# ---------- STAGE DEPLOY FOLDER ----------
Write-Host "Refreshing $deployDir ..."
Reset-Dir $deployDir
New-Item -ItemType Directory -Path "$deployDir/admin" | Out-Null

Write-Host "Copying MAIN -> $deployDir ..."
Copy-Item "$mainOutDir\*" $deployDir -Recurse -Force

Write-Host "Copying ADMIN -> $deployDir/admin ..."
Copy-Item "$adminOutDir\*" "$deployDir/admin" -Recurse -Force

# ---------- SANITY CHECK ----------
Write-Host "Sanity-checking base href..."
$mainBase  = (Select-String -Path "$deployDir/index.html"        -Pattern "<base href=" -SimpleMatch | Select-Object -First 1).Line
$adminBase = (Select-String -Path "$deployDir/admin/index.html"  -Pattern "<base href=" -SimpleMatch | Select-Object -First 1).Line
Write-Host "MAIN  index.html: $mainBase"
Write-Host "ADMIN index.html: $adminBase"

Write-Host "Deploying Hosting..."
firebase deploy --only hosting

# deploy code for admin and main web app
# powershell -ExecutionPolicy Bypass -File tool/deploy_web.ps1