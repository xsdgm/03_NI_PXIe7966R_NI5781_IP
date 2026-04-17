$ErrorActionPreference = "Stop"

$TopModule = "fog_core_ni7966r_ni5781_lv_adapter"
$Part = "xc5vsx95tff1136-1"
$KeepHierarchy = $false

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$buildRoot = Join-Path $projectRoot "build\ise14_7"
$buildDir = Join-Path $buildRoot $TopModule

$xstCandidates = @(
    "C:\NIFPGA\programs\Xilinx14_7\ISE\bin\nt64\xst.exe",
    "C:\NIFPGA\programs\Xilinx14_7\ISE\bin\nt\xst.exe",
    "C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\xst.exe",
    "C:\Xilinx\14.7\ISE_DS\ISE\bin\nt\xst.exe"
)

$xstExe = $xstCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $xstExe) {
    throw "Cannot find xst.exe for Xilinx ISE 14.7."
}

$settingsCandidates = @(
    "C:\NIFPGA\programs\Xilinx14_7\settings64.bat",
    "C:\Xilinx\14.7\ISE_DS\settings64.bat"
)

$settingsBat = $settingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsBat) {
    throw "Cannot find settings64.bat for Xilinx ISE 14.7."
}

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

$sourceFiles = @(
    "src\adapters\fog_core_ni7966r_ni5781_lv_adapter.v",
    "src\adapters\ni5781_ai_to_adin12.v",
    "src\core\fog_core_ni7966r.v",
    "src\core\asReset.v",
    "src\core\genclk.v",
    "src\core\demodulate.v",
    "src\core\dRtMultFBK.v",
    "src\core\integrator.v",
    "src\core\ladhpi.v",
    "src\core\pidemint.v",
    "src\core\sdaout.v",
    "src\core\angleoutputWithComp.v"
)

$projectFile = Join-Path $buildDir "$TopModule.prj"
$xstFile = Join-Path $buildDir "$TopModule.xst"
$syrFile = Join-Path $buildDir "$TopModule.syr"
$ngcFile = Join-Path $buildDir "$TopModule.ngc"
$xstTmpDir = Join-Path $buildDir "xst"
$runBat = Join-Path $buildDir "run_xst.bat"
$keepValue = if ($KeepHierarchy) { "Yes" } else { "No" }

$prjLines = foreach ($file in $sourceFiles) {
    "verilog work `"$((Join-Path $projectRoot $file))`""
}
Set-Content -LiteralPath $projectFile -Value $prjLines -Encoding ASCII

$xstLines = @(
    "set -tmpdir `"$xstTmpDir`"",
    "set -xsthdpdir `"$xstTmpDir`"",
    "run",
    "-ifn `"$projectFile`"",
    "-ifmt mixed",
    "-ofn `"$ngcFile`"",
    "-ofmt NGC",
    "-p $Part",
    "-top $TopModule",
    "-opt_mode Speed",
    "-opt_level 1",
    "-keep_hierarchy $keepValue",
    "-iuc NO",
    "-vlgincdir `"$((Join-Path $projectRoot 'src\include'))`""
)
Set-Content -LiteralPath $xstFile -Value $xstLines -Encoding ASCII

Write-Host "Using XST:" $xstExe
Write-Host "Using settings:" $settingsBat
Write-Host "Top module:" $TopModule
Write-Host "Target part:" $Part
Write-Host "Output dir:" $buildDir

$batLines = @(
    "@echo off",
    "call `"$settingsBat`"",
    "`"$xstExe`" -intstyle xflow -ifn `"$xstFile`" -ofn `"$syrFile`"",
    "exit /b %ERRORLEVEL%"
)
Set-Content -LiteralPath $runBat -Value $batLines -Encoding ASCII

Push-Location $projectRoot
try {
    cmd /c $runBat
}
finally {
    Pop-Location
}

if (-not (Test-Path $ngcFile)) {
    throw "XST finished, but no NGC file was generated. Check $syrFile."
}

Write-Host ""
Write-Host "NGC generated:" $ngcFile
Write-Host "Synthesis report:" $syrFile
