$ErrorActionPreference = "Stop"

$TopModule = "fog_core_ni7966r_ni5781_lv_adapter"
$Part = "xc5vsx95tff1136-1"
$KeepHierarchy = $false

$scriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$projectRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent
$buildRoot = Join-Path $projectRoot "build\ise14_7"
$buildDir = Join-Path $buildRoot $TopModule

$toolCandidates = @(
    @{
        Xst = "C:\NIFPGA\programs\Xilinx14_7\ISE\bin\nt\xst.exe"
        Settings = "C:\NIFPGA\programs\Xilinx14_7\settings32.bat"
        Label = "NI FPGA ISE 14.7 32-bit"
    },
    @{
        Xst = "C:\NIFPGA\programs\Xilinx14_7\ISE\bin\nt64\xst.exe"
        Settings = "C:\NIFPGA\programs\Xilinx14_7\settings64.bat"
        Label = "NI FPGA ISE 14.7 64-bit"
    },
    @{
        Xst = "C:\Xilinx\14.7\ISE_DS\ISE\bin\nt\xst.exe"
        Settings = "C:\Xilinx\14.7\ISE_DS\settings32.bat"
        Label = "Standalone ISE 14.7 32-bit"
    },
    @{
        Xst = "C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\xst.exe"
        Settings = "C:\Xilinx\14.7\ISE_DS\settings64.bat"
        Label = "Standalone ISE 14.7 64-bit"
    }
)

$tool = $toolCandidates | Where-Object { (Test-Path $_.Xst) -and (Test-Path $_.Settings) } | Select-Object -First 1
if (-not $tool) {
    throw "Cannot find a matching xst.exe/settings*.bat pair for Xilinx ISE 14.7."
}

$xstExe = $tool.Xst
$settingsBat = $tool.Settings
$toolLabel = $tool.Label

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

$resolvedSourceFiles = foreach ($file in $sourceFiles) {
    Join-Path $projectRoot $file
}

$missingSourceFiles = @($resolvedSourceFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missingSourceFiles.Count -ne 0) {
    $message = "Missing source file(s) for XST project:`n" + ($missingSourceFiles -join "`n")
    throw $message
}

$projectFile = Join-Path $buildDir "$TopModule.prj"
$xstFile = Join-Path $buildDir "$TopModule.xst"
$syrFile = Join-Path $buildDir "$TopModule.syr"
$ngcFile = Join-Path $buildDir "$TopModule.ngc"
$xstTmpDir = Join-Path $buildDir "xst"
$runBat = Join-Path $buildDir "run_xst.bat"
$keepValue = if ($KeepHierarchy) { "Yes" } else { "No" }

if (-not (Test-Path $xstTmpDir)) {
    New-Item -ItemType Directory -Path $xstTmpDir -Force | Out-Null
}
attrib -R "$xstTmpDir" /S /D 2>$null

$prjLines = foreach ($file in $resolvedSourceFiles) {
    "verilog work `"$file`""
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
Write-Host "Toolchain:" $toolLabel
Write-Host "Project root:" $projectRoot
Write-Host "Top module:" $TopModule
Write-Host "Target part:" $Part
Write-Host "Output dir:" $buildDir
Write-Host "Source files:"
$resolvedSourceFiles | ForEach-Object { Write-Host "  " $_ }

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
