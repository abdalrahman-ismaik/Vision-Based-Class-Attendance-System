# HADIR Mobile Project Cleanup Script
# This script organizes and cleans up the project structure

Write-Host "🧹 Starting HADIR Mobile Project Cleanup..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$ProjectRoot = "d:\Education\University\Fall 2025\COSC 330 - Intro to Artificial Intelligence\Project\HADIR\HADIR\hadir_mobile_full"
Set-Location $ProjectRoot

# Create archive directory for old/backup files
$ArchiveDir = Join-Path $ProjectRoot "archive"
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir | Out-Null
    Write-Host "✅ Created archive directory" -ForegroundColor Green
}

# 1. Move backup files to archive
Write-Host "`n📦 Moving backup files to archive..." -ForegroundColor Yellow
$BackupFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*backup*" -File
foreach ($file in $BackupFiles) {
    $relativePath = $file.FullName.Replace("$ProjectRoot\lib\", "")
    $archivePath = Join-Path $ArchiveDir "backups\$relativePath"
    $archiveDir = Split-Path $archivePath -Parent
    
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    
    Move-Item -Path $file.FullName -Destination $archivePath -Force
    Write-Host "  Moved: $($file.Name)" -ForegroundColor Gray
}

# 2. Move old unused core files to archive
Write-Host "`n📦 Archiving unused core files..." -ForegroundColor Yellow
$UnusedCoreFiles = @(
    "lib\core\capture_control\multi_pose_capture_controller.dart",
    "lib\core\computer_vision\ml_kit_face_detector.dart",
    "lib\core\frame_selection\enhanced_frame_selection_service.dart"
)

foreach ($file in $UnusedCoreFiles) {
    $fullPath = Join-Path $ProjectRoot $file
    if (Test-Path $fullPath) {
        $relativePath = $file.Replace("lib\", "")
        $archivePath = Join-Path $ArchiveDir "unused_core\$relativePath"
        $archiveDir = Split-Path $archivePath -Parent
        
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        }
        
        Move-Item -Path $fullPath -Destination $archivePath -Force
        Write-Host "  Archived: $relativePath" -ForegroundColor Gray
    }
}

# 3. Move old documentation to archive
Write-Host "`n📦 Organizing documentation..." -ForegroundColor Yellow
$OldDocs = Get-ChildItem -Path $ProjectRoot -Filter "*.md" -File | Where-Object {
    $_.Name -match "DEBUG|CLEANUP|CRITICAL|FIX|SUMMARY|GUIDE|REPORT|CHECKLIST|COMPLETION" -and
    $_.Name -ne "README.md" -and
    $_.Name -ne "CHANGELOG.md"
}

if ($OldDocs.Count -gt 0) {
    $docsArchive = Join-Path $ArchiveDir "old_documentation"
    if (-not (Test-Path $docsArchive)) {
        New-Item -ItemType Directory -Path $docsArchive -Force | Out-Null
    }
    
    foreach ($doc in $OldDocs) {
        Move-Item -Path $doc.FullName -Destination (Join-Path $docsArchive $doc.Name) -Force
        Write-Host "  Archived: $($doc.Name)" -ForegroundColor Gray
    }
}

# 4. Create organized docs structure
Write-Host "`n📁 Creating organized documentation structure..." -ForegroundColor Yellow
$DocsDir = Join-Path $ProjectRoot "docs"
if (-not (Test-Path $DocsDir)) {
    New-Item -ItemType Directory -Path $DocsDir | Out-Null
}

$DocFolders = @("architecture", "features", "guides", "api")
foreach ($folder in $DocFolders) {
    $folderPath = Join-Path $DocsDir $folder
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
        Write-Host "  Created: docs/$folder" -ForegroundColor Gray
    }
}

# 5. Move remaining important docs to proper locations
if (Test-Path (Join-Path $ProjectRoot "ARCHITECTURE.md")) {
    Move-Item -Path (Join-Path $ProjectRoot "ARCHITECTURE.md") -Destination (Join-Path $DocsDir "architecture\ARCHITECTURE.md") -Force
    Write-Host "  Moved ARCHITECTURE.md to docs/architecture/" -ForegroundColor Gray
}

if (Test-Path (Join-Path $ProjectRoot "PROJECT_STRUCTURE.md")) {
    Move-Item -Path (Join-Path $ProjectRoot "PROJECT_STRUCTURE.md") -Destination (Join-Path $DocsDir "architecture\PROJECT_STRUCTURE.md") -Force
    Write-Host "  Moved PROJECT_STRUCTURE.md to docs/architecture/" -ForegroundColor Gray
}

# 6. Clean build artifacts
Write-Host "`n🗑️  Cleaning build artifacts..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "  ✅ Flutter clean completed" -ForegroundColor Green

# 7. Remove empty directories
Write-Host "`n🗑️  Removing empty directories..." -ForegroundColor Yellow
Get-ChildItem -Path "lib" -Recurse -Directory | 
    Where-Object { (Get-ChildItem $_.FullName -Recurse -File).Count -eq 0 } |
    Remove-Item -Recurse -Force
Write-Host "  ✅ Empty directories removed" -ForegroundColor Green

# 8. Create project organization summary
Write-Host "`n📝 Creating project structure summary..." -ForegroundColor Yellow
$SummaryPath = Join-Path $ProjectRoot "PROJECT_ORGANIZATION.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$Summary = @"
# HADIR Mobile - Project Organization

## Directory Structure

``````
hadir_mobile_full/
├── lib/                          # Main source code
│   ├── app/                      # App-level configuration
│   │   ├── router/              # Navigation & routing
│   │   └── theme/               # App theming
│   ├── core/                     # Core utilities & services
│   ├── features/                 # Feature modules
│   │   ├── auth/                # Authentication
│   │   ├── dashboard/           # Dashboard
│   │   ├── registration/        # Student registration
│   │   └── student_management/  # Student list & details
│   └── shared/                   # Shared code across features
├── test/                         # Unit & widget tests
├── docs/                         # Documentation
│   ├── architecture/            # Architecture docs
│   ├── features/                # Feature documentation
│   ├── guides/                  # Development guides
│   └── api/                     # API documentation
├── archive/                      # Archived old files
│   ├── backups/                 # Backup files
│   ├── unused_core/             # Unused core files
│   └── old_documentation/       # Old docs
└── README.md                     # Project readme

``````

## Active Features

### 1. Authentication
- Location: lib/features/auth/
- Status: Active
- Routes: /login

### 2. Student Registration
- Location: lib/features/registration/
- Status: Active
- Routes: /registration
- Features: 5-pose capture, frame selection

### 3. Dashboard
- Location: lib/features/dashboard/
- Status: Active
- Routes: /dashboard

### 4. Student Management
- Location: lib/features/student_management/
- Status: Active (Newly Added)
- Routes: /students, /students/:id
- Features: List view, search, filter, sort, detail view with frames

## Archived Items

All backup files, unused core modules, and old documentation have been moved to the archive/ directory for reference.

## Next Steps

- Review active features and test thoroughly
- Update README.md with current project status
- Consider removing archived files after verification
- Document any new features in docs/features/

Last Updated: $timestamp
Generated by: cleanup_project.ps1
"@

Set-Content -Path $SummaryPath -Value $Summary -Encoding UTF8
Write-Host "  Created PROJECT_ORGANIZATION.md" -ForegroundColor Green

Write-Host "`n✨ Project cleanup completed!" -ForegroundColor Cyan
Write-Host "`n📊 Summary:" -ForegroundColor Yellow
Write-Host "  - Backup files archived" -ForegroundColor White
Write-Host "  - Unused core files archived" -ForegroundColor White
Write-Host "  - Old documentation organized" -ForegroundColor White
Write-Host "  - Documentation structure created" -ForegroundColor White
Write-Host "  - Build artifacts cleaned" -ForegroundColor White
Write-Host "  - Empty directories removed" -ForegroundColor White
Write-Host "`n📁 Check PROJECT_ORGANIZATION.md for details" -ForegroundColor Cyan
Write-Host ""
