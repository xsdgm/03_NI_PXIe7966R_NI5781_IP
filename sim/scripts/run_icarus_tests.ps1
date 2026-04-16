$ErrorActionPreference = "Stop"

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$buildDir = Join-Path $projectRoot "build\icarus"
$waveDir = Join-Path $projectRoot "sim\icarus"

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

if (-not (Test-Path $waveDir)) {
    New-Item -ItemType Directory -Path $waveDir | Out-Null
}

Push-Location $projectRoot

Write-Host "[1/6] Compile mapper unit test"
iverilog -g2001 -I "src\include" -o "$buildDir\tb_mapper.vvp" `
  "sim\tb\tb_ni5781_ai_to_adin12.v" `
  "src\adapters\ni5781_ai_to_adin12.v"

Write-Host "[2/6] Run mapper unit test"
vvp "$buildDir\tb_mapper.vvp"

Write-Host "[3/6] Compile top smoke test"
iverilog -g2001 -I "src\include" -o "$buildDir\tb_top.vvp" `
  "sim\tb\tb_fog_core_ni7966r_ni5781_lv_adapter.v" `
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

Write-Host "[4/6] Run top smoke test"
vvp "$buildDir\tb_top.vvp"

Write-Host "[5/6] Compile gyro modulation functional test"
iverilog -g2001 -I "src\include" -o "$buildDir\tb_gyro_modulation.vvp" `
  "sim\tb\tb_fog_gyro_signal_modulation.v" `
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

Write-Host "[6/6] Run gyro modulation functional test"
vvp "$buildDir\tb_gyro_modulation.vvp"

Pop-Location
