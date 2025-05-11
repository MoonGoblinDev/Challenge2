import Foundation
import MultipeerConnectivity

enum ConnectionState: String, Codable {
    case disconnected
    case connecting
    case connected
}

class Player: Identifiable, ObservableObject {
    let id = UUID()
    var playerNumber: Int
    var peerID: MCPeerID
    @Published var deviceName: String
    @Published var connectionState: ConnectionState
    @Published var currentGyroData: GyroData
    
    init(playerNumber: Int, peerID: MCPeerID, deviceName: String = "", connectionState: ConnectionState = .disconnected) {
        self.playerNumber = playerNumber
        self.peerID = peerID
        self.deviceName = deviceName
        self.connectionState = connectionState
        self.currentGyroData = GyroData()
    }
    
    // Update player's gyro data with new values
    func updateGyroData(_ data: GyroData) {
        DispatchQueue.main.async {
            self.currentGyroData = data
        }
    }
    
    // For preview and testing
    static func samplePlayers() -> [Player] {
        return [
            Player(playerNumber: 1, peerID: MCPeerID(displayName: "iPhone 15"), deviceName: "Player 1 iPhone", connectionState: .connected),
            Player(playerNumber: 2, peerID: MCPeerID(displayName: "iPhone 14"), deviceName: "Player 2 iPhone", connectionState: .connected),
            Player(playerNumber: 3, peerID: MCPeerID(displayName: "iPhone 13"), deviceName: "Player 3 iPhone", connectionState: .disconnected),
            Player(playerNumber: 4, peerID: MCPeerID(displayName: "iPhone SE"), deviceName: "Player 4 iPhone", connectionState: .connecting)
        ]
    }
}
