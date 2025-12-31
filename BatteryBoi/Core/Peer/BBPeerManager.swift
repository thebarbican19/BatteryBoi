//
//  BBPeerManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/19/23.
//

import Foundation
import MultipeerConnectivity

class PeerManager: NSObject, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, ObservableObject {
    static var shared = PeerManager()
    
    var peerID: MCPeerID!
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    
    override init() {
        super.init()
        peerID = MCPeerID(displayName: "YourDeviceName")
        session = MCSession(peer: peerID)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "your-service-type")
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
    }
        
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Handle invitation, decide whether to accept or reject
        invitationHandler(true, session)
        
    }
        
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data
        let receivedString = String(data: data, encoding: .utf8)
        print("Received: \(receivedString ?? "")")
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Handle peer state changes (connected, disconnected, etc.)
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func sendString(_ message: String) {
        if session.connectedPeers.count > 0 {
            do {
                try session.send(message.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } 
            catch {
                print("Error sending message: \(error.localizedDescription)")
                
            }
            
        }
        
    }
    
    
    
}
