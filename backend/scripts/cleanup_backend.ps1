# Backend Directory Cleanup Script
# This script removes redundant files and organizes the backend structure
# Run from: backend/ directory

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend Directory Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Safety check
$currentDir = Get-Location
if (-not ($currentDir.Path -like "*backend*")) {
    Write-Host "ERROR: Please run this script from the backend directory" -ForegroundColor Red
    exit 1
}

Write-Host "Current directory: $currentDir" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue with cleanup (Ctrl+C to cancel)"

# Track what we're removing
$itemsToRemove = @()

# 1. Remove backend_working (now integrated into services/)
if (Test-Path "backend_working") {
    $itemsToRemove += "backend_working/"
}

# 2. Remove duplicate database files (keep root database.json)
if (Test-Path "data/database.json") {
    $itemsToRemove += "data/database.json"
}
if (Test-Path "data/classes.json") {
    $itemsToRemove += "data/classes.json"
}

# 3. Remove old test files
$oldTests = @(
    "test_pipeline_fix.py",
    "test_register_student.py"
)
foreach ($test in $oldTests) {
    if (Test-Path $test) {
        $itemsToRemove += $test
    }
}

# 4. Remove redundant documentation (keep only essential ones)
$oldDocs = @(
    "ARCHITECTURE_MIGRATION.md",
    "MIGRATION_GUIDE.md",
    "STRUCTURE_README.md"
)
foreach ($doc in $oldDocs) {
    if (Test-Path $doc) {
        $itemsToRemove += $doc
    }
}

# 5. Remove old scripts (superseded by current implementation)
$oldScripts = @(
    "scripts/fix_retinaface_line518.py",
    "scripts/fix_retinaface.py",
    "scripts/inspect_checkpoint.py",
    "scripts/manual_process.py",
    "scripts/process_pending_updated.py",
    "scripts/process_pending.py"
)
foreach ($script in $oldScripts) {
    if (Test-Path $script) {
        $itemsToRemove += $script
    }
}

# 6. Remove obsolete service files
if (Test-Path "services/opencv_face_processor.py") {
    $itemsToRemove += "services/opencv_face_processor.py"
}
if (Test-Path "services/PIPELINE_COMPARISON.md") {
    $itemsToRemove += "services/PIPELINE_COMPARISON.md"
}
if (Test-Path "services/res10_300x300_ssd_iter_140000.caffemodel") {
    $itemsToRemove += "services/res10_300x300_ssd_iter_140000.caffemodel"
}
if (Test-Path "services/opencv_models") {
    $itemsToRemove += "services/opencv_models/"
}

# 7. Remove duplicate model files (keep only in models/)
if (Test-Path "models/res10_300x300_ssd_iter_140000.caffemodel") {
    # This one is OK to keep in models/ directory
}

# 8. Remove empty or redundant directories
$emptyDirs = @(
    "storage/classifiers",
    "storage/processed_faces",
    "storage/uploads",
    "api"  # if empty
)
foreach ($dir in $emptyDirs) {
    if (Test-Path $dir) {
        $items = Get-ChildItem -Path $dir -Force
        if ($items.Count -eq 0) {
            $itemsToRemove += "$dir/"
        }
    }
}

# Display what will be removed
Write-Host "`nThe following items will be REMOVED:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
foreach ($item in $itemsToRemove) {
    Write-Host "  - $item" -ForegroundColor Red
}

Write-Host "`nTotal items to remove: $($itemsToRemove.Count)" -ForegroundColor Cyan
Write-Host ""

# Confirm deletion
$confirm = Read-Host "Type 'yes' to proceed with deletion"
if ($confirm -ne "yes") {
    Write-Host "`nCleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Perform cleanup
Write-Host "`nStarting cleanup..." -ForegroundColor Cyan
$removed = 0
$failed = 0

foreach ($item in $itemsToRemove) {
    try {
        if (Test-Path $item) {
            Remove-Item -Path $item -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Removed: $item" -ForegroundColor Green
            $removed++
        } else {
            Write-Host "  ⊘ Not found: $item" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ Failed to remove: $item" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

# Optional: Clean up processed_faces for old test data (FP* student IDs)
Write-Host "`n" -ForegroundColor Cyan
$cleanTestData = Read-Host "Do you want to clean up OLD test student data (234xxx, 10006xxx, FP* with old runs)? (yes/no)"
if ($cleanTestData -eq "yes") {
    Write-Host "Scanning processed_faces for old test data..." -ForegroundColor Cyan
    
    if (Test-Path "processed_faces") {
        $studentDirs = Get-ChildItem -Path "processed_faces" -Directory
        $oldTestStudents = @()
        
        foreach ($dir in $studentDirs) {
            # Check if it's an old test student
            if ($dir.Name -match "^234\d+$" -or 
                $dir.Name -match "^10006\d+$" -or
                ($dir.Name -match "^FP" -and $dir.CreationTime -lt (Get-Date).AddDays(-1))) {
                $oldTestStudents += $dir.FullName
            }
        }
        
        if ($oldTestStudents.Count -gt 0) {
            Write-Host "Found $($oldTestStudents.Count) old test student directories:" -ForegroundColor Yellow
            foreach ($dir in $oldTestStudents) {
                Write-Host "  - $(Split-Path $dir -Leaf)" -ForegroundColor Gray
            }
            
            $confirmTest = Read-Host "Remove these test directories? (yes/no)"
            if ($confirmTest -eq "yes") {
                foreach ($dir in $oldTestStudents) {
                    try {
                        Remove-Item -Path $dir -Recurse -Force
                        Write-Host "  ✓ Removed: $(Split-Path $dir -Leaf)" -ForegroundColor Green
                        $removed++
                    } catch {
                        Write-Host "  ✗ Failed: $(Split-Path $dir -Leaf)" -ForegroundColor Red
                        $failed++
                    }
                }
            }
        } else {
            Write-Host "No old test data found." -ForegroundColor Green
        }
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successfully removed: $removed items" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed to remove: $failed items" -ForegroundColor Red
}
Write-Host ""

# Show final directory structure
Write-Host "Current backend structure:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Get-ChildItem -Directory | Select-Object Name | Format-Table -HideTableHeaders

Write-Host "`n✓ Cleanup complete!" -ForegroundColor Green
Write-Host "Recommended: Run your tests to verify everything still works." -ForegroundColor Yellow
