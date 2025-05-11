import SwiftUI

struct PlayerTileView: View {
    @ObservedObject var player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with player number and connection status
            HStack {
                Text("Player \(player.playerNumber)")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                // Connection status indicator
                ConnectionStatusIndicator(state: player.connectionState)
            }
            
            Divider()
            
            // Device information
            Group {
                Text("Device:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(player.deviceName.isEmpty ? "Not Connected" : player.deviceName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
                .frame(height: 8)
            
            // Gyro data display
            Group {
                Text("Gyro Data:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if player.connectionState == .connected {
                    Text(player.currentGyroData.formattedValues)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(2)
                    
                    // Visual representation of gyro data
                    GyroVisualizer(gyroData: player.currentGyroData)
                        .frame(height: 40)
                        .padding(.top, 4)
                } else {
                    Text("No data available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(connectionStateColor(player.connectionState), lineWidth: 2)
        )
    }
    
    private func connectionStateColor(_ state: ConnectionState) -> Color {
        switch state {
        case .connected:
            return Color.green
        case .connecting:
            return Color.yellow
        case .disconnected:
            return Color.gray
        }
    }
}

struct ConnectionStatusIndicator: View {
    var state: ConnectionState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
            
            Text(state.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(indicatorColor)
        }
    }
    
    private var indicatorColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .gray
        }
    }
}

struct GyroVisualizer: View {
    var gyroData: GyroData
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                // X-axis indicator
                BarIndicator(value: gyroData.x, label: "X", color: .red, width: geometry.size.width / 3 - 2)
                
                // Y-axis indicator
                BarIndicator(value: gyroData.y, label: "Y", color: .green, width: geometry.size.width / 3 - 2)
                
                // Z-axis indicator
                BarIndicator(value: gyroData.z, label: "Z", color: .blue, width: geometry.size.width / 3 - 2)
            }
        }
    }
}

struct BarIndicator: View {
    var value: Double
    var label: String
    var color: Color
    var width: CGFloat
    
    private var normalizedValue: Double {
        // Normalize value to range between 0 and 1 (assuming gyro data range of -1 to 1)
        return (value + 1) / 2
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // The bar
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: geometry.size.height)
                    
                    // Value bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(height: CGFloat(normalizedValue) * geometry.size.height)
                }
            }
            
            // Label
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(color)
        }
        .frame(width: width)
    }
}

// Preview provider
struct PlayerTileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Connected player
            PlayerTileView(player: Player.samplePlayers()[0])
                .frame(width: 250, height: 200)
                .previewDisplayName("Connected Player")
            
            // Connecting player
            PlayerTileView(player: Player.samplePlayers()[3])
                .frame(width: 250, height: 200)
                .previewDisplayName("Connecting Player")
            
            // Disconnected player
            PlayerTileView(player: Player.samplePlayers()[2])
                .frame(width: 250, height: 200)
                .previewDisplayName("Disconnected Player")
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}
