// HADIR Live Attendance - Client-side JavaScript

class AttendanceMonitor {
    constructor() {
        this.detections = new Map();
        this.sessionActive = false;
        this.statsInterval = null;
        
        this.init();
    }
    
    init() {
        console.log('Initializing HADIR Attendance Monitor...');
        
        // Check backend status
        this.checkBackendStatus();
        
        // Load available classes
        this.loadClasses();
        
        // Setup event listeners
        this.setupEventListeners();
        
        console.log('✓ Attendance Monitor ready');
    }
    
    setupEventListeners() {
        // Clear detections button
        const clearBtn = document.getElementById('clear-btn');
        clearBtn?.addEventListener('click', () => {
            this.clearDetections();
        });

        // Start Class Button
        const startBtn = document.getElementById('start-class-btn');
        startBtn?.addEventListener('click', () => this.startClass());

        // Stop Class Button
        const stopBtn = document.getElementById('stop-class-btn');
        stopBtn?.addEventListener('click', () => this.stopClass());
    }

    async loadClasses() {
        try {
            const response = await fetch('/api/classes/');
            const data = await response.json();
            
            const classSelect = document.getElementById('class-select');
            classSelect.innerHTML = '<option value="">-- Select a class --</option>';
            
            if (data.classes && data.classes.length > 0) {
                data.classes.forEach(cls => {
                    const option = document.createElement('option');
                    option.value = cls.class_id;
                    option.textContent = `${cls.class_id} - ${cls.class_name}`;
                    classSelect.appendChild(option);
                });
            } else {
                classSelect.innerHTML = '<option value="">No classes available</option>';
            }
        } catch (error) {
            console.error('Error loading classes:', error);
            const classSelect = document.getElementById('class-select');
            classSelect.innerHTML = '<option value="">Error loading classes</option>';
        }
    }

    async startClass() {
        const classSelect = document.getElementById('class-select');
        const classId = classSelect.value.trim();
        
        if (!classId) {
            alert('Please select a class from the dropdown');
            return;
        }

        const startBtn = document.getElementById('start-class-btn');
        startBtn.disabled = true;
        startBtn.textContent = 'Starting...';

        try {
            const response = await fetch('/start_class', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ class_id: classId })
            });
            
            const data = await response.json();
            if (response.ok) {
                this.showMainView(classId);
            } else {
                alert('Error: ' + data.error);
            }
        } catch (error) {
            console.error('Error starting class:', error);
            alert('Failed to start class session. Check console for details.');
        } finally {
            startBtn.disabled = false;
            startBtn.textContent = 'Start Session';
        }
    }

    async stopClass() {
        try {
            await fetch('/stop_class', { method: 'POST' });
            this.showSetupSection();
        } catch (error) {
            console.error('Error stopping class:', error);
        }
    }

    showMainView(classId) {
        document.getElementById('setup-section').classList.add('hidden');
        document.getElementById('main-view').classList.remove('hidden');
        document.getElementById('class-info').classList.remove('hidden');
        document.getElementById('stop-class-btn').classList.remove('hidden');
        document.getElementById('current-class-name').textContent = classId;
        
        // Set video src to start streaming
        const videoFeed = document.getElementById('video-feed');
        videoFeed.src = "/video_feed?" + new Date().getTime();
        
        document.getElementById('camera-status').classList.add('active');
        
        // Start fetching stats
        this.sessionActive = true;
        this.startStatsPolling();
    }

    showSetupSection() {
        document.getElementById('setup-section').classList.remove('hidden');
        document.getElementById('main-view').classList.add('hidden');
        document.getElementById('class-info').classList.add('hidden');
        document.getElementById('stop-class-btn').classList.add('hidden');
        
        // Reset dropdown
        document.getElementById('class-select').value = '';
        
        // Stop video stream
        const videoFeed = document.getElementById('video-feed');
        videoFeed.src = "";
        
        document.getElementById('camera-status').classList.remove('active');
        
        // Stop fetching stats
        this.sessionActive = false;
        this.stopStatsPolling();
    }
    
    startStatsPolling() {
        // Fetch stats every 2 seconds
        this.statsInterval = setInterval(() => {
            this.fetchStats();
            this.fetchDetections();
        }, 2000);
        
        // Fetch immediately
        this.fetchStats();
        this.fetchDetections();
    }
    
    stopStatsPolling() {
        if (this.statsInterval) {
            clearInterval(this.statsInterval);
            this.statsInterval = null;
        }
    }
    
    async fetchStats() {
        if (!this.sessionActive) return;
        
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            
            // Update stats display
            document.getElementById('session-time').textContent = this.formatTime(data.session_uptime);
            document.getElementById('total-detections').textContent = data.total_detections;
            document.getElementById('registered-count').textContent = data.registered_count || 0;
            document.getElementById('unknown-count').textContent = data.unknown_count;
            
        } catch (error) {
            console.error('Error fetching stats:', error);
        }
    }
    
    async fetchDetections() {
        if (!this.sessionActive) return;
        
        try {
            const response = await fetch('/api/detections');
            const data = await response.json();
            
            // Update detections list
            this.updateDetectionsList(data.detections || []);
            
        } catch (error) {
            console.error('Error fetching detections:', error);
        }
    }
    
    updateDetectionsList(detections) {
        const log = document.getElementById('detections-log');
        
        if (detections.length === 0) {
            log.innerHTML = '<div class="empty-state">No detections yet</div>';
            return;
        }
        
        log.innerHTML = detections.map(det => {
            const time = this.formatDetectionTime(det.timestamp);
            const confidencePercent = (det.confidence * 100).toFixed(1);
            const isUnknown = det.is_unknown;
            
            return `
                <div class="detection-item">
                    <div class="detection-header">
                        <span class="detection-name">${det.student_name}</span>
                        <span class="detection-time">${time}</span>
                    </div>
                    <div class="detection-details">
                        <span class="detection-id">${det.student_id}</span>
                        ${!isUnknown ? `<span class="detection-confidence">${confidencePercent}%</span>` : ''}
                    </div>
                </div>
            `;
        }).join('');
    }
    
    formatDetectionTime(timestamp) {
        const now = Date.now() / 1000;
        const diff = Math.floor(now - timestamp);
        
        if (diff < 5) return 'Just now';
        if (diff < 60) return `${diff}s ago`;
        if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
        return `${Math.floor(diff / 3600)}h ago`;
    }
    
    formatTime(seconds) {
        if (!seconds) return '00:00';
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }
    
    async checkBackendStatus() {
        const statusIndicator = document.getElementById('backend-status');
        
        try {
            // Check if we can reach the classes endpoint
            const response = await fetch('/api/classes/');
            if (response.ok) {
                statusIndicator.classList.add('active');
            }
        } catch (e) {
            statusIndicator.classList.remove('active');
        }
    }
    
    clearDetections() {
        const log = document.getElementById('detections-log');
        log.innerHTML = '<div class="empty-state">No detections yet</div>';
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    window.attendanceMonitor = new AttendanceMonitor();
});
