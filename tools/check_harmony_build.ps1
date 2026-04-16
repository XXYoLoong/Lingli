# 邻里鸿蒙端编译检查
# 用法：
#   powershell -ExecutionPolicy Bypass -File .\tools\check_harmony_build.ps1

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LingliDir = Join-Path $ProjectRoot "Lingli"
$NodeExe = "F:\DevEco Studio 6.0.0\tools\node\node.exe"
$HvigorJs = "F:\DevEco Studio 6.0.0\tools\hvigor\bin\hvigorw.js"

if (-not (Test-Path $NodeExe)) {
  throw "未找到 DevEco Node: $NodeExe"
}
if (-not (Test-Path $HvigorJs)) {
  throw "未找到 hvigorw.js: $HvigorJs"
}
if (-not (Test-Path $LingliDir)) {
  throw "未找到 Lingli 工程目录: $LingliDir"
}

Write-Host "开始鸿蒙构建检查..." -ForegroundColor Cyan
Write-Host "工程目录: $LingliDir"

Push-Location $LingliDir
try {
  & $NodeExe $HvigorJs `
    --mode module `
    -p module=entry@default `
    -p product=default `
    -p requiredDeviceType=phone `
    assembleHap `
    --analyze=normal `
    --parallel `
    --incremental `
    --daemon

  if ($LASTEXITCODE -ne 0) {
    throw "鸿蒙构建失败，退出码: $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}

Write-Host "Harmony build check passed." -ForegroundColor Green
