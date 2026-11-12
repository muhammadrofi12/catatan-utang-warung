# Invoke the pinned stable SDK without changing the global Flutter channel.
$flutterArguments = $args
$taskSdk = $env:CATATAN_FLUTTER_SDK
if (-not $taskSdk) { $taskSdk = 'C:/src/flutter-ocs-pos-stable' }
$taskFlutter = Join-Path $taskSdk 'bin/flutter.bat'
if (-not (Test-Path -LiteralPath $taskFlutter)) { $taskFlutter = (Get-Command flutter -ErrorAction Stop).Source }
& $taskFlutter --no-version-check @flutterArguments
exit $LASTEXITCODE
