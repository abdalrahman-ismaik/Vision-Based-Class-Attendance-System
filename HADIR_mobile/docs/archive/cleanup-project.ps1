# HADIR Project Cleanup Script
# Purpose: Clean build artifacts, organize documentation, and optimize disk usage
# Run with: .\cleanup-project.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HADIR Project Cleanup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to get folder size
function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

# Track total space recovered
$totalRecovered = 0

# 1. Clean Flutter Build Artifacts (hadir_mobile_full)
Write-Host "[1/5] Cleaning hadir_mobile_full build artifacts..." -ForegroundColor Yellow
$buildSize = Get-FolderSize "hadir_mobile_full\build"
$dartToolSize = Get-FolderSize "hadir_mobile_full\.dart_tool"

if ($buildSize -gt 0 -or $dartToolSize -gt 0) {
    Push-Location hadir_mobile_full
    flutter clean
    Pop-Location
    $recovered = $buildSize + $dartToolSize
    $totalRecovered += $recovered
    Write-Host "  ✅ Recovered: $recovered MB" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Already clean" -ForegroundColor Gray
}

# 2. Clean Flutter Build Artifacts (hadir_mobile_mvp)
Write-Host "[2/5] Cleaning hadir_mobile_mvp build artifacts..." -ForegroundColor Yellow
$buildSizeMvp = Get-FolderSize "hadir_mobile_mvp\build"
$dartToolSizeMvp = Get-FolderSize "hadir_mobile_mvp\.dart_tool"

if ($buildSizeMvp -gt 0 -or $dartToolSizeMvp -gt 0) {
    Push-Location hadir_mobile_mvp
    flutter clean
    Pop-Location
    $recovered = $buildSizeMvp + $dartToolSizeMvp
    $totalRecovered += $recovered
    Write-Host "  ✅ Recovered: $recovered MB" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Already clean" -ForegroundColor Gray
}

# 3. Clean Python Cache
Write-Host "[3/5] Cleaning Python cache files..." -ForegroundColor Yellow
$pycacheSize = 0

$pycacheFolders = @(
    "frame_selection_service\__pycache__",
    "frame_selection_service\services\__pycache__"
)

foreach ($folder in $pycacheFolders) {
    if (Test-Path $folder) {
        $size = Get-FolderSize $folder
        $pycacheSize += $size
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($pycacheSize -gt 0) {
    $totalRecovered += $pycacheSize
    Write-Host "  ✅ Recovered: $pycacheSize MB" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  No cache files found" -ForegroundColor Gray
}

# 4. Create docs/archive folder and move historical documents
Write-Host "[4/5] Organizing documentation..." -ForegroundColor Yellow

# Create archive folder if it doesn't exist
if (-not (Test-Path "docs\archive")) {
    New-Item -ItemType Directory -Path "docs\archive" -Force | Out-Null
    Write-Host "  ✅ Created docs/archive folder" -ForegroundColor Green
}

# Historical documents to archive
$historicalDocs = @(
    "ML_KIT_REFACTORING_SUMMARY.md",
    "REFACTORING_CHECKLIST.md",
    "REGISTRATION_SEPARATION.md",
    "SESSION_SUMMARY.md",
    "VALIDATION_IMPLEMENTATION_SUMMARY.md",
    "VALIDATION_VISUAL_GUIDE.md",
    "VideoCapturingUpdate.md",
    "VideoCapturingUpdate_Implementation_Summary.md",
    "CAMERA_PREVIEW_VISUAL_GUIDE.md"
)

$movedCount = 0
foreach ($doc in $historicalDocs) {
    if (Test-Path $doc) {
        Move-Item -Path $doc -Destination "docs\archive\" -Force
        $movedCount++
    }
}

if ($movedCount -gt 0) {
    Write-Host "  ✅ Archived $movedCount historical documents" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  No documents to archive" -ForegroundColor Gray
}

# 5. Optional: Archive hadir_mobile_mvp
Write-Host "[5/5] Checking hadir_mobile_mvp folder..." -ForegroundColor Yellow
$mvpSize = Get-FolderSize "hadir_mobile_mvp"

if ($mvpSize -gt 0) {
    Write-Host "  ⚠️  hadir_mobile_mvp found ($mvpSize MB)" -ForegroundColor Yellow
    Write-Host "  ℹ️  This is the old MVP version. Options:" -ForegroundColor Cyan
    Write-Host "     1. Keep as reference (do nothing)" -ForegroundColor Gray
    Write-Host "     2. Archive it (rename to archive_hadir_mobile_mvp)" -ForegroundColor Gray
    Write-Host "     3. Delete it (manual deletion recommended)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ℹ️  Action: Skipping automatic cleanup (user decision required)" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Disk Space Recovered: $totalRecovered MB" -ForegroundColor Green
Write-Host ""

# Recommendations
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. ✅ Build artifacts cleaned" -ForegroundColor Green
Write-Host "  2. ✅ Python cache removed" -ForegroundColor Green
Write-Host "  3. ✅ Historical docs archived" -ForegroundColor Green
Write-Host "  4. ⏭️  Review hadir_mobile_mvp folder (manual decision)" -ForegroundColor Yellow
Write-Host "  5. ⏭️  Run 'flutter pub get' in hadir_mobile_full" -ForegroundColor Yellow
Write-Host ""

# Additional recommendations
Write-Host "💡 Recommendations:" -ForegroundColor Cyan
Write-Host "  • Add 'build/' to .gitignore if not already present" -ForegroundColor Gray
Write-Host "  • Add '__pycache__/' to .gitignore" -ForegroundColor Gray
Write-Host "  • Run this script periodically to maintain clean workspace" -ForegroundColor Gray
Write-Host ""

Write-Host "✨ Cleanup complete!" -ForegroundColor Green
