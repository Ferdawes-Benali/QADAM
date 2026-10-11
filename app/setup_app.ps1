# Qadam app setup (Windows PowerShell, run from the app\ folder):   .\setup_app.ps1
# Generates the Android project if missing, applies Qadam's Android overrides (manifest, launcher icons),
# fetches packages, then runs the static analysis and the unit tests.
$ErrorActionPreference = "Stop"
if (-not (Test-Path "android")) {
    flutter create --org tn.qadam --project-name qadam_app --platforms android .
    if (Test-Path "test\widget_test.dart") { Remove-Item "test\widget_test.dart" }
}
Copy-Item -Recurse -Force "android_overrides\*" "android\"
# Kotlin incremental cache breaks when the project (D:) and the pub cache (C:) are on different drives
$gp = "android\gradle.properties"
if (-not (Select-String -Path $gp -Pattern "kotlin.incremental=false" -Quiet)) { Add-Content $gp "`nkotlin.incremental=false" }
flutter pub get
flutter analyze
flutter test
Write-Host "`nReady. Run on the phone with:  flutter run" -ForegroundColor Green
