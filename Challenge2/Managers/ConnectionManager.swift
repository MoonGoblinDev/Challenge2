import Foundation
import MultipeerConnectivity
import Combine
import os.log

class ConnectionManager: NSObject, ObservableObject {
    private let serviceType = "tennis-game"
    private let logger = Logger(subsystem: "com.yourdomain.TennisGameHost", category: "ConnectionManager")
    
    private var session: MCSession
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    
    // Published properties for UI updates
    @Published var players: [Player] = []
    @Published var isHosting: Bool = false
    @Published var browserError: String?
    @Published var advertiserError: String?
    
    // Maximum number of players
    private let maxPlayers = 4
    
    override init() {
        // Initialize with host's peer ID
        let localPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac Host")
        
        // Set up session with encryption
        self.session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        // Set up service advertiser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        
        // Set up service browser
        self.serviceBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        
        // Initialize players array with placeholders
        self.players = (1...maxPlayers).map { playerNum in
            Player(playerNumber: playerNum, peerID: localPeerID)
        }
        
        super.init()
        
        // Set delegates
        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }
    
    // Start hosting the game session
    func startHosting() {
        logger.info("Starting to host game session")
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
        isHosting = true
    }
    
    // Stop hosting the game session
    func stopHosting() {
        logger.info("Stopping game session hosting")
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        
        // Disconnect all players
        for player in players where player.connectionState != .disconnected {
            let peerID = player.peerID
            session.disconnect()
            updatePlayerConnectionState(peerID: peerID, state: .disconnected)
        }
        
        isHosting = false
    }
    
    // Send gyro data to all connected peers (for testing)
    func sendDataToAllPeers(_ data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            logger.error("Error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    // Helper method to find available player slot
    private func findAvailablePlayerSlot() -> Int? {
        for (index, player) in players.enumerated() {
            if player.connectionState == .disconnected {
                return index
            }
        }
        return nil
    }
    
    // Update player connection state
    private func updatePlayerConnectionState(peerID: MCPeerID, state: ConnectionState) {
        DispatchQueue.main.async {
            if let index = self.players.firstIndex(where: { $0.peerID.displayName == peerID.displayName && $0.connectionState != .disconnected }) {
                self.players[index].connectionState = state
            }
        }
    }
    
    // Process received gyro data
    private func processReceivedGyroData(_ data: Data, from peerID: MCPeerID) {
        do {
            let gyroData = try JSONDecoder().decode(GyroData.self, from: data)
            
            if let playerIndex = players.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
                DispatchQueue.main.async {
                    self.players[playerIndex].updateGyroData(gyroData)
                }
            }
        } catch {
            logger.error("Error decoding gyro data: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCSessionDelegate
extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.logger.info("Peer \(peerID.displayName) changed state to \(state.rawValue)")
            
            switch state {
            case .connected:
                // Find an available player slot
                if let index = self.findAvailablePlayerSlot() {
                    self.players[index].peerID = peerID
                    self.players[index].deviceName = peerID.displayName
                    self.players[index].connectionState = .connected
                }
            case .connecting:
                if let index = self.findAvailablePlayerSlot() {
                    self.players[index].peerID = peerID
                    self.players[index].deviceName = peerID.displayName
                    self.players[index].connectionState = .connecting
                }
            case .notConnected:
                // Find the disconnected player and update state
                if let index = self.players.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
                    self.players[index].connectionState = .disconnected
                }
            @unknown default:
                self.logger.error("Unknown session state: \(state.rawValue)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        processReceivedGyroData(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("Received invitation from peer: \(peerID.displayName)")
        
        // Check if we have room for more players
        if session.connectedPeers.count < maxPlayers {
            invitationHandler(true, session)
        } else {
            logger.info("Rejected peer - max players reached")
            invitationHandler(false, nil)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.advertiserError = error.localizedDescription
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        logger.info("Found peer: \(peerID.displayName)")
        
        // Invite peer if we have room for more players
        if session.connectedPeers.count < maxPlayers {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.browserError = error.localizedDescription
        }
    }
}
