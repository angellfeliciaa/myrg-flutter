# Builds the APK for testers: connected to a MyRG backend, release mode.
#
#   .\tool\build_tester_apk.ps1 -ApiUrl https://staging.example.com/api/v1
#
# -ApiUrl must be https (a release build refuses plain http) and end with /api/v1.
# The backend behind it should run with CORE_RG_MODE=fake while Raja Gadai's device-check SDK is
# not in the app: -SampleInspection (on by default) sends a made-up device check so the photo
# steps of Gadai Online can be tried. Use -SampleInspection:$false against the real Core RG.
param(
    [Parameter(Mandatory = $true)][string]$ApiUrl,
    [bool]$SampleInspection = $true
)

if ($ApiUrl -notmatch '^https://.+/api/v1$') {
    Write-Error "ApiUrl must look like https://host/api/v1 (got: $ApiUrl)"
    exit 1
}

$flutter = if (Get-Command flutter -ErrorAction SilentlyContinue) { 'flutter' } else { 'C:\flutter\bin\flutter.bat' }
$defines = @("--dart-define=RG_PREVIEW=false", "--dart-define=MYRG_API_URL=$ApiUrl")
if ($SampleInspection) { $defines += "--dart-define=MYRG_SAMPLE_INSPECTION=true" }

& $flutter build apk --release --split-per-abi --target-platform android-arm64 @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
Write-Host ""
Write-Host "APK for testers: $((Resolve-Path $apk).Path)"
Write-Host "Backend: $ApiUrl"
