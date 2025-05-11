import Foundation
import Combine
import os.log

class DataManager: ObservableObject {
    private let logger = Logger(subsystem: "com.yourdomain.TennisGameHost", category: "DataManager")
    
    // Published properties
    @Published var gyroDataHistory: [String: [GyroData]] = [:]
    @Published var lastProcessedTimestamp: Date = Date()
    
    // For calculating movement statistics
    @Published var movementStats: [String: MovementStats] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTimers()
    }
    
    // Process new gyro data from a player
    func processGyroData(_ data: GyroData, from playerID: String) {
        DispatchQueue.main.async {
            // Store data in history
            if self.gyroDataHistory[playerID] == nil {
                self.gyroDataHistory[playerID] = []
            }
            
            // Keep history at a reasonable size (last 100 readings)
            var history = self.gyroDataHistory[playerID] ?? []
            history.append(data)
            
            if history.count > 100 {
                history.removeFirst(history.count - 100)
            }
            
            self.gyroDataHistory[playerID] = history
            
            // Update movement statistics
            self.updateMovementStats(for: playerID)
            
            // Update timestamp
            self.lastProcessedTimestamp = Date()
        }
    }
    
    // Calculate movement statistics based on gyro data
    private func updateMovementStats(for playerID: String) {
        guard let history = gyroDataHistory[playerID], history.count >= 2 else {
            return
        }
        
        // Take the last 10 readings or less if not available
        let samples = min(10, history.count)
        let recentData = Array(history.suffix(samples))
        
        // Calculate average magnitude
        let avgMagnitude = recentData.map { $0.magnitude }.reduce(0, +) / Double(recentData.count)
        
        // Calculate max values for each axis
        let maxX = recentData.map { abs($0.x) }.max() ?? 0
        let maxY = recentData.map { abs($0.y) }.max() ?? 0
        let maxZ = recentData.map { abs($0.z) }.max() ?? 0
        
        // Create or update stats
        let stats = MovementStats(
            averageMagnitude: avgMagnitude,
            maxX: maxX,
            maxY: maxY,
            maxZ: maxZ,
            timestamp: Date()
        )
        
        movementStats[playerID] = stats
    }
    
    // Clear all data for a player
    func clearPlayerData(for playerID: String) {
        DispatchQueue.main.async {
            self.gyroDataHistory.removeValue(forKey: playerID)
            self.movementStats.removeValue(forKey: playerID)
        }
    }
    
    // Setup periodic cleanup timers
    private func setupTimers() {
        // Cleanup old data periodically (every minute)
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldData()
            }
            .store(in: &cancellables)
    }
    
    // Remove stale data
    private func cleanupOldData() {
        let currentTime = Date()
        let staleThreshold: TimeInterval = 300 // 5 minutes
        
        for playerID in gyroDataHistory.keys {
            if let lastStats = movementStats[playerID],
               currentTime.timeIntervalSince(lastStats.timestamp) > staleThreshold {
                clearPlayerData(for: playerID)
                logger.info("Cleared stale data for player: \(playerID)")
            }
        }
    }
}

// Structure to hold movement statistics
struct MovementStats {
    var averageMagnitude: Double
    var maxX: Double
    var maxY: Double
    var maxZ: Double
    var timestamp: Date
    
    // Determine if there's significant movement
    var isSignificantMovement: Bool {
        return averageMagnitude > 0.5 // Threshold can be adjusted
    }
}
