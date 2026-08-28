param(
    [switch] $SkipAnalyze
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$MobileDir = Join-Path $Root "rabbitrack-mobile"

Push-Location $MobileDir
try {
    if (-not $SkipAnalyze) {
        Write-Host "[RabbiTrack] Running targeted Dart analysis..."
        dart analyze `
            lib/src/features/auth/auth_repository.dart `
            lib/src/features/home/farm_summary_controller.dart `
            lib/src/features/rabbits/rabbit_repository.dart `
            lib/src/features/breeding/mating_repository.dart `
            lib/src/features/litters/litter_repository.dart `
            lib/src/features/health/health_repository.dart `
            lib/src/features/tasks/task_repository.dart `
            lib/src/features/reports/finance_report_repository.dart `
            lib/src/shared/offline_action_queue.dart `
            lib/src/shared/offline_demo_data.dart
    }

    Write-Host "[RabbiTrack] Running focused offline Flutter tests..."
    flutter test `
        test/features/auth/auth_error_messages_test.dart `
        test/features/rabbits/rabbit_repository_test.dart `
        test/features/breeding/mating_repository_test.dart `
        test/features/litters/litter_repository_test.dart `
        test/features/health/health_repository_test.dart `
        test/features/tasks/task_repository_test.dart `
        test/features/reports/finance_report_repository_test.dart `
        test/features/offline_remaining_repositories_test.dart `
        test/features/weights/weight_repository_test.dart `
        test/shared/offline_action_queue_test.dart

    Write-Host "[RabbiTrack] Offline mobile checks passed."
} finally {
    Pop-Location
}
