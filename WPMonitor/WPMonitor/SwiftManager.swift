import Foundation
import Combine

class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published var currentWPM: Int = 0
    @Published var currentCPM: Int = 0
    @Published var totalKeystrokes: Int = 0
    @Published var totalWords: Int = 0
    @Published var highestWPMToday: Int = 0
    @Published var averageWPMToday: Double = 0
    @Published var consistency: Double = 0
    @Published var activeTime: TimeInterval = 0

    private var wordTimestamps: [Date] = []
    private var keystrokeTimestamps: [Date] = []
    private var wpmHistory: [Int] = []
    private var sessionStartTime: Date?
    private var lastActivityTime: Date?
    private let userDefaults = UserDefaults.standard

    private let wpmWindow: TimeInterval = 60.0 // 1 minute window for WPM calculation
    private let inactivityThreshold: TimeInterval = 5.0 // 5 seconds of inactivity

    init() {
        loadStats()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateStats()
            }
        }
    }

    func incrementKeystroke() {
        DispatchQueue.main.async {
            self.totalKeystrokes += 1
            self.keystrokeTimestamps.append(Date())
            self.lastActivityTime = Date()

            if self.sessionStartTime == nil {
                self.sessionStartTime = Date()
            }

            // Clean old timestamps
            let cutoff = Date().addingTimeInterval(-self.wpmWindow)
            self.keystrokeTimestamps.removeAll { $0 < cutoff }

            self.saveStats()

            // Force immediate UI update
            self.objectWillChange.send()
        }
    }

    func addWord(at time: Date) {
        DispatchQueue.main.async {
            self.totalWords += 1
            self.wordTimestamps.append(time)

            // Clean old timestamps
            let cutoff = time.addingTimeInterval(-self.wpmWindow)
            self.wordTimestamps.removeAll { $0 < cutoff }

            // Force immediate UI update
            self.objectWillChange.send()
        }
    }

    private func updateStats() {
        // Check for inactivity
        if let lastActivity = lastActivityTime,
           Date().timeIntervalSince(lastActivity) > inactivityThreshold {
            sessionStartTime = nil
        }

        // Update active time
        if let startTime = sessionStartTime {
            activeTime = Date().timeIntervalSince(startTime)
        }

        // Calculate current WPM
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let recentWords = wordTimestamps.filter { $0 > oneMinuteAgo }.count
        currentWPM = recentWords

        // Calculate CPM
        let recentKeystrokes = keystrokeTimestamps.filter { $0 > oneMinuteAgo }.count
        currentCPM = recentKeystrokes

        // Update WPM history and highest WPM
        if currentWPM > 0 {
            wpmHistory.append(currentWPM)
            if currentWPM > highestWPMToday {
                highestWPMToday = currentWPM
            }
        }

        // Calculate average WPM
        if !wpmHistory.isEmpty {
            averageWPMToday = Double(wpmHistory.reduce(0, +)) / Double(wpmHistory.count)
        }

        // Calculate consistency (standard deviation)
        if wpmHistory.count > 1 {
            let mean = averageWPMToday
            let variance = wpmHistory.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(wpmHistory.count)
            let stdDev = sqrt(variance)
            consistency = max(0, 100 - (stdDev / mean * 100))
        }
    }

    func resetDailyStats() {
        highestWPMToday = 0
        averageWPMToday = 0
        consistency = 0
        wpmHistory.removeAll()
        activeTime = 0
        sessionStartTime = nil
    }

    private func saveStats() {
        userDefaults.set(totalKeystrokes, forKey: "totalKeystrokes")
        userDefaults.set(totalWords, forKey: "totalWords")
        userDefaults.set(highestWPMToday, forKey: "highestWPMToday")

        // Check if it's a new day
        let lastSaveDate = userDefaults.object(forKey: "lastSaveDate") as? Date ?? Date()
        if !Calendar.current.isDateInToday(lastSaveDate) {
            resetDailyStats()
        }
        userDefaults.set(Date(), forKey: "lastSaveDate")
    }

    private func loadStats() {
        totalKeystrokes = userDefaults.integer(forKey: "totalKeystrokes")
        totalWords = userDefaults.integer(forKey: "totalWords")
        highestWPMToday = userDefaults.integer(forKey: "highestWPMToday")

        // Check if saved stats are from today
        let lastSaveDate = userDefaults.object(forKey: "lastSaveDate") as? Date ?? Date()
        if !Calendar.current.isDateInToday(lastSaveDate) {
            resetDailyStats()
        }
    }

    var formattedActiveTime: String {
        let hours = Int(activeTime) / 3600
        let minutes = (Int(activeTime) % 3600) / 60
        let seconds = Int(activeTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
