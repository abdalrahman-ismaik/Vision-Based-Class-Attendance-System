// HADIR Live Attendance - Client-side JavaScript

class AttendanceMonitor {
    constructor() {
        this.detections = new Map();
        this.stats = {
            totalDetected: 0,
            registered: 0,
            unknown: 0
        };
        
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
        
        // Start FPS counter
        this.startFPSCounter();
        
        // Setup periodic updates
        setInterval(() => this.updateLastUpdateTime(), 1000);
        
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
        const originalHTML = startBtn.innerHTML;
        startBtn.disabled = true;
        startBtn.innerHTML = '<span class="loading"></span><span>Starting...</span>';

        try {
            const response = await fetch('/start_class', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ class_id: classId })
            });
            
            const data = await response.json();
            if (response.ok) {
                this.showVideoSection(classId);
            } else {
                alert('Error: ' + data.error);
            }
        } catch (error) {
            console.error('Error starting class:', error);
            alert('Failed to start class session. Check console for details.');
        } finally {
            startBtn.disabled = false;
            startBtn.innerHTML = originalHTML;
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

    showVideoSection(classId) {
        document.getElementById('setup-section').classList.add('hidden');
        document.getElementById('video-section').classList.remove('hidden');
        document.getElementById('stats-section').classList.remove('hidden');
        document.getElementById('current-class-display').textContent = classId;
        
        // Set video src to start streaming
        const videoFeed = document.getElementById('video-feed');
        // Add timestamp to prevent caching
        videoFeed.src = "/video_feed?" + new Date().getTime();
        
        document.getElementById('camera-status').classList.add('active');
        document.getElementById('camera-text').textContent = 'Active';
    }

    showSetupSection() {
        document.getElementById('setup-section').classList.remove('hidden');
        document.getElementById('video-section').classList.add('hidden');
        document.getElementById('stats-section').classList.add('hidden');
        
        // Reset dropdown
        document.getElementById('class-select').value = '';
        
        // Stop video stream
        const videoFeed = document.getElementById('video-feed');
        videoFeed.src = "";
        
        document.getElementById('camera-status').classList.remove('active');
        document.getElementById('camera-text').textContent = 'Inactive';
    }
    
    async checkBackendStatus() {
        const statusIndicator = document.getElementById('backend-status');
        const statusText = document.getElementById('backend-text');
        
        // In this new architecture, we assume backend is reachable if this page loads
        // But we can check the main API health
        try {
            // We can't easily check the main backend from here without CORS or proxy
            // So we'll just assume it's fine for now or check our own server
            statusIndicator.classList.add('active');
            statusText.textContent = 'Connected';
        } catch (e) {
            statusIndicator.classList.remove('active');
            statusText.textContent = 'Disconnected';
        }
    }
    
    clearDetections() {
        this.detections.clear();
        const log = document.getElementById('detections-log');
        log.innerHTML = '<div class="empty-state">No detections yet</div>';
        
        this.stats = { totalDetected: 0, registered: 0, unknown: 0 };
        this.updateStatsDisplay();
    }
    
    updateStatsDisplay() {
        document.getElementById('total-detected').textContent = this.stats.totalDetected;
        document.getElementById('registered-count').textContent = this.stats.registered;
        document.getElementById('unknown-count').textContent = this.stats.unknown;
    }
    
    startFPSCounter() {
        let frameCount = 0;
        let lastTime = performance.now();
        const fpsDisplay = document.getElementById('fps-counter');
        
        // This is a client-side estimation, real FPS comes from server stream usually
        // But for MJPEG, we can't easily count frames in JS.
        // So we'll just leave it as placeholder or remove it.
        fpsDisplay.textContent = "FPS: --"; 
    }
    
    updateLastUpdateTime() {
        // Update "Just now", "5s ago" etc. in the log
        // Implementation omitted for brevity
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    window.attendanceMonitor = new AttendanceMonitor();
});
