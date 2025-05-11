import SwiftUI

struct MainView: View {
    @StateObject private var connectionManager = ConnectionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Tennis Game Host")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Connection status section
            ConnectionStatusView(connectionManager: connectionManager)
                .frame(maxWidth: .infinity)
            
            // Player tiles grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(connectionManager.players) { player in
                    PlayerTileView(player: player)
                        .frame(height: 200)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.headline)
                
                Text("1. Press 'Start Hosting' to begin accepting connections")
                Text("2. Launch the Tennis Controller app on iPhones")
                Text("3. Gyro data will appear in the player tiles once connected")
                
                if connectionManager.isHosting {
                    Text("Currently hosting a game session")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            
            // Debug options - optional for development
            #if DEBUG
            Divider()
                .padding(.vertical, 10)
            
            Button("Simulate Gyro Data") {
                simulateGyroData()
            }
            .disabled(!connectionManager.isHosting)
            #endif
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Automatically start hosting when the app launches
            // Uncomment to enable auto-start
            // connectionManager.startHosting()
        }
    }
    
    #if DEBUG
    // Debug function to simulate gyro data for testing UI
    private func simulateGyroData() {
        for (index, player) in connectionManager.players.enumerated() {
            if player.connectionState == .connected {
                let randomGyroData = GyroData(
                    x: Double.random(in: -1.0...1.0),
                    y: Double.random(in: -1.0...1.0),
                    z: Double.random(in: -1.0...1.0)
                )
                
                connectionManager.players[index].updateGyroData(randomGyroData)
            }
        }
    }
    #endif
}

// Preview provider
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 900, height: 700)
    }
}
