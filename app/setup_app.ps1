# Qadam app setup (Windows PowerShell, run from the repo's app\ folder):
#   cd app
#   .\setup_app.ps1
# Creates the Android project around the provided lib\ code, adds packages, assets and permissions.
# Existing files (lib\, test\foot_rule_test.dart) are NOT overwritten by `flutter create`.

$ErrorActionPreference = "Stop"

flutter create --org tn.qadam --project-name qadam_app --platforms android .
Remove-Item -ErrorAction SilentlyContinue test\widget_test.dart   # default test refers to the counter app

flutter pub add provider mqtt_client http hive hive_flutter fl_chart url_launcher pdf printing audioplayers
flutter pub add flutter_localizations --sdk=flutter

# assets/audio/ for the Derja voice clips
$pub = Get-Content pubspec.yaml -Raw
if ($pub -notmatch "assets/audio/") {
  $pub = $pub -replace "  uses-material-design: true", "  uses-material-design: true`n  assets:`n    - assets/audio/"
  Set-Content pubspec.yaml $pub
}

# INTERNET permission for release builds (MQTT + Gemini)
$man = "android\app\src\main\AndroidManifest.xml"
$xml = Get-Content $man -Raw
if ($xml -notmatch "android.permission.INTERNET") {
  $xml = $xml -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`n    <application"
  Set-Content $man $xml
}

flutter pub get
flutter analyze
flutter test
Write-Host "`nDone. Run on your phone with:" -ForegroundColor Green
Write-Host "  flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY"
