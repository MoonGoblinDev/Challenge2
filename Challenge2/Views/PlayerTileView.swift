// Challenge2/Views/PlayerTileView.swift
import SwiftUI

struct PlayerTileView: View {
    @ObservedObject var player: Player
    
    // Define normalization ranges for different data types.
    // Rotation rates (rad/s) might be around -7 to 7 (approx +/- 400 deg/s) for quick movements.
    // Acceleration (Gs) for user input, after gravity compensation, might be +/- 2G or more.
    // Attitude (radians): roll/yaw (-pi to pi), pitch (-pi/2 to pi/2).
    private let rotationRange: (min: Double, max: Double) = (-7.0, 7.0)
    private let accelerationRange: (min: Double, max: Double) = (-2.5, 2.5) // Gs
    private let rollYawRange: (min: Double, max: Double) = (-Double.pi, Double.pi)
    private let pitchRange: (min: Double, max: Double) = (-Double.pi / 2, Double.pi / 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) { // Reduced spacing
            // Title row with player number and connection status
            HStack {
                Text("Player \(player.playerNumber)")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                ConnectionStatusIndicator(state: player.connectionState)
            }
            
            Divider()
            
            Group {
                Text("Device:")
                    .font(.caption) // Slightly smaller
                    .foregroundColor(.secondary)
                
                Text(player.deviceName.isEmpty ? "Not Connected" : player.deviceName)
                    .font(.caption) // Slightly smaller
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.bottom, 2)
            
            // Motion data display
            VStack {
                Text("Motion Data:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if player.connectionState == .connected {
                    ScrollView(.vertical, showsIndicators: true) { // Allow scrolling if content overflows
                        Text(player.currentGyroData.formattedValues)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                            Text("Rotation (rad/s)")
                                .font(.caption2).foregroundColor(.gray)
                            DataVisualizer(
                                value1: player.currentGyroData.rotationX,
                                value2: player.currentGyroData.rotationY,
                                value3: player.currentGyroData.rotationZ,
                                labels: ("RX","RY","RZ"),
                                colors: (.red, .green, .blue),
                                ranges: (rotationRange, rotationRange, rotationRange)
                            )
                            .frame(height: 25) // Reduced height
                            
                            Text("Acceleration (Gs)")
                                .font(.caption2).foregroundColor(.gray)
                                .padding(.top, 2)
                            DataVisualizer(
                                value1: player.currentGyroData.accelerationX,
                                value2: player.currentGyroData.accelerationY,
                                value3: player.currentGyroData.accelerationZ,
                                labels: ("AX","AY","AZ"),
                                colors: (.orange, .purple, .yellow),
                                ranges: (accelerationRange, accelerationRange, accelerationRange)
                            )
                            .frame(height: 25)
                            
                            Text("Attitude (rad)")
                                .font(.caption2).foregroundColor(.gray)
                                .padding(.top, 2)
                            DataVisualizer(
                                value1: player.currentGyroData.roll,
                                value2: player.currentGyroData.pitch,
                                value3: player.currentGyroData.yaw,
                                labels: ("Roll","Pitch","Yaw"),
                                colors: (.cyan, .orange, .brown),
                                ranges: (rollYawRange, pitchRange, rollYawRange)
                            )
                            .frame(height: 25)
                        }
                    }
                    .frame(maxHeight: .infinity) // Allow ScrollView to take available space
                     
                }
                else {
                    Text("No data available")
                        .font(.caption) // Slightly smaller
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(maxHeight: .infinity) // Allow motion data group to expand
        }
        .padding(10) // Reduced padding
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

// Renamed GyroVisualizer to DataVisualizer for generality
struct DataVisualizer: View {
    var value1: Double
    var value2: Double
    var value3: Double
    var labels: (String, String, String)
    var colors: (Color, Color, Color)
    // Takes a tuple of ranges, one for each bar
    var ranges: ((min: Double, max: Double), (min: Double, max: Double), (min: Double, max: Double))?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                BarIndicator(value: value1, label: labels.0, color: colors.0, width: geometry.size.width / 3 - 2, range: ranges?.0)
                BarIndicator(value: value2, label: labels.1, color: colors.1, width: geometry.size.width / 3 - 2, range: ranges?.1)
                BarIndicator(value: value3, label: labels.2, color: colors.2, width: geometry.size.width / 3 - 2, range: ranges?.2)
            }
        }
    }
}

struct BarIndicator: View {
    var value: Double
    var label: String
    var color: Color
    var width: CGFloat
    var range: (min: Double, max: Double)? // Optional custom range for normalization

    private var normalizedValue: Double {
        let minVal = range?.min ?? -1.0 // Default range -1 to 1 if not specified
        let maxVal = range?.max ?? 1.0
        
        guard maxVal > minVal else { return 0.5 } // Avoid division by zero or invalid range, default to middle
        
        let clampedValue = max(minVal, min(value, maxVal)) // Clamp value to the defined range
        return (clampedValue - minVal) / (maxVal - minVal) // Normalize to 0-1 range
    }
    
    var body: some View {
        VStack(spacing: 1) { // Reduced spacing
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: geometry.size.height)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(height: CGFloat(normalizedValue) * geometry.size.height)
                }
            }
            
            Text(label)
                .font(.system(size: 8)) // Smaller label
                .foregroundColor(color)
        }
        .frame(width: width)
    }
}


