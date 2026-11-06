# ICA 13B setup for Windows (PowerShell). Run from the project root:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
# Prereqs: Flutter SDK, Node (for firebase-tools), a Firebase project with
# Email/Password sign-in enabled.

$ErrorActionPreference = "Stop"

Write-Host "1/6 Generating platform folders (keeps existing lib/ and test/)..."
flutter create --platforms=android --project-name ica13b_firebase_auth --org edu.gsu.csc4360 .

Write-Host "2/6 Adding INTERNET permission to the main AndroidManifest..."
$manifest = "android\app\src\main\AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "android.permission.INTERNET") {
  $xml = $xml -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  Set-Content $manifest $xml -NoNewline
}

Write-Host "3/6 Raising Android minSdk to 23 (required by firebase_auth)..."
$gradle = Get-ChildItem android\app -Filter "build.gradle*" | Select-Object -First 1
$g = Get-Content $gradle.FullName -Raw
$g = $g -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
$g = $g -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23'
Set-Content $gradle.FullName $g -NoNewline

Write-Host "4/6 Installing packages..."
flutter pub get

Write-Host "5/6 Connecting to Firebase (choose your project, select android)..."
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) { npm install -g firebase-tools }
firebase login
dart pub global activate flutterfire_cli
# Add Pub cache bin to PATH so flutterfire is found
$pubCache = "$env:LOCALAPPDATA\Pub\Cache\bin"
if ($env:Path -notlike "*$pubCache*") {
  $env:Path += ";$pubCache"
}
flutterfire configure --platforms=android

Write-Host "6/6 Running tests and building the release APK..."
flutter test
flutter build apk --release
Write-Host "Done. APK: build\app\outputs\flutter-apk\app-release.apk"
