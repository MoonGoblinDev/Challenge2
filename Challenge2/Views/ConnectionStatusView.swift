import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var connectionManager: ConnectionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Host status indicator
                StatusIndicator(
                    isActive: connectionManager.isHosting,
                    activeText: "Hosting Active",
                    inactiveText: "Hosting Inactive"
                )
                
                // Connected players count
                let connectedCount = connectionManager.players.filter { $0.connectionState == .connected }.count
                StatusIndicator(
                    isActive: connectedCount > 0,
                    activeText: "\(connectedCount) Player(s) Connected",
                    inactiveText: "No Players Connected",
                    activeColor: .blue
                )
            }
            
            // Error display
            if let browserError = connectionManager.browserError {
                ErrorView(message: "Browser Error: \(browserError)")
            }
            
            if let advertiserError = connectionManager.advertiserError {
                ErrorView(message: "Advertiser Error: \(advertiserError)")
            }
            
            // Host control button
            Button(action: {
                if connectionManager.isHosting {
                    connectionManager.stopHosting()
                } else {
                    connectionManager.startHosting()
                }
            }) {
                Text(connectionManager.isHosting ? "Stop Hosting" : "Start Hosting")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatusIndicator: View {
    var isActive: Bool
    var activeText: String
    var inactiveText: String
    var activeColor: Color = .green
    var inactiveColor: Color = .gray
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 10, height: 10)
            
            Text(isActive ? activeText : inactiveText)
                .font(.subheadline)
        }
    }
}

struct ErrorView: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(4)
    }
}

// Preview provider
struct ConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active hosting preview
            let activeManager = ConnectionManager()
            //activeManager.startHosting()
            
            ConnectionStatusView(connectionManager: activeManager)
                .frame(width: 400)
                .previewDisplayName("Active Hosting")
            
            // Inactive hosting preview
            let inactiveManager = ConnectionManager()
            
            ConnectionStatusView(connectionManager: inactiveManager)
                .frame(width: 400)
                .previewDisplayName("Inactive Hosting")
            
            // Error state preview
            let errorManager = ConnectionManager()
            //errorManager.browserError = "Failed to start browsing for peers"
            
            ConnectionStatusView(connectionManager: errorManager)
                .frame(width: 400)
                .previewDisplayName("With Error")
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}
