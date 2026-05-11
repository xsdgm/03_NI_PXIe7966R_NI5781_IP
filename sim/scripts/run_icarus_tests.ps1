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

Write-Host "[1/8] Compile mapper unit test"
iverilog -g2001 -I "src\include" -o "$buildDir\tb_mapper.vvp" `
  "sim\tb\tb_ni5781_ai_to_adin12.v" `
  "src\adapters\ni5781_ai_to_adin12.v"

Write-Host "[2/8] Run mapper unit test"
vvp "$buildDir\tb_mapper.vvp"

Write-Host "[3/8] Compile top smoke test"
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

Write-Host "[4/8] Run top smoke test"
vvp "$buildDir\tb_top.vvp"

Write-Host "[5/8] Compile gyro modulation functional test"
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

Write-Host "[6/8] Run gyro modulation functional test"
vvp "$buildDir\tb_gyro_modulation.vvp"

Write-Host "[7/8] Compile LabVIEW adapter configuration sweep"
iverilog -g2001 -I "src\include" -o "$buildDir\tb_lv_adapter_config_sweep.vvp" `
  "sim\tb\tb_lv_adapter_config_sweep.v" `
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

Write-Host "[8/8] Run LabVIEW adapter configuration sweep"
vvp "$buildDir\tb_lv_adapter_config_sweep.vvp"

Pop-Location
