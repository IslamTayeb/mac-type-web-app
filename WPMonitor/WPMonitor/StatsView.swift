import SwiftUI

struct StatsView: View {
    @ObservedObject var statsManager = StatsManager.shared
    @State private var showSettings = false
    @State private var launchAtLogin = LaunchHelper.shared.isLaunchAtLoginEnabled
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("WPMonitor")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main Stats
            ScrollView {
                VStack(spacing: 20) {
                    // Current Performance
                    VStack(spacing: 12) {
                        Text("Current Performance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 30) {
                            StatCard(
                                title: "WPM",
                                value: "\(statsManager.currentWPM)",
                                color: .blue
                            )
                            StatCard(
                                title: "CPM",
                                value: "\(statsManager.currentCPM)",
                                color: .green
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Today's Stats
                    VStack(spacing: 12) {
                        Text("Today's Statistics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 10) {
                            StatRow(title: "Highest WPM", value: "\(statsManager.highestWPMToday)")
                            StatRow(title: "Average WPM", value: String(format: "%.1f", statsManager.averageWPMToday))
                            StatRow(title: "Consistency", value: String(format: "%.1f%%", statsManager.consistency))
                            StatRow(title: "Active Time", value: statsManager.formattedActiveTime)
                        }
                    }
                    
                    Divider()
                    
                    // All-Time Stats
                    VStack(spacing: 12) {
                        Text("All-Time Statistics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 10) {
                            StatRow(title: "Total Keystrokes", value: formatNumber(statsManager.totalKeystrokes))
                            StatRow(title: "Total Words", value: formatNumber(statsManager.totalWords))
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.red)
                
                Spacer()
                
                if showSettings {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .onChange(of: launchAtLogin) { value in
                            LaunchHelper.shared.isLaunchAtLoginEnabled = value
                        }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 350, height: 400)
    }
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
