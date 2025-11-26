// HADIR Live Attendance - Client-side JavaScript

class AttendanceMonitor {
    constructor() {
        this.detections = new Map();
        this.stats = {
            totalDetected: 0,
            registered: 0,
            unknown: 0
        };
        this.roster = [];
        this.recognizedStudents = new Set();
        this.currentClassId = null;
        
        this.init();
    }
    
    init() {
        console.log('Initializing HADIR Attendance Monitor...');
        
        // Check backend status
        this.checkBackendStatus();
        
        // Setup event listeners
        this.setupEventListeners();
        this.setupClassForm();
        this.fetchCurrentClassId();
        
        // Start FPS counter
        this.startFPSCounter();
        
        // Setup periodic updates
        setInterval(() => this.updateLastUpdateTime(), 1000);
        setInterval(() => this.checkRecognizedStudents(), 2000);
        
        console.log('✓ Attendance Monitor ready');
    }
    
    setupEventListeners() {
        // Fullscreen button
        const fullscreenBtn = document.getElementById('fullscreen-btn');
        const videoContainer = document.getElementById('video-container');
        
        fullscreenBtn?.addEventListener('click', () => {
            videoContainer.classList.toggle('fullscreen');
            fullscreenBtn.textContent = videoContainer.classList.contains('fullscreen') 
                ? '⛶ Exit Fullscreen' 
                : '⛶ Fullscreen';
        });
        
        // Clear detections button
        const clearBtn = document.getElementById('clear-btn');
        clearBtn?.addEventListener('click', () => {
            this.clearDetections();
        });
        
        // Escape key to exit fullscreen
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && videoContainer.classList.contains('fullscreen')) {
                videoContainer.classList.remove('fullscreen');
                fullscreenBtn.textContent = '⛶ Fullscreen';
            }
        });
    }

    setupClassForm() {
        const input = document.getElementById('class-id-input');
        const button = document.getElementById('class-save-btn');
        const hint = document.getElementById('class-hint');

        if (!input || !button) {
            return;
        }

            const saveClassId = async () => {
            const classId = input.value.trim();
            if (!classId) {
                this.showToast('Class ID cannot be empty', 'error');
                return;
            }

            button.disabled = true;
            hint.textContent = 'Saving...';

            try {
                const response = await fetch('/config/class', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ class_id: classId })
                });

                if (!response.ok) {
                    throw new Error('Failed to update class ID');
                }

                const data = await response.json();
                input.value = data.class_id || '';
                this.currentClassId = data.class_id;
                hint.textContent = `Active class: ${data.class_id}`;
                this.showToast('Class ID updated', 'success');
                
                // Fetch and display roster
                await this.fetchClassRoster();
            } catch (error) {
                console.error(error);
                hint.textContent = 'Unable to update class. Check server logs.';
                this.showToast('Failed to update class ID', 'error');
            } finally {
                button.disabled = false;
            }
        };        button.addEventListener('click', saveClassId);
        input.addEventListener('keyup', (event) => {
            if (event.key === 'Enter') {
                saveClassId();
            }
        });
    }

    async fetchCurrentClassId() {
        try {
            const response = await fetch('/config/class');
            if (!response.ok) {
                throw new Error('Failed to fetch class ID');
            }
            const data = await response.json();
            const input = document.getElementById('class-id-input');
            const hint = document.getElementById('class-hint');
            if (input && typeof data.class_id !== 'undefined') {
                input.value = data.class_id || '';
                if (hint) {
                    hint.textContent = data.class_id
                        ? `Active class: ${data.class_id}`
                        : 'Set the class that will receive attendance submissions.';
                }
            }
        } catch (error) {
            console.warn('Could not fetch class ID:', error);
        }
    }
    
    async checkBackendStatus() {
        const statusIndicator = document.getElementById('backend-status');
        const statusText = document.getElementById('backend-text');
        const backendUrl = document.getElementById('backend-url')?.textContent || 'http://127.0.0.1:5000';
        
        // Remove trailing slash if present
        const cleanBackendUrl = backendUrl.replace(/\/$/, '');
        
        try {
            // Fix: Ensure we don't double-append /api if backendUrl already has it
            // But typically backendUrl is just the host. 
            // The issue was likely `${backendUrl}/api/health/status` where backendUrl might have been '.../api'
            // Or the user provided backendUrl in the UI includes /api.
            
            // Let's assume backendUrl is the base URL (e.g. http://localhost:5000)
            // The endpoint is /api/health/status
            
            const response = await fetch(`${cleanBackendUrl}/api/health/status`, {
                method: 'GET',
                mode: 'cors'
            });
            
            if (response.ok) {
                statusIndicator.classList.add('active');
                statusIndicator.style.color = 'var(--success)';
                statusText.textContent = 'Connected';
                this.showToast('Backend connected successfully', 'success');
            } else {
                throw new Error('Backend not responding');
            }
        } catch (error) {
            console.warn('Backend connection failed:', error);
            statusIndicator.style.color = 'var(--danger)';
            statusText.textContent = 'Disconnected';
            this.showToast('Backend connection failed', 'error');
        }
    }
    
    startFPSCounter() {
        const videoFeed = document.getElementById('video-feed');
        const fpsCounter = document.getElementById('fps-counter');
        let lastFrameTime = Date.now();
        let frameCount = 0;
        let fps = 0;
        
        // Monitor video feed for frame updates
        const updateFPS = () => {
            frameCount++;
            const now = Date.now();
            const elapsed = now - lastFrameTime;
            
            if (elapsed >= 1000) {
                fps = Math.round(frameCount / (elapsed / 1000));
                fpsCounter.textContent = `FPS: ${fps}`;
                frameCount = 0;
                lastFrameTime = now;
            }
            
            requestAnimationFrame(updateFPS);
        };
        
        updateFPS();
    }
    
    addDetection(studentId, name, confidence, isRegistered = true) {
        const now = new Date();
        const detectionId = `${studentId}-${now.getTime()}`;
        
        // Check if already detected recently (within 30 seconds)
        const recentDetection = Array.from(this.detections.values()).find(
            d => d.studentId === studentId && (now - d.timestamp) < 30000
        );
        
        if (recentDetection) {
            return; // Don't add duplicate
        }
        
        // Add detection
        this.detections.set(detectionId, {
            studentId,
            name,
            confidence,
            isRegistered,
            timestamp: now
        });
        
        // Update stats
        this.stats.totalDetected++;
        if (isRegistered) {
            this.stats.registered++;
        } else {
            this.stats.unknown++;
        }
        
        // Update UI
        this.updateStats();
        this.updateDetectionsList();
        
        // Clean old detections (keep last 50)
        if (this.detections.size > 50) {
            const oldest = Array.from(this.detections.keys())[0];
            this.detections.delete(oldest);
        }
    }
    
    updateStats() {
        document.getElementById('total-detected').textContent = this.stats.totalDetected;
        document.getElementById('registered-count').textContent = this.stats.registered;
        document.getElementById('unknown-count').textContent = this.stats.unknown;
        this.updateLastUpdateTime();
    }
    
    updateLastUpdateTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit'
        });
        document.getElementById('last-update').textContent = timeString;
    }
    
    updateDetectionsList() {
        const listContainer = document.getElementById('detections-list');
        
        // Clear empty state
        const emptyState = listContainer.querySelector('.empty-state');
        if (emptyState && this.detections.size > 0) {
            emptyState.remove();
        }
        
        // Sort detections by timestamp (newest first)
        const sorted = Array.from(this.detections.entries())
            .sort((a, b) => b[1].timestamp - a[1].timestamp);
        
        // Rebuild list
        listContainer.innerHTML = '';
        
        if (sorted.length === 0) {
            listContainer.innerHTML = `
                <div class="empty-state">
                    <p>No detections yet</p>
                    <p class="hint">Faces will appear here when detected</p>
                </div>
            `;
            return;
        }
        
        sorted.forEach(([id, detection]) => {
            const item = this.createDetectionItem(detection);
            listContainer.appendChild(item);
        });
    }
    
    createDetectionItem(detection) {
        const div = document.createElement('div');
        div.className = `detection-item ${detection.isRegistered ? '' : 'unknown'}`;
        
        const timeString = detection.timestamp.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        
        div.innerHTML = `
            <div class="detection-info">
                <div class="detection-name">
                    ${detection.name || detection.studentId}
                </div>
                <div class="detection-meta">
                    ${detection.isRegistered 
                        ? `ID: ${detection.studentId} • Confidence: ${(detection.confidence * 100).toFixed(1)}%`
                        : 'Status: Unknown'}
                </div>
            </div>
            <div class="detection-time">${timeString}</div>
        `;
        
        return div;
    }
    
    clearDetections() {
        if (confirm('Clear all detections?')) {
            this.detections.clear();
            this.stats = {
                totalDetected: 0,
                registered: 0,
                unknown: 0
            };
            this.updateStats();
            this.updateDetectionsList();
            this.showToast('Detections cleared', 'success');
        }
    }
    
    showToast(message, type = 'info') {
        const toast = document.getElementById('toast');
        toast.textContent = message;
        toast.className = `toast ${type} show`;
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    async fetchClassRoster() {
        try {
            const response = await fetch('/api/class/roster');
            
            if (!response.ok) {
                if (response.status === 404) {
                    this.showToast('Class not found or has no students', 'warning');
                    this.hideRoster();
                    return;
                }
                throw new Error('Failed to fetch roster');
            }

            const data = await response.json();
            this.roster = data.students || [];
            this.currentClassId = data.class_id;
            
            if (this.roster.length > 0) {
                this.displayRoster();
                this.showToast(`Loaded ${this.roster.length} students`, 'success');
            } else {
                this.hideRoster();
                this.showToast('No students enrolled in this class', 'warning');
            }
        } catch (error) {
            console.error('Failed to fetch roster:', error);
            this.showToast('Failed to load class roster', 'error');
            this.hideRoster();
        }
    }

    displayRoster() {
        const rosterCard = document.getElementById('roster-card');
        const rosterList = document.getElementById('roster-list');
        
        rosterCard.style.display = 'block';
        rosterList.innerHTML = '';
        
        // Sort roster by student ID
        const sortedRoster = [...this.roster].sort((a, b) => 
            a.student_id.localeCompare(b.student_id)
        );
        
        sortedRoster.forEach(student => {
            const isPresent = this.recognizedStudents.has(student.student_id);
            const item = this.createRosterItem(student, isPresent);
            rosterList.appendChild(item);
        });
        
        this.updateAttendanceStats();
    }

    createRosterItem(student, isPresent = false) {
        const div = document.createElement('div');
        div.className = `roster-item ${isPresent ? 'present' : 'absent'}`;
        div.dataset.studentId = student.student_id;
        
        div.innerHTML = `
            <div class="roster-status">
                <span class="status-badge ${isPresent ? 'present' : 'absent'}">
                    ${isPresent ? '✓' : '✗'}
                </span>
            </div>
            <div class="roster-info">
                <div class="roster-name">${student.name || student.student_id}</div>
                <div class="roster-id">ID: ${student.student_id}</div>
            </div>
            <div class="roster-time" id="time-${student.student_id}">
                ${isPresent ? 'Present' : 'Absent'}
            </div>
        `;
        
        return div;
    }

    hideRoster() {
        const rosterCard = document.getElementById('roster-card');
        rosterCard.style.display = 'none';
    }

    async checkRecognizedStudents() {
        if (!this.currentClassId || this.roster.length === 0) {
            return;
        }

        try {
            const response = await fetch('/api/attendance/recognized');
            
            if (!response.ok) {
                return;
            }

            const data = await response.json();
            const recognizedList = data.recognized_students || [];
            
            recognizedList.forEach(student => {
                if (!this.recognizedStudents.has(student.student_id)) {
                    // New recognition
                    this.recognizedStudents.add(student.student_id);
                    this.markStudentPresent(student.student_id, student.timestamp);
                }
            });
        } catch (error) {
            console.debug('Failed to check recognized students:', error);
        }
    }

    markStudentPresent(studentId, timestamp) {
        const rosterItem = document.querySelector(`[data-student-id="${studentId}"]`);
        
        if (rosterItem) {
            rosterItem.classList.remove('absent');
            rosterItem.classList.add('present');
            
            const statusBadge = rosterItem.querySelector('.status-badge');
            statusBadge.textContent = '✓';
            statusBadge.classList.remove('absent');
            statusBadge.classList.add('present');
            
            const timeElement = rosterItem.querySelector(`#time-${studentId}`);
            if (timeElement && timestamp) {
                const time = new Date(timestamp * 1000);
                timeElement.textContent = time.toLocaleTimeString('en-US', {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit'
                });
            } else {
                timeElement.textContent = 'Present';
            }
            
            this.updateAttendanceStats();
        }
    }

    updateAttendanceStats() {
        const statsElement = document.getElementById('attendance-stats');
        const presentCount = this.recognizedStudents.size;
        const totalCount = this.roster.length;
        
        statsElement.textContent = `${presentCount}/${totalCount} Present`;
        
        // Update color based on attendance percentage
        const percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0;
        if (percentage >= 80) {
            statsElement.style.color = 'var(--success)';
        } else if (percentage >= 50) {
            statsElement.style.color = 'var(--warning)';
        } else {
            statsElement.style.color = 'var(--danger)';
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.attendanceMonitor = new AttendanceMonitor();
});

// Example: Simulate detection (for testing without backend)
// Uncomment to test UI
/*
setTimeout(() => {
    window.attendanceMonitor.addDetection('S12345', 'John Doe', 0.95, true);
}, 2000);

setTimeout(() => {
    window.attendanceMonitor.addDetection('UNKNOWN', 'Unknown', 0.0, false);
}, 4000);
*/
