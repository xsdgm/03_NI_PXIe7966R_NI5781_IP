$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$buildDir = Join-Path $projectRoot "build\icarus"

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Push-Location $projectRoot

iverilog -g2001 -I "src\include" -o "$buildDir\smoke_ni5781.vvp" `
  "src\adapters\fog_core_ni7966r_ni5781_lv_adapter.v" `
  "src\adapters\ni5781_ai_to_adin12.v" `
  "src\core\fog_core_ni7966r.v" `
  "src\core\asReset.v" `
  "src\core\genclk.v" `
  "src\core\demodulate.v" `
  "src\core\dRtMultFBK.v" `
  "src\core\integrator.v" `
  "src\core\ladhpi.v" `
  "src\core\pidemint.v" `
  "src\core\sdaout.v" `
  "src\core\angleoutputWithComp.v"

Pop-Location
