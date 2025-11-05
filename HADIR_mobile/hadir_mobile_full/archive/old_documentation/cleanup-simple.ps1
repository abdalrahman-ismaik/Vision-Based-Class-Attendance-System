# HADIR Mobile Project Cleanup Script
# Simplified version without complex heredoc strings

$ErrorActionPreference = "Continue"
$ProjectRoot = $PSScriptRoot

Write-Host "`nStarting HADIR Mobile Project Cleanup...`n" -ForegroundColor Cyan

# 1. Create archive structure
Write-Host "Creating archive directories..." -ForegroundColor Yellow
$ArchivePaths = @(
    "archive\backups",
    "archive\unused_core",
    "archive\old_documentation"
)

foreach ($path in $ArchivePaths) {
    $fullPath = Join-Path $ProjectRoot $path
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $path" -ForegroundColor Green
    }
}

# 2. Move backup files
Write-Host "`nArchiving backup files..." -ForegroundColor Yellow
$BackupFiles = Get-ChildItem -Path lib -Recurse -Filter *backup* -File -ErrorAction SilentlyContinue
foreach ($file in $BackupFiles) {
    $relativePath = $file.FullName.Replace("$ProjectRoot\lib\", "")
    $destPath = Join-Path "$ProjectRoot\archive\backups" $relativePath
    $destDir = Split-Path $destPath -Parent
    
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    Move-Item -Path $file.FullName -Destination $destPath -Force
    Write-Host "  Archived: $relativePath" -ForegroundColor Gray
}

# 3. Move unused core files
Write-Host "`nArchiving unused core files..." -ForegroundColor Yellow
$UnusedCoreFiles = @(
    "lib\core\frame_selection\enhanced_frame_selection_service.dart"
)

foreach ($file in $UnusedCoreFiles) {
    $fullPath = Join-Path $ProjectRoot $file
    if (Test-Path $fullPath) {
        $relativePath = $file.Replace("lib\", "")
        $destPath = Join-Path "$ProjectRoot\archive\unused_core" $relativePath
        $destDir = Split-Path $destPath -Parent
        
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Move-Item -Path $fullPath -Destination $destPath -Force
        Write-Host "  Archived: $relativePath" -ForegroundColor Gray
    }
}

# 4. Organize documentation
Write-Host "`nOrganizing documentation..." -ForegroundColor Yellow
$DocsDirs = @("docs\architecture", "docs\features", "docs\guides", "docs\api")
foreach ($dir in $DocsDirs) {
    $fullPath = Join-Path $ProjectRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# Move old docs to archive
$OldDocPatterns = @("*DEBUG*", "*CLEANUP*", "*CRITICAL*", "*FIX*", "*SUMMARY*", "*GUIDE*", "*REPORT*", "*COMPLETION*")
foreach ($pattern in $OldDocPatterns) {
    $files = Get-ChildItem -Path $ProjectRoot -Filter $pattern -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $destPath = Join-Path "$ProjectRoot\archive\old_documentation" $file.Name
        Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
        Write-Host "  Archived doc: $($file.Name)" -ForegroundColor Gray
    }
}

# 5. Flutter clean
Write-Host "`nCleaning build artifacts..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "  Flutter clean completed" -ForegroundColor Green

# 6. Remove empty directories
Write-Host "`nRemoving empty directories..." -ForegroundColor Yellow
Get-ChildItem -Path lib -Recurse -Directory | 
    Where-Object { -not (Get-ChildItem $_.FullName) } | 
    Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "  Empty directories removed" -ForegroundColor Green

# 7. Create simple summary
Write-Host "`nCreating project organization summary..." -ForegroundColor Yellow
$SummaryPath = Join-Path $ProjectRoot "PROJECT_ORGANIZATION.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

$SummaryContent = @"
# HADIR Mobile - Project Organization

Last Updated: $timestamp

## Directory Structure

- **lib/** - Main source code
  - **app/** - App configuration (router, theme)
  - **core/** - Core utilities and services
  - **features/** - Feature modules
    - auth/ - Authentication
    - dashboard/ - Dashboard
    - registration/ - Student registration (5-pose capture)
    - student_management/ - Student list and details (NEW)
  - **shared/** - Shared code across features

- **archive/** - Archived old files
  - backups/ - Backup files
  - unused_core/ - Unused core modules
  - old_documentation/ - Old documentation files

- **docs/** - Documentation
  - architecture/ - Architecture documentation
  - features/ - Feature documentation
  - guides/ - Development guides
  - api/ - API documentation

## Active Features

### Authentication
- Routes: /login
- Location: lib/features/auth/

### Student Registration
- Routes: /registration
- Features: 5-pose capture, frame selection, face detection
- Location: lib/features/registration/

### Dashboard
- Routes: /dashboard
- Features: Feature cards with navigation
- Location: lib/features/dashboard/

### Student Management (NEW)
- Routes: /students, /students/:id
- Features: List view, search, filter, sort, detail view with frames
- Location: lib/features/student_management/

## Next Steps

1. Review and test all active features
2. Update main README.md
3. Verify archived files can be removed
4. Document new features in docs/features/

---
Generated by: cleanup-simple.ps1
"@

Set-Content -Path $SummaryPath -Value $SummaryContent -Encoding UTF8
Write-Host "  Created PROJECT_ORGANIZATION.md" -ForegroundColor Green

# 8. Summary
Write-Host "`nCleanup completed!`n" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Backup files archived" -ForegroundColor White
Write-Host "  - Unused core files archived" -ForegroundColor White
Write-Host "  - Old documentation organized" -ForegroundColor White
Write-Host "  - Documentation structure created" -ForegroundColor White
Write-Host "  - Build artifacts cleaned" -ForegroundColor White
Write-Host "  - Empty directories removed" -ForegroundColor White
Write-Host "`nCheck PROJECT_ORGANIZATION.md for details`n" -ForegroundColor Yellow
