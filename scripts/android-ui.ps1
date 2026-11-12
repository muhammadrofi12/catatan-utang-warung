param([string]$Tap, [switch]$Dump, [string]$Screenshot)
# Developer helper; use only the dedicated test emulator, never a real book.
$ErrorActionPreference = 'Stop'
$adbPath = 'C:/sdk-android/platform-tools/adb.exe'
$root = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Force $artifacts | Out-Null
& $adbPath -s emulator-5554 shell uiautomator dump /sdcard/warung-ui.xml | Out-Null
$ErrorActionPreference = 'Continue'
& $adbPath -s emulator-5554 pull /sdcard/warung-ui.xml (Join-Path $artifacts 'ui.xml') 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'Could not retrieve UI hierarchy.' }
[xml]$tree = Get-Content -Raw (Join-Path $artifacts 'ui.xml')
$nodes = $tree.SelectNodes('//node')
if ($Tap) {
    $node = $nodes | Where-Object { $_.'content-desc' -eq $Tap -or $_.text -eq $Tap } | Select-Object -First 1
    if (-not $node) { throw "Control not found: $Tap" }
    $numbers = [regex]::Matches($node.bounds, '\d+') | ForEach-Object { [int]$_.Value }
    $tapX = [int](($numbers[0] + $numbers[2]) / 2)
    $tapY = [int](($numbers[1] + $numbers[3]) / 2)
    & $adbPath -s emulator-5554 shell input tap $tapX $tapY
    Write-Output "Tapped: $Tap"
}
if ($Dump) {
    $nodes | Where-Object { $_.'content-desc' -or $_.text } | ForEach-Object {
        $label = if ($_.'content-desc') { $_.'content-desc' } else { $_.text }
        if ($label -notmatch '(?i)[0-9a-f]{4}(\s[0-9a-f]{4}){3}' -and $label -notmatch '^ID kunci:') {
            Write-Output "$label $($_.bounds)"
        }
    }
}
if ($Screenshot) {
    & $adbPath -s emulator-5554 shell screencap -p /sdcard/warung-screen.png
    & $adbPath -s emulator-5554 pull /sdcard/warung-screen.png (Join-Path $artifacts $Screenshot)
}
